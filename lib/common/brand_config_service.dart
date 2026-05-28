import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:jichanglianmeng/common/brand.dart';
import 'package:jichanglianmeng/common/brand_crypto.dart';
import 'package:jichanglianmeng/common/preferences.dart';
import 'package:jichanglianmeng/common/request.dart';
import 'package:jichanglianmeng/models/brand_config_data.dart';

class BrandConfigService {
  static const _requestTimeout = Duration(seconds: 10);
  static const _raceTimeout = Duration(seconds: 10);

  Future<BrandConfigData?> loadFromCache() async {
    try {
      final cacheString = await preferences.getBrandConfigCache();
      if (cacheString == null || cacheString.isEmpty) {
        return null;
      }
      final decoded = json.decode(cacheString);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return BrandConfigData.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveToCache(BrandConfigData data) async {
    await preferences.setBrandConfigCache(json.encode(data.toJson()));
  }

  Future<BrandConfigData?> fetchRemote() async {
    if (!BrandConfig.hasRemoteConfig) {
      return null;
    }
    final urls = BrandConfig.configUrls;
    if (urls.isEmpty) {
      return null;
    }
    if (urls.length == 1) {
      return _fetchFromUrl(urls.first);
    }
    return _fetchRemoteRace(urls);
  }

  Future<BrandConfigData?> _fetchRemoteRace(List<String> urls) async {
    final completer = Completer<BrandConfigData?>();
    var pending = urls.length;

    void onRequestFinished() {
      pending--;
      if (pending == 0 && !completer.isCompleted) {
        completer.complete(null);
      }
    }

    for (final url in urls) {
      unawaited(
        _fetchFromUrl(url)
            .then((data) {
              if (completer.isCompleted) {
                return;
              }
              if (data != null && data.hasValidAirportUrl) {
                completer.complete(data);
                return;
              }
              onRequestFinished();
            })
            .catchError((_) {
              onRequestFinished();
            }),
      );
    }

    return completer.future.timeout(
      _raceTimeout,
      onTimeout: () => null,
    );
  }

  Future<BrandConfigData?> _fetchFromUrl(String url) async {
    final response = await request.dio
        .get<String>(
          url,
          options: Options(
            responseType: ResponseType.plain,
            receiveTimeout: _requestTimeout,
            sendTimeout: _requestTimeout,
          ),
        )
        .timeout(_requestTimeout);
    if (response.statusCode != 200 || response.data == null) {
      throw Exception('brand config request failed: $url');
    }
    final remoteJson = json.decode(response.data!) as Map<String, dynamic>;
    final version = remoteJson['v'];
    if (version != 1) {
      throw FormatException('unsupported brand config version: $version');
    }
    final payload = remoteJson['payload'];
    if (payload is! String || payload.isEmpty) {
      throw FormatException('brand config payload missing');
    }
    final plainJson = decryptBrandPayload(payload);
    return BrandConfigData.fromJson(plainJson);
  }
}

final brandConfigService = BrandConfigService();
