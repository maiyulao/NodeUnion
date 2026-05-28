import 'dart:io';

import 'package:jichanglianmeng/common/common.dart';
import 'package:jichanglianmeng/controller.dart';

class FlClashHttpOverrides extends HttpOverrides {
  static String handleFindProxy(Uri url) {
    if ([localhost].contains(url.host)) {
      return 'DIRECT';
    }
    final port = appController.config.patchClashConfig.mixedPort;
    final isStart = appController.isStart;
    commonPrint.log('find $url proxy:$isStart');
    if (!isStart) return 'DIRECT';
    return 'PROXY localhost:$port';
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, _, _) => true;
    client.findProxy = handleFindProxy;
    return client;
  }
}
