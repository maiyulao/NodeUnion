import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jichanglianmeng/common/admob.dart';
import 'package:jichanglianmeng/common/common.dart';
import 'package:jichanglianmeng/enum/enum.dart';
import 'package:jichanglianmeng/models/brand_config_ads.dart';
import 'package:jichanglianmeng/providers/ad.dart';
import 'package:jichanglianmeng/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdManager extends ConsumerStatefulWidget {
  final Widget child;

  const AdManager({super.key, required this.child});

  @override
  ConsumerState<AdManager> createState() => _AdManagerState();
}

class _AdManagerState extends ConsumerState<AdManager>
    with WidgetsBindingObserver {
  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  bool _isInterstitialLoading = false;
  bool _isAppOpenLoading = false;
  bool _isShowingFullScreenAd = false;
  DateTime? _lastInterstitialShownAt;
  DateTime? _lastAppOpenShownAt;
  Timer? _interstitialTimer;
  ProviderSubscription<bool>? _canRequestSub;
  ProviderSubscription<bool>? _adsEnabledSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncInitialVpnState();
    _canRequestSub = ref.listenManual<bool>(
      canRequestAdsProvider,
      (previous, next) {
        if (previous == next) {
          return;
        }
        if (next) {
          _scheduleInterstitial();
          unawaited(_loadAppOpenAd());
        } else {
          _interstitialTimer?.cancel();
        }
      },
      fireImmediately: true,
    );
    _adsEnabledSub = ref.listenManual<bool>(
      adsEnabledProvider,
      (previous, next) {
        if (previous == true && next == false) {
          _disposeAllAds();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_showAppOpenAdIfAvailable());
    }
  }

  Future<void> _syncInitialVpnState() async {
    final results = await Connectivity().checkConnectivity();
    if (!mounted) {
      return;
    }
    ref.read(hasSystemVpnProvider.notifier).setHasVpn(
      results.contains(ConnectivityResult.vpn),
    );
  }

  void _disposeAllAds() {
    _interstitialTimer?.cancel();
    _disposeInterstitial();
    _disposeAppOpenAd();
  }

  void _scheduleInterstitial() {
    _interstitialTimer?.cancel();
    final ads = ref.read(brandConfigAdsProvider);
    if (ads == null || !ads.enabled) {
      return;
    }
    final delay = Duration(seconds: ads.interstitialDelaySeconds);
    _interstitialTimer = Timer(delay, () {
      if (!mounted || !ref.read(canRequestAdsProvider)) {
        return;
      }
      unawaited(_loadAndShowInterstitial(ads));
    });
  }

  bool _canShowInterstitial(BrandConfigAds ads) {
    final lastShown = _lastInterstitialShownAt;
    if (lastShown == null) {
      return true;
    }
    final cooldown = Duration(seconds: ads.interstitialCooldownSeconds);
    return DateTime.now().difference(lastShown) >= cooldown;
  }

  bool _canShowAppOpen(BrandConfigAds ads) {
    final lastShown = _lastAppOpenShownAt;
    if (lastShown == null) {
      return true;
    }
    final cooldown = Duration(seconds: ads.appOpenCooldownSeconds);
    return DateTime.now().difference(lastShown) >= cooldown;
  }

  Future<void> _loadAndShowInterstitial(BrandConfigAds ads) async {
    if (_isInterstitialLoading ||
        _interstitialAd != null ||
        _isShowingFullScreenAd ||
        !_canShowInterstitial(ads)) {
      return;
    }
    final adUnitId = ads.interstitialAdUnitId;
    if (adUnitId == null || adUnitId.isEmpty) {
      return;
    }

    _isInterstitialLoading = true;
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isInterstitialLoading = false;
          if (!mounted || !ref.read(adsEnabledProvider)) {
            ad.dispose();
            return;
          }
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isShowingFullScreenAd = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isShowingFullScreenAd = false;
              _lastInterstitialShownAt = DateTime.now();
              if (ref.read(canRequestAdsProvider)) {
                _scheduleInterstitial();
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              commonPrint.log(
                'interstitial show failed: $error',
                logLevel: LogLevel.warning,
              );
              ad.dispose();
              _interstitialAd = null;
              _isShowingFullScreenAd = false;
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          commonPrint.log(
            'interstitial load failed: $error',
            logLevel: LogLevel.warning,
          );
        },
      ),
    );
  }

  Future<void> _loadAppOpenAd() async {
    if (_isAppOpenLoading || _appOpenAd != null) {
      return;
    }
    if (!ref.read(canRequestAdsProvider)) {
      return;
    }
    final ads = ref.read(brandConfigAdsProvider);
    if (ads == null || !ads.enabled) {
      return;
    }
    final adUnitId = ads.appOpenAdUnitId;
    if (adUnitId == null || adUnitId.isEmpty) {
      return;
    }

    _isAppOpenLoading = true;
    await AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isAppOpenLoading = false;
          if (!mounted || !ref.read(adsEnabledProvider)) {
            ad.dispose();
            return;
          }
          _appOpenAd = ad;
          unawaited(_showAppOpenAdIfAvailable());
        },
        onAdFailedToLoad: (error) {
          _isAppOpenLoading = false;
          commonPrint.log(
            'app open load failed: $error',
            logLevel: LogLevel.warning,
          );
        },
      ),
    );
  }

  Future<void> _showAppOpenAdIfAvailable() async {
    if (_isShowingFullScreenAd || !ref.read(adsEnabledProvider)) {
      return;
    }
    final ads = ref.read(brandConfigAdsProvider);
    if (ads == null || !_canShowAppOpen(ads)) {
      return;
    }
    final ad = _appOpenAd;
    if (ad == null) {
      if (ref.read(canRequestAdsProvider)) {
        unawaited(_loadAppOpenAd());
      }
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingFullScreenAd = true;
        _lastAppOpenShownAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _isShowingFullScreenAd = false;
        if (ref.read(canRequestAdsProvider)) {
          unawaited(_loadAppOpenAd());
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        commonPrint.log(
          'app open show failed: $error',
          logLevel: LogLevel.warning,
        );
        ad.dispose();
        _appOpenAd = null;
        _isShowingFullScreenAd = false;
      },
    );
    await ad.show();
  }

  void _disposeInterstitial() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoading = false;
  }

  void _disposeAppOpenAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isAppOpenLoading = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _interstitialTimer?.cancel();
    _canRequestSub?.close();
    _adsEnabledSub?.close();
    _disposeAllAds();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  String? _loadedAdUnitId;

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBanner(String adUnitId) async {
    if (!ref.read(canRequestAdsProvider)) {
      return;
    }
    if (_loadedAdUnitId == adUnitId && _bannerAd != null) {
      return;
    }
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    _loadedAdUnitId = adUnitId;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null || !ref.read(canRequestAdsProvider)) {
      return;
    }

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          commonPrint.log(
            'banner load failed: $error',
            logLevel: LogLevel.warning,
          );
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _bannerAd = null;
              _loadedAdUnitId = null;
            });
          }
        },
      ),
    );
    _bannerAd = banner;
    await banner.load();
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    _loadedAdUnitId = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!AdMobConfig.isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    final adsEnabled = ref.watch(adsEnabledProvider);
    final canRequest = ref.watch(canRequestAdsProvider);
    final ads = ref.watch(brandConfigAdsProvider);
    final adUnitId = ads?.bannerAdUnitId;

    ref.listen<bool>(adsEnabledProvider, (previous, next) {
      if (previous == true && next == false) {
        setState(_disposeBanner);
      }
    });

    ref.listen<bool>(canRequestAdsProvider, (previous, next) {
      if (previous == false && next == true && adUnitId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_loadBanner(adUnitId));
          }
        });
      }
    });

    if (!adsEnabled) {
      return const SizedBox.shrink();
    }

    if (canRequest &&
        adUnitId != null &&
        adUnitId.isNotEmpty &&
        _loadedAdUnitId != adUnitId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(canRequestAdsProvider)) {
          unawaited(_loadBanner(adUnitId));
        }
      });
    }

    final banner = _bannerAd;
    if (!_isLoaded || banner == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }
}

