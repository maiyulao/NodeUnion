import 'dart:io';

import 'package:jichanglianmeng/common/admob.dart';

class BrandConfigAds {
  final bool enabled;
  final String? bannerAndroid;
  final String? bannerIos;
  final String? interstitialAndroid;
  final String? interstitialIos;
  final String? nativeAndroid;
  final String? nativeIos;
  final String? appOpenAndroid;
  final String? appOpenIos;
  final int interstitialDelaySeconds;
  final int interstitialCooldownSeconds;
  final int appOpenCooldownSeconds;

  const BrandConfigAds({
    this.enabled = false,
    this.bannerAndroid,
    this.bannerIos,
    this.interstitialAndroid,
    this.interstitialIos,
    this.nativeAndroid,
    this.nativeIos,
    this.appOpenAndroid,
    this.appOpenIos,
    this.interstitialDelaySeconds = 8,
    this.interstitialCooldownSeconds = 180,
    this.appOpenCooldownSeconds = 240,
  });

  String? get bannerAdUnitId {
    if (Platform.isAndroid) {
      return bannerAndroid ?? AdMobConfig.testBannerAndroid;
    }
    if (Platform.isIOS) {
      return bannerIos ?? AdMobConfig.testBannerIos;
    }
    return null;
  }

  String? get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return interstitialAndroid ?? AdMobConfig.testInterstitialAndroid;
    }
    if (Platform.isIOS) {
      return interstitialIos ?? AdMobConfig.testInterstitialIos;
    }
    return null;
  }

  String? get nativeAdUnitId {
    if (Platform.isAndroid) {
      return nativeAndroid ?? AdMobConfig.testNativeAndroid;
    }
    if (Platform.isIOS) {
      return nativeIos ?? AdMobConfig.testNativeIos;
    }
    return null;
  }

  String? get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return appOpenAndroid ?? AdMobConfig.testAppOpenAndroid;
    }
    if (Platform.isIOS) {
      return appOpenIos ?? AdMobConfig.testAppOpenIos;
    }
    return null;
  }

  factory BrandConfigAds.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const BrandConfigAds();
    }
    return BrandConfigAds(
      enabled: json['enabled'] as bool? ?? false,
      bannerAndroid: json['bannerAndroid'] as String?,
      bannerIos: json['bannerIos'] as String?,
      interstitialAndroid: json['interstitialAndroid'] as String?,
      interstitialIos: json['interstitialIos'] as String?,
      nativeAndroid: json['nativeAndroid'] as String?,
      nativeIos: json['nativeIos'] as String?,
      appOpenAndroid: json['appOpenAndroid'] as String?,
      appOpenIos: json['appOpenIos'] as String?,
      interstitialDelaySeconds: json['interstitialDelaySeconds'] as int? ?? 8,
      interstitialCooldownSeconds:
          json['interstitialCooldownSeconds'] as int? ?? 180,
      appOpenCooldownSeconds: json['appOpenCooldownSeconds'] as int? ?? 240,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'bannerAndroid': bannerAndroid,
      'bannerIos': bannerIos,
      'interstitialAndroid': interstitialAndroid,
      'interstitialIos': interstitialIos,
      'nativeAndroid': nativeAndroid,
      'nativeIos': nativeIos,
      'appOpenAndroid': appOpenAndroid,
      'appOpenIos': appOpenIos,
      'interstitialDelaySeconds': interstitialDelaySeconds,
      'interstitialCooldownSeconds': interstitialCooldownSeconds,
      'appOpenCooldownSeconds': appOpenCooldownSeconds,
    };
  }
}
