import 'dart:io';

import 'package:flutter_app_builder/src/build_config.dart';
import 'package:flutter_app_builder/src/build_result.dart';

class BuildLinuxResultResolver extends BuildResultResolver {
  @override
  BuildResult resolve(BuildConfig config, {Duration? duration}) {
    return BuildLinuxResult(config)..duration = duration;
  }
}

class BuildLinuxResult extends BuildResult {
  BuildLinuxResult(BuildConfig config) : super(config);

  String? _arch;

  String? _archFromTargetPlatform() {
    final targetPlatform = config.arguments['target-platform']?.toString();
    if (targetPlatform == 'linux-arm64') {
      return 'arm64';
    }
    if (targetPlatform == 'linux-x64') {
      return 'x64';
    }
    return null;
  }

  String get arch {
    _arch ??= _archFromTargetPlatform();
    if (_arch != null) {
      return _arch!;
    }
    ProcessResult r = Process.runSync('uname', ['-m']);
    if ('${r.stdout}'.trim() == 'aarch64') {
      _arch = 'arm64';
    } else {
      _arch = 'x64';
    }
    return _arch!;
  }

  set arch(String value) {
    _arch = value;
  }

  @override
  Directory get outputDirectory {
    String buildMode = config.mode.name;
    String path = 'build/linux/$arch/$buildMode/bundle';
    return Directory(path);
  }
}
