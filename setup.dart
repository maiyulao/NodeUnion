// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';

enum Target { windows, linux, android, macos }

extension TargetExt on Target {
  String get os {
    if (this == Target.macos) {
      return 'darwin';
    }
    return name;
  }

  bool get same {
    if (this == Target.android) {
      return true;
    }
    if (Platform.isWindows && this == Target.windows) {
      return true;
    }
    if (Platform.isLinux && this == Target.linux) {
      return true;
    }
    if (Platform.isMacOS && this == Target.macos) {
      return true;
    }
    return false;
  }

  String get dynamicLibExtensionName {
    final String extensionName;
    switch (this) {
      case Target.android || Target.linux:
        extensionName = '.so';
        break;
      case Target.windows:
        extensionName = '.dll';
        break;
      case Target.macos:
        extensionName = '.dylib';
        break;
    }
    return extensionName;
  }

  String get executableExtensionName {
    final String extensionName;
    switch (this) {
      case Target.windows:
        extensionName = '.exe';
        break;
      default:
        extensionName = '';
        break;
    }
    return extensionName;
  }
}

enum Mode { core, lib }

enum Arch { amd64, arm64, arm }

class BuildItem {
  Target target;
  Arch? arch;
  String? archName;

  BuildItem({required this.target, this.arch, this.archName});

  @override
  String toString() {
    return 'BuildLibItem{target: $target, arch: $arch, archName: $archName}';
  }
}

class Build {
  static List<BuildItem> get buildItems => [
    BuildItem(target: Target.macos, arch: Arch.arm64),
    BuildItem(target: Target.macos, arch: Arch.amd64),
    BuildItem(target: Target.linux, arch: Arch.arm64),
    BuildItem(target: Target.linux, arch: Arch.amd64),
    BuildItem(target: Target.windows, arch: Arch.amd64),
    BuildItem(target: Target.windows, arch: Arch.arm64),
    BuildItem(target: Target.android, arch: Arch.arm, archName: 'armeabi-v7a'),
    BuildItem(target: Target.android, arch: Arch.arm64, archName: 'arm64-v8a'),
    BuildItem(target: Target.android, arch: Arch.amd64, archName: 'x86_64'),
  ];

  static String get appName => 'NodeUnion';

  static String get coreName => 'FlClashCore';

  static String get libName => 'libclash';

  static String get outDir => join(current, libName);

  static String get _coreDir => join(current, 'core');

  static String get _servicesDir => join(current, 'services', 'helper');

  static String get distPath => join(current, 'dist');

  static String? _resolveAndroidNdkPath() {
    final environment = Platform.environment;
    final directNdk = environment['ANDROID_NDK'] ?? environment['ANDROID_NDK_HOME'];
    if (directNdk != null && directNdk.isNotEmpty) {
      return directNdk;
    }
    final sdkRoot = environment['ANDROID_SDK_ROOT'] ?? environment['ANDROID_HOME'];
    if (sdkRoot == null || sdkRoot.isEmpty) {
      return null;
    }
    final ndkRoot = Directory(join(sdkRoot, 'ndk'));
    if (ndkRoot.existsSync()) {
      final versions = ndkRoot
          .listSync()
          .whereType<Directory>()
          .where((dir) => !basename(dir.path).startsWith('.'))
          .toList()
        ..sort((a, b) => basename(b.path).compareTo(basename(a.path)));
      if (versions.isNotEmpty) {
        return versions.first.path;
      }
    }
    final ndkBundle = Directory(join(sdkRoot, 'ndk-bundle'));
    if (ndkBundle.existsSync()) {
      return ndkBundle.path;
    }
    return null;
  }

