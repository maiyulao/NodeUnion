import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:jichanglianmeng/common/system.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

WebViewEnvironment? globalWebViewEnvironment;

Future<void> initWebViewEnvironment() async {
  if (!system.isWindows) {
    return;
  }
  final supportDir = await getApplicationSupportDirectory();
  final userDataFolder = join(supportDir.path, 'WebView2');
  globalWebViewEnvironment = await WebViewEnvironment.create(
    settings: WebViewEnvironmentSettings(userDataFolder: userDataFolder),
  );
}