class AdNativeCard extends ConsumerStatefulWidget {
  const AdNativeCard({super.key});

  @override
  ConsumerState<AdNativeCard> createState() => _AdNativeCardState();
}

class _AdNativeCardState extends ConsumerState<AdNativeCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  String? _loadedAdUnitId;

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  NativeTemplateStyle _buildTemplateStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: colorScheme.surfaceContainerHighest,
      cornerRadius: 12,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
        style: NativeTemplateFontStyle.bold,
        size: 14,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: colorScheme.onSurface,
        style: NativeTemplateFontStyle.bold,
        size: 16,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: colorScheme.onSurfaceVariant,
        style: NativeTemplateFontStyle.normal,
        size: 14,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: colorScheme.onSurfaceVariant,
        style: NativeTemplateFontStyle.normal,
        size: 12,
      ),
    );
  }

  Future<void> _loadNative(String adUnitId) async {
    if (!ref.read(canRequestAdsProvider)) {
      return;
    }
    if (_loadedAdUnitId == adUnitId && _nativeAd != null) {
      return;
    }
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoaded = false;
    _loadedAdUnitId = adUnitId;

    final nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: _buildTemplateStyle(context),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          commonPrint.log(
            'native load failed: $error',
            logLevel: LogLevel.warning,
          );
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _nativeAd = null;
              _loadedAdUnitId = null;
            });
          }
        },
      ),
    );
    _nativeAd = nativeAd;
    await nativeAd.load();
  }

  void _disposeNative() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoaded = false;
    _loadedAdUnitId = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!AdMobConfig.isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    final adsEnabled = ref.watch(adsEnabledProvider);
    final canRequest = ref.watch(canRequestAdsProvider);
    final ads = ref.watch(brandConfigAdsProvider);
    final adUnitId = ads?.nativeAdUnitId;

    ref.listen<bool>(adsEnabledProvider, (previous, next) {
      if (previous == true && next == false) {
        setState(_disposeNative);
      }
    });

    ref.listen<bool>(canRequestAdsProvider, (previous, next) {
      if (previous == false && next == true && adUnitId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_loadNative(adUnitId));
          }
        });
      }
    });

    if (!adsEnabled) {
      return const SizedBox.shrink();
    }

    if (canRequest &&
        adUnitId != null &&
        adUnitId.isNotEmpty &&
        _loadedAdUnitId != adUnitId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(canRequestAdsProvider)) {
          unawaited(_loadNative(adUnitId));
        }
      });
    }

    final nativeAd = _nativeAd;
    if (!_isLoaded || nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: AdWidget(ad: nativeAd),
      ),
    );
  }
}