  static String _getCc(BuildItem buildItem) {
    if (buildItem.target == Target.android) {
      final ndk = _resolveAndroidNdkPath();
      if (ndk == null) {
        throw StateError(
          'Android NDK not found. Please set ANDROID_NDK/ANDROID_NDK_HOME, or configure ANDROID_SDK_ROOT (contains ndk/<version>).',
        );
      }
      final prebuiltDir = Directory(
        join(ndk, 'toolchains', 'llvm', 'prebuilt'),
      );
      if (!prebuiltDir.existsSync()) {
        throw StateError('Invalid Android NDK path: $ndk');
      }
      final prebuiltDirList = prebuiltDir
          .listSync()
          .where((file) => !basename(file.path).startsWith('.'))
          .toList();
      if (prebuiltDirList.isEmpty) {
        throw StateError('No NDK prebuilt toolchains found in: ${prebuiltDir.path}');
      }
      final map = {
        'armeabi-v7a': 'armv7a-linux-androideabi21-clang',
        'arm64-v8a': 'aarch64-linux-android21-clang',
        'x86': 'i686-linux-android21-clang',
        'x86_64': 'x86_64-linux-android21-clang',
      };
      final compiler = map[buildItem.archName];
      if (compiler == null) {
        throw StateError('Unsupported Android archName: ${buildItem.archName}');
      }
      return join(prebuiltDirList.first.path, 'bin', compiler);
    }
    return 'gcc';
  }

  static String get tags => 'with_gvisor';

  static Future<void> exec(
    List<String> executable, {
    String? name,
    Map<String, String>? environment,
    String? workingDirectory,
    bool runInShell = true,
  }) async {
    if (name != null) print('run $name');
    print('exec: ${executable.join(' ')}');
    print('env: ${environment.toString()}');
    final process = await Process.start(
      executable[0],
      executable.sublist(1),
      environment: environment,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );
    process.stdout.listen((data) {
      print(utf8.decode(data));
    });
    process.stderr.listen((data) {
      print(utf8.decode(data));
    });
    final exitCode = await process.exitCode;
    if (exitCode != 0 && name != null) throw '$name error';
  }

