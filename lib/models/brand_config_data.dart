import 'package:jichanglianmeng/common/brand.dart';
import 'package:jichanglianmeng/models/brand_config_ads.dart';

class BrandConfigData {
  final String airportName;
  final String airportUrl;
  final BrandConfigAds ads;

  const BrandConfigData({
    required this.airportName,
    required this.airportUrl,
    this.ads = const BrandConfigAds(),
  });

  bool get hasValidAirportUrl => BrandConfig.isValidAirportUrl(airportUrl);

  factory BrandConfigData.fromJson(Map<String, dynamic> json) {
    return BrandConfigData(
      airportName: json['airportName'] as String? ?? '',
      airportUrl: json['airportUrl'] as String? ?? '',
      ads: BrandConfigAds.fromJson(json['ads'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'airportName': airportName,
      'airportUrl': airportUrl,
      'ads': ads.toJson(),
    };
  }
}
