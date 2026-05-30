import 'package:jichanglianmeng/common/common.dart';
import 'package:jichanglianmeng/controller.dart';
import 'package:jichanglianmeng/providers/providers.dart';
import 'package:jichanglianmeng/state.dart';
import 'package:jichanglianmeng/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class AirportWebView extends ConsumerStatefulWidget {
  const AirportWebView({super.key});

  @override
  ConsumerState<AirportWebView> createState() => _AirportWebViewState();
}

class _AirportWebViewState extends ConsumerState<AirportWebView> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  static const _trustedExternalSchemes = {
    'alipay',
    'alipays',
    'weixin',
    'wechat',
    'mqqapi',
    'wxp',
    'intent',
  };

  bool get _isUnsupportedPlatform => system.isLinux;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brandConfigProvider.notifier).refresh(force: true);
    });
  }

  Future<void> _openInExternalBrowser(String airportUrl) async {
    await globalState.openUrl(airportUrl);
  }

  Future<void> _openExternalUrl(Uri uri, {required bool showConfirm}) async {
    if (showConfirm) {
      await globalState.openUrl(uri.toString());
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool _tryHandleInstallConfig(Uri uri) {
    if (uri.host != 'install-config') {
      return false;
    }
    final isInstallScheme = const {'clash', 'clashmeta', 'flclash'}.contains(
      uri.scheme,
    );
    if (!isInstallScheme) {
      return false;
    }
    final url = uri.queryParameters['url'];
    if (url == null || url.isEmpty) {
      return true;
    }
    appController.addProfileFormURL(url);
    return true;
  }

  Future<NavigationActionPolicy> _onShouldOverrideUrlLoading(
    NavigationAction action,
  ) async {
    final requestUrl = action.request.url;
    if (requestUrl == null) {
      return NavigationActionPolicy.ALLOW;
    }
    final uri = Uri.tryParse(requestUrl.toString());
    if (uri == null) {
      return NavigationActionPolicy.ALLOW;
    }
    if (_tryHandleInstallConfig(uri)) {
      return NavigationActionPolicy.CANCEL;
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return NavigationActionPolicy.ALLOW;
    }
    final isTrusted = _trustedExternalSchemes.contains(uri.scheme);
    await _openExternalUrl(uri, showConfirm: !isTrusted);
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _reload() async {
    await _webViewController?.reload();
  }

  Future<void> _goBack() async {
    if (await _webViewController?.canGoBack() ?? false) {
      await _webViewController?.goBack();
    }
  }

  Future<void> _goForward() async {
    if (await _webViewController?.canGoForward() ?? false) {
      await _webViewController?.goForward();
    }
  }

  Widget _buildNotConfiguredBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          appLocalizations.airportNotConfigured,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLoadingBody() {
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    final brandConfig = ref.watch(brandConfigProvider);
    final pageTitle = brandConfig.airportName.isNotEmpty
        ? brandConfig.airportName
        : appLocalizations.airport;

    if (brandConfig.status == BrandConfigStatus.loading) {
      return CommonScaffold(
        title: pageTitle,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(brandConfigProvider.notifier).refresh(
                    force: true,
                  );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
        body: _buildLoadingBody(),
      );
    }

    if (!brandConfig.hasValidAirportUrl) {
      return CommonScaffold(
        title: pageTitle,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(brandConfigProvider.notifier).refresh(
                    force: true,
                  );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
        body: _buildNotConfiguredBody(),
      );
    }

    final airportUrl = brandConfig.airportUrl!;

    if (_isUnsupportedPlatform) {
      return CommonScaffold(
        title: pageTitle,
        actions: [
          IconButton(
            onPressed: () => _openInExternalBrowser(airportUrl),
            icon: const Icon(Icons.open_in_browser),
          ),
        ],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appLocalizations.airportWebviewUnsupported,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _openInExternalBrowser(airportUrl),
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(appLocalizations.openInBrowser),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return CommonScaffold(
      title: pageTitle,
      actions: [
        IconButton(onPressed: _goBack, icon: const Icon(Icons.arrow_back)),
        IconButton(
          onPressed: _goForward,
          icon: const Icon(Icons.arrow_forward),
        ),
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        IconButton(
          onPressed: () => _openInExternalBrowser(airportUrl),
          icon: const Icon(Icons.open_in_browser),
        ),
      ],
      body: Column(
        children: [
          if (_progress > 0 && _progress < 1)
            LinearProgressIndicator(value: _progress),
          Expanded(
            child: InAppWebView(
              webViewEnvironment: globalWebViewEnvironment,
              initialUrlRequest: URLRequest(url: WebUri(airportUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              shouldOverrideUrlLoading: (_, action) {
                return _onShouldOverrideUrlLoading(action);
              },
              onProgressChanged: (_, progress) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _progress = progress / 100;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
