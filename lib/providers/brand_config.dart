import 'package:jichanglianmeng/common/common.dart';
import 'package:jichanglianmeng/enum/enum.dart';
import 'package:jichanglianmeng/models/brand_config_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/brand_config.g.dart';

enum BrandConfigStatus { loading, ready, invalid }

class BrandConfigState {
  final BrandConfigStatus status;
  final BrandConfigData? data;

  const BrandConfigState({
    required this.status,
    this.data,
  });

  bool get hasValidAirportUrl =>
      data != null && data!.hasValidAirportUrl;

  String? get airportUrl => data?.airportUrl;

  String get airportName => data?.airportName ?? '';
}

@Riverpod(keepAlive: true)
class BrandConfigNotifier extends _$BrandConfigNotifier
    with AutoDisposeNotifierMixin {
  @override
  BrandConfigState build() {
    return const BrandConfigState(status: BrandConfigStatus.loading);
  }

  Future<void> refresh({bool force = false}) async {
    if (!BrandConfig.hasRemoteConfig) {
      state = const BrandConfigState(status: BrandConfigStatus.invalid);
      return;
    }

    final previous = state;
    if (previous.status != BrandConfigStatus.ready || force) {
      state = BrandConfigState(
        status: BrandConfigStatus.loading,
        data: previous.data,
      );
    }

    BrandConfigData? cached;
    try {
      cached = await brandConfigService.loadFromCache();
      if (cached != null && cached.hasValidAirportUrl) {
        state = BrandConfigState(
          status: BrandConfigStatus.ready,
          data: cached,
        );
      }
    } catch (e) {
      commonPrint.log(
        'load brand config cache failed: $e',
        logLevel: LogLevel.warning,
      );
    }

    try {
      final remote = await brandConfigService.fetchRemote();
      if (remote != null && remote.hasValidAirportUrl) {
        await brandConfigService.saveToCache(remote);
        state = BrandConfigState(
          status: BrandConfigStatus.ready,
          data: remote,
        );
        return;
      }
      if (cached == null || !cached.hasValidAirportUrl) {
        state = const BrandConfigState(status: BrandConfigStatus.invalid);
      }
    } catch (e) {
      commonPrint.log(
        'fetch brand config failed: $e',
        logLevel: LogLevel.warning,
      );
      if (cached == null || !cached.hasValidAirportUrl) {
        state = const BrandConfigState(status: BrandConfigStatus.invalid);
      }
    }
  }
}
