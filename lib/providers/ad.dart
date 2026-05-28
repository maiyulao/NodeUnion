import 'package:jichanglianmeng/common/admob.dart';
import 'package:jichanglianmeng/models/brand_config_ads.dart';
import 'package:jichanglianmeng/providers/brand_config.dart';
import 'package:jichanglianmeng/providers/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HasSystemVpnNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setHasVpn(bool value) {
    state = value;
  }
}

final hasSystemVpnProvider =
    NotifierProvider<HasSystemVpnNotifier, bool>(HasSystemVpnNotifier.new);

final adsEnabledProvider = Provider<bool>((ref) {
  if (!AdMobConfig.isSupportedPlatform) {
    return false;
  }
  final ads = ref.watch(
    brandConfigProvider.select((state) => state.data?.ads),
  );
  return ads?.enabled ?? false;
});

/// 是否允许发起新的广告请求（VPN/代理开启时不请求，但不隐藏已加载广告）
final canRequestAdsProvider = Provider<bool>((ref) {
  if (!ref.watch(adsEnabledProvider)) {
    return false;
  }
  if (ref.watch(isStartProvider)) {
    return false;
  }
  if (ref.watch(hasSystemVpnProvider)) {
    return false;
  }
  return true;
});

final brandConfigAdsProvider = Provider<BrandConfigAds?>((ref) {
  return ref.watch(
    brandConfigProvider.select((state) => state.data?.ads),
  );
});
