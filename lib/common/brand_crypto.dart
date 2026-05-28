import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:jichanglianmeng/common/brand.dart';

const _ivLength = 12;
const _tagLength = 16;

Map<String, dynamic> decryptBrandPayload(String base64Payload) {
  return decryptBrandPayloadWithKey(base64Payload, BrandConfig.configKeyHex);
}

Map<String, dynamic> decryptBrandPayloadWithKey(
  String base64Payload,
  String keyHex,
) {
  final keyBytes = _parseKeyHex(keyHex);
  final raw = base64.decode(base64Payload);
  if (raw.length <= _ivLength + _tagLength) {
    throw FormatException('brand payload too short');
  }
  final iv = IV(Uint8List.fromList(raw.sublist(0, _ivLength)));
  final cipherTextAndTag = Encrypted(
    Uint8List.fromList(raw.sublist(_ivLength)),
  );
  final key = Key(keyBytes);
  final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
  final decrypted = encrypter.decrypt(cipherTextAndTag, iv: iv);
  final decoded = json.decode(decrypted);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('brand payload is not a JSON object');
  }
  return decoded;
}

Uint8List encryptBrandPayloadBytes(String plainText, String keyHex) {
  final keyBytes = _parseKeyHex(keyHex);
  final iv = IV.fromSecureRandom(_ivLength);
  final key = Key(keyBytes);
  final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
  final encrypted = encrypter.encrypt(plainText, iv: iv);
  return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
}

String encryptBrandPayload(String plainText, String keyHex) {
  return base64.encode(encryptBrandPayloadBytes(plainText, keyHex));
}

Uint8List _parseKeyHex(String hex) {
  final normalized = hex.trim();
  if (normalized.length != 64) {
    throw FormatException('brand config key must be 64 hex characters');
  }
  final keyBytes = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    final byte = int.tryParse(normalized.substring(i * 2, i * 2 + 2), radix: 16);
    if (byte == null) {
      throw FormatException('brand config key contains invalid hex');
    }
    keyBytes[i] = byte;
  }
  return keyBytes;
}