  static Future<String> calcSha256(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw 'File not exists';
    }
    final stream = file.openRead();
    return sha256.convert(await stream.reduce((a, b) => a + b)).toString();
  }

  static Future<List<String>> buildCore({
    required Mode mode,
    required Target target,
    Arch? arch,
  }) async {
    final isLib = mode == Mode.lib;

    final items = buildItems.where((element) {
      return element.target == target &&
          (arch == null ? true : element.arch == arch);
    }).toList();

    final List<String> corePaths = [];

    final targetOutFilePath = join(outDir, target.name);
    final targetOutFile = File(targetOutFilePath);
    if (await targetOutFile.exists()) {
      await targetOutFile.delete(recursive: true);
      await Directory(targetOutFilePath).create(recursive: true);
    }
    for (final item in items) {
      final outFilePath = join(targetOutFilePath, item.archName);
      final file = File(outFilePath);
      if (file.existsSync()) {
        file.deleteSync(recursive: true);
      }

      final fileName = isLib
          ? '$libName${item.target.dynamicLibExtensionName}'
          : '$coreName${item.target.executableExtensionName}';
      final realOutPath = join(outFilePath, fileName);
      corePaths.add(realOutPath);

      final Map<String, String> env = {};
      env['GOOS'] = item.target.os;
      if (item.arch != null) {
        env['GOARCH'] = item.arch!.name;
      }
      if (isLib) {
        env['CGO_ENABLED'] = '1';
        env['CC'] = _getCc(item);
        env['CFLAGS'] = '-O3 -Werror';
      } else {
        env['CGO_ENABLED'] = '0';
      }
      final execLines = [
        'go',
        'build',
        '-ldflags=-w -s',
        '-tags=$tags',
        if (isLib) '-buildmode=c-shared',
        '-o',
        realOutPath,
      ];
      await exec(
        execLines,
        name: 'build core',
        environment: env,
        workingDirectory: _coreDir,
      );
      if (isLib && item.archName != null) {
        await adjustLibOut(
          targetOutFilePath: targetOutFilePath,
          outFilePath: outFilePath,
          archName: item.archName!,
        );
      }
    }

    return corePaths;
  }

  static Future<void> adjustLibOut({
    required String targetOutFilePath,
    required String outFilePath,
    required String archName,
  }) async {
    final includesPath = join(targetOutFilePath, 'includes');
    final realOutPath = join(includesPath, archName);
    await Directory(realOutPath).create(recursive: true);
    final targetOutFiles = Directory(outFilePath).listSync();
    final coreFiles = Directory(_coreDir).listSync();
    for (final file in [...targetOutFiles, ...coreFiles]) {
      if (!file.path.endsWith('.h')) {
        continue;
      }
      final targetFilePath = join(realOutPath, basename(file.path));
      final realFile = File(file.path);
      await realFile.copy(targetFilePath);
      if (coreFiles.contains(file)) {
        continue;
      }
      await realFile.delete();
    }
  }

  static Future<void> buildHelper(
    Target target,
    String token,
    Arch arch,
  ) async {
    final rustTarget = switch (arch) {
      Arch.arm64 => 'aarch64-pc-windows-msvc',
      Arch.amd64 => 'x86_64-pc-windows-msvc',
      Arch.arm => throw UnsupportedError('Windows helper does not support arm'),
    };
    await exec(
      [
        'cargo',
        'build',
        '--release',
        '--features',
        'windows-service',
        '--target',
        rustTarget,
      ],
      environment: {'TOKEN': token},
      name: 'build helper',
      workingDirectory: _servicesDir,
    );
    final outPath = join(
      _servicesDir,
      'target',
      rustTarget,
      'release',
      'helper${target.executableExtensionName}',
    );
    final targetPath = join(
      outDir,
      target.name,
      'FlClashHelperService${target.executableExtensionName}',
    );
    await File(outPath).copy(targetPath);
  }

  static List<String> getExecutable(String command) {
    return command.split(' ');
  }

  static Future<void> getDistributor() async {
    final distributorDir = join(
      current,
      'plugins',
      'flutter_distributor',
      'packages',
      'flutter_distributor',
    );

    await exec(
      name: 'clean distributor',
      Build.getExecutable('flutter clean'),
      workingDirectory: distributorDir,
    );
    await exec(
      name: 'upgrade distributor',
      Build.getExecutable('flutter pub upgrade'),
      workingDirectory: distributorDir,
    );
    await exec(
      name: 'get distributor',
      Build.getExecutable('dart pub global activate -s path $distributorDir'),
    );
  }

  static void copyFile(String sourceFilePath, String destinationFilePath) {
    final sourceFile = File(sourceFilePath);
    if (!sourceFile.existsSync()) {
      throw 'SourceFilePath not exists';
    }
    final destinationFile = File(destinationFilePath);
    final destinationDirectory = destinationFile.parent;
    if (!destinationDirectory.existsSync()) {
      destinationDirectory.createSync(recursive: true);
    }
    try {
      sourceFile.copySync(destinationFilePath);
      print('File copied successfully!');
    } catch (e) {
      print('Failed to copy file: $e');
    }
  }
}

class BuildCommand extends Command {
  Target target;

  BuildCommand({required this.target}) {
    if (target == Target.android) {
      argParser.addOption(
        'arch',
        valueHelp: arches.map((e) => e.name).join(','),
        help: 'Android ABI filter (optional)',
      );
    } else {
      argParser.addOption(
        'arch',
        valueHelp: 'amd64,arm64',
        help:
            'Target CPU architecture (default: host). '
            'Cross-arch builds are supported on the native OS only.',
      );
    }
    argParser.addOption(
      'out',
      valueHelp: ['app', 'core'].join(','),
      help: 'Build output: app (default, package with env.json) or core (kernel only)',
    );
    argParser.addOption(
      'env',
      valueHelp: ['pre', 'stable'].join(','),
      help:
          'Override APP_ENV in env.json. If omitted, keeps the value already in env.json.',
    );
  }

