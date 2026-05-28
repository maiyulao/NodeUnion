import 'dart:io';

class AdMobConfig {
  static const testAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';
  static const testAppIdIos = 'ca-app-pub-3940256099942544~1458002511';

  static const testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const testNativeIos = 'ca-app-pub-3940256099942544/3986624511';
  static const testAppOpenAndroid = 'ca-app-pub-3940256099942544/9257395921';
  static const testAppOpenIos = 'ca-app-pub-3940256099942544/5575463023';

  static bool get isSupportedPlatform => Platform.isAndroid || Platform.isIOS;
}
