import 'package:jichanglianmeng/common/brand.dart';

class BrandConfigData {
  final String airportName;
  final String airportUrl;

  const BrandConfigData({
    required this.airportName,
    required this.airportUrl,
  });

  bool get hasValidAirportUrl => BrandConfig.isValidAirportUrl(airportUrl);

  factory BrandConfigData.fromJson(Map<String, dynamic> json) {
    return BrandConfigData(
      airportName: json['airportName'] as String? ?? '',
      airportUrl: json['airportUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'airportName': airportName,
      'airportUrl': airportUrl,
    };
  }
}