  @override
  String get description => 'build $name application';

  @override
  String get name => target.name;

  List<Arch> get arches => Build.buildItems
      .where((element) => element.target == target && element.arch != null)
      .map((e) => e.arch!)
      .toList();

  static String flutterTargetPlatform(Target target, Arch arch) {
    return switch (target) {
      Target.macos =>
        arch == Arch.arm64 ? 'darwin-arm64' : 'darwin-x64',
      Target.windows =>
        arch == Arch.arm64 ? 'windows-arm64' : 'windows-x64',
      Target.linux => arch == Arch.arm64 ? 'linux-arm64' : 'linux-x64',
      Target.android => throw UnsupportedError('Use android target map'),
    };
  }

  Future<Arch> _resolveArch(String? archName) async {
    if (archName != null) {
      final matched =
          arches.where((element) => element.name == archName).toList();
      if (matched.isEmpty) {
        throw 'Invalid arch "$archName" for ${target.name}. '
            'Valid: ${arches.map((e) => e.name).join(", ")}';
      }
      return matched.first;
    }
    if (Platform.isMacOS || Platform.isLinux) {
      final result = await Process.run('uname', ['-m']);
      final machine = result.stdout.toString().trim();
      if (machine == 'aarch64' || machine == 'arm64') {
        return Arch.arm64;
      }
      return Arch.amd64;
    }
    if (Platform.isWindows) {
      final hostArch =
          Platform.environment['PROCESSOR_ARCHITECTURE']?.toUpperCase();
      if (hostArch == 'ARM64') {
        return Arch.arm64;
      }
      return Arch.amd64;
    }
    throw 'Cannot detect host architecture';
  }

  void _assertNativePlatform() {
    if (!target.same) {
      throw 'Cannot package ${target.name} on ${Platform.operatingSystem}. '
          'Run on a ${target.name} host, or use --out=core to cross-build the core only.';
    }
  }

  bool _supportsFlutterTargetPlatform(Target target) {
    return target == Target.linux || target == Target.android;
  }

  Future<void> _assertFlutterPackageArch(Arch arch) async {
    if (_supportsFlutterTargetPlatform(target)) {
      return;
    }
    final hostArch = await _resolveArch(null);
    if (arch != hostArch) {
      throw 'Flutter stable cannot cross-build ${target.name} apps '
          '(host: ${hostArch.name}, requested: ${arch.name}). '
          'Run on a ${arch.name} ${target.name} machine, or use --out=core '
          'to cross-build the Go core only.';
    }
  }

  List<String> _distributorExtraArgs({
    required String resolvedArchName,
    required String? flutterPlatform,
  }) {
    final args = <String>['--description', resolvedArchName];
    if (flutterPlatform != null && _supportsFlutterTargetPlatform(target)) {
      args.addAll(['--build-target-platform', flutterPlatform]);
    }
    return args;
  }

