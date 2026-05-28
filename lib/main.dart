import 'dart:async';
import 'dart:io';

import 'package:jichanglianmeng/pages/error.dart';
import 'package:jichanglianmeng/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'application.dart';
import 'common/admob.dart';
import 'common/common.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (AdMobConfig.isSupportedPlatform) {
      await MobileAds.instance.initialize();
    }
    final version = await system.version;
    final container = await globalState.init(version);
    HttpOverrides.global = FlClashHttpOverrides();
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const Application(),
      ),
    );
  } catch (e, s) {
    return runApp(
      MaterialApp(
        home: InitErrorScreen(error: e, stack: s),
      ),
    );
  }
}
