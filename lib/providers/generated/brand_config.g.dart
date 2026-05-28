// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../brand_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BrandConfigNotifier)
const brandConfigProvider = BrandConfigNotifierProvider._();

final class BrandConfigNotifierProvider
    extends $NotifierProvider<BrandConfigNotifier, BrandConfigState> {
  const BrandConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brandConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brandConfigNotifierHash();

  @$internal
  @override
  BrandConfigNotifier create() => BrandConfigNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BrandConfigState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BrandConfigState>(value),
    );
  }
}

String _$brandConfigNotifierHash() =>
    r'03333febed0914f7c1f16b09a7369e37b736a0e1';

abstract class _$BrandConfigNotifier extends $Notifier<BrandConfigState> {
  BrandConfigState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<BrandConfigState, BrandConfigState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BrandConfigState, BrandConfigState>,
              BrandConfigState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