  Future<void> _buildEnvFile({String? envOverride, String? coreSha256}) async {
    final envFilePath = join(current, 'env.json');
    final envFile = File(envFilePath);
    final exampleFile = File(join(current, 'env.json.example'));
    final data = <String, dynamic>{};

    if (exampleFile.existsSync()) {
      try {
        final template = json.decode(await exampleFile.readAsString());
        if (template is Map<String, dynamic>) {
          data.addAll(template);
        }
      } catch (_) {}
    }

    if (await envFile.exists()) {
      try {
        final existing = json.decode(await envFile.readAsString());
        if (existing is Map<String, dynamic>) {
          data.addAll(existing);
        }
      } catch (_) {}
    }

    for (final key in [
      'APP_ENV',
      'BRAND_CONFIG_URLS',
      'BRAND_CONFIG_KEY',
      'CORE_SHA256',
    ]) {
      final value = Platform.environment[key];
      if (value != null && value.isNotEmpty) {
        data[key] = value;
      }
    }

    if (envOverride != null) {
      data['APP_ENV'] = envOverride;
    } else if (data['APP_ENV'] == null || data['APP_ENV'].toString().isEmpty) {
      data['APP_ENV'] = 'pre';
    }
    if (coreSha256 != null) {
      data['CORE_SHA256'] = coreSha256;
    }

    await envFile.create(recursive: true);
    await envFile.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(data)}\n',
    );

    print('Updated env.json at $envFilePath');
    final brandUrls = data['BRAND_CONFIG_URLS']?.toString() ?? '';
    final brandKey = data['BRAND_CONFIG_KEY']?.toString() ?? '';
    if (brandUrls.isEmpty || brandKey.isEmpty) {
      print(
        'WARNING: BRAND_CONFIG_URLS or BRAND_CONFIG_KEY is missing. '
        'Copy env.json.example to env.json and set your brand config before building the app.',
      );
    }
  }

  void _printFlutterBuildHint(Target target) {
    print('');
    print('Core-only build finished. env.json has been updated.');
    print(
      'To package the app with env.json on ${target.name}, run:\n'
      '  dart run setup.dart ${target.name}'
      '${target == Target.android ? '' : ' --arch <amd64|arm64>'}',
    );
  }

  Future<void> _buildDistributor({
    required Target target,
    required String targets,
    List<String> flutterBuildArgs = const [
      'verbose',
      'dart-define-from-file=env.json',
    ],
    List<String> extraArgs = const [],
  }) async {
    await Build.getDistributor();
    final envFilePath = join(current, 'env.json');
    if (!File(envFilePath).existsSync()) {
      throw 'env.json not found at $envFilePath';
    }

    try {
      final envData = json.decode(await File(envFilePath).readAsString());
      if (envData is Map<String, dynamic>) {
        print(
          'Injecting dart-define from env.json: ${envData.keys.join(', ')}',
        );
      }
    } catch (_) {}

    final command = <String>[
      'flutter_distributor',
      'package',
      '--skip-clean',
      '--platform',
      target.name,
      '--targets',
      targets,
      '--flutter-build-args',
      flutterBuildArgs.join(','),
      ...extraArgs,
    ];

    await Build.exec(
      command,
      name: name,
      workingDirectory: current,
      runInShell: true,
    );
  }

  Future<void> _getLinuxDependencies(Arch arch) async {
    await Build.exec(Build.getExecutable('sudo apt update -y'));
    await Build.exec(
      Build.getExecutable('sudo apt install -y ninja-build libgtk-3-dev'),
    );
    await Build.exec(
      Build.getExecutable('sudo apt install -y libayatana-appindicator3-dev'),
    );
    await Build.exec(
      Build.getExecutable('sudo apt-get install -y libkeybinder-3.0-dev'),
    );
    await Build.exec(Build.getExecutable('sudo apt install -y locate'));
    if (arch == Arch.amd64) {
      await Build.exec(Build.getExecutable('sudo apt install -y rpm patchelf'));
      await Build.exec(Build.getExecutable('sudo apt install -y libfuse2'));

      final downloadName = arch == Arch.amd64 ? 'x86_64' : 'aarch64';
      await Build.exec(
        Build.getExecutable(
          'wget -O appimagetool https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$downloadName.AppImage',
        ),
      );
      await Build.exec(Build.getExecutable('chmod +x appimagetool'));
      await Build.exec(
        Build.getExecutable('sudo mv appimagetool /usr/local/bin/'),
      );
    }
  }

  Future<void> _getMacosDependencies() async {
    await Build.exec(Build.getExecutable('npm install -g appdmg'));
  }

  Future<String?> get systemArch async {
    if (Platform.isWindows) {
      return Platform.environment['PROCESSOR_ARCHITECTURE'];
    } else if (Platform.isLinux || Platform.isMacOS) {
      final result = await Process.run('uname', ['-m']);
      return result.stdout.toString().trim();
    }
    return null;
  }

  @override
  Future<void> run() async {
    final mode = target == Target.android ? Mode.lib : Mode.core;
    final String out = argResults?['out'] ?? 'app';
    final archName = argResults?['arch'];
    final envOverride =
        (argResults?.wasParsed('env') ?? false) ? argResults!['env'] as String : null;
    final Arch? arch = target == Target.android && archName == null
        ? null
        : await _resolveArch(archName);
    final resolvedArchName = arch?.name ?? 'all';
    final flutterPlatform = arch == null || target == Target.android
        ? null
        : BuildCommand.flutterTargetPlatform(target, arch);

    final corePaths = await Build.buildCore(
      target: target,
      arch: arch,
      mode: mode,
    );

    String? coreSha256;

    if (Platform.isWindows && target == Target.windows) {
      coreSha256 = await Build.calcSha256(corePaths.first);
      await Build.buildHelper(target, coreSha256, arch!);
    }
    await _buildEnvFile(envOverride: envOverride, coreSha256: coreSha256);
    if (out != 'app') {
      _printFlutterBuildHint(target);
      return;
    }

    _assertNativePlatform();
    if (arch != null) {
      await _assertFlutterPackageArch(arch);
    }
    if (flutterPlatform != null && _supportsFlutterTargetPlatform(target)) {
      print(
        'Building ${target.name} package for $resolvedArchName ($flutterPlatform)',
      );
    } else if (target != Target.android) {
      print('Building ${target.name} package for $resolvedArchName (host arch)');
    } else {
      print('Building android package for $resolvedArchName');
    }

    switch (target) {
      case Target.windows:
        await _buildDistributor(
          target: target,
          targets: 'exe,zip',
          extraArgs: _distributorExtraArgs(
            resolvedArchName: resolvedArchName,
            flutterPlatform: flutterPlatform,
          ),
        );
        return;
      case Target.linux:
        final targets = [
          'deb',
          if (arch == Arch.amd64) 'appimage',
          if (arch == Arch.amd64) 'rpm',
        ].join(',');
        await _getLinuxDependencies(arch!);
        await _buildDistributor(
          target: target,
          targets: targets,
          extraArgs: _distributorExtraArgs(
            resolvedArchName: resolvedArchName,
            flutterPlatform: flutterPlatform,
          ),
        );
        return;
      case Target.android:
        final targetMap = {
          Arch.arm: 'android-arm',
          Arch.arm64: 'android-arm64',
          Arch.amd64: 'android-x64',
        };
        final defaultArches = [Arch.arm, Arch.arm64, Arch.amd64];
        final defaultTargets = defaultArches
            .where((element) => arch == null ? true : element == arch)
            .map((e) => targetMap[e]!)
            .join(',');
        await _buildDistributor(
          target: target,
          targets: 'apk',
          flutterBuildArgs: const [
            'verbose',
            'dart-define-from-file=env.json',
            'split-per-abi',
          ],
          extraArgs: ['--build-target-platform', defaultTargets],
        );
        return;
      case Target.macos:
        await _getMacosDependencies();
        await _buildDistributor(
          target: target,
          targets: 'dmg',
          extraArgs: _distributorExtraArgs(
            resolvedArchName: resolvedArchName,
            flutterPlatform: flutterPlatform,
          ),
        );
        return;
    }
  }
}

Future<void> main(Iterable<String> args) async {
  final runner = CommandRunner('setup', 'build Application');
  runner.addCommand(BuildCommand(target: Target.android));
  runner.addCommand(BuildCommand(target: Target.linux));
  runner.addCommand(BuildCommand(target: Target.windows));
  runner.addCommand(BuildCommand(target: Target.macos));
  runner.run(args);
}
