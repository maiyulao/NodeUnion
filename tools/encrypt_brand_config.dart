import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:jichanglianmeng/common/brand_crypto.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('input', abbr: 'i', help: 'Plain JSON input file')
    ..addOption('key', abbr: 'k', help: '64-char hex AES key')
    ..addOption('output', abbr: 'o', help: 'Encrypted output file');
  final results = parser.parse(arguments);

  final inputPath = results['input'] as String?;
  final key = results['key'] as String?;
  final outputPath = results['output'] as String?;

  if (inputPath == null || key == null || outputPath == null) {
    stderr.writeln(
      'Usage: dart run tools/encrypt_brand_config.dart '
      '-i brand.plain.json -k <64-hex-key> -o brand.json',
    );
    exit(64);
  }

  final plainText = await File(inputPath).readAsString();
  json.decode(plainText) as Map<String, dynamic>;

  final payload = encryptBrandPayload(plainText, key);
  final output = json.encode({'v': 1, 'payload': payload});
  await File(outputPath).writeAsString('${output.trim()}\n');
  stdout.writeln('Wrote encrypted brand config to $outputPath');
}
