import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  static const _formatTag = 'kovira-encrypted-v3';

  static const _kdfIterations = 100000;

  String encryptWithPassphrase(String plaintext, String passphrase) {
    final salt = _randomBytes(16);
    final iv = enc.IV.fromSecureRandom(16);
    final key = _deriveKey(passphrase, salt, _kdfIterations);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return jsonEncode({
      'format': _formatTag,
      'kdf': 'pbkdf2-sha256',
      'iter': _kdfIterations,
      'salt': base64.encode(salt),
      'iv': base64.encode(iv.bytes),
      'ct': base64.encode(encrypted.bytes),
    });
  }

  String decryptWithPassphrase(String envelope, String passphrase) {
    final json = jsonDecode(envelope) as Map<String, dynamic>;
    if (json['format'] != _formatTag) {
      throw const FormatException('Not a passphrase-encrypted backup');
    }
    final salt = base64.decode(json['salt'] as String);
    final iv = enc.IV(base64.decode(json['iv'] as String));
    final ct = base64.decode(json['ct'] as String);
    final iter = (json['iter'] as int?) ?? _kdfIterations;
    final key = _deriveKey(passphrase, salt, iter);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt(enc.Encrypted(ct), iv: iv);
  }

  static bool isPassphraseFormat(String raw) {
    final t = raw.trim();
    if (!t.startsWith('{')) return false;
    try {
      final j = jsonDecode(t);
      return j is Map &&
          j['format'] is String &&
          (j['format'] as String).startsWith('kovira-encrypted-v');
    } catch (_) {
      return false;
    }
  }

  static enc.Key _deriveKey(String passphrase, Uint8List salt, int iter) {
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
    pbkdf2.init(pc.Pbkdf2Parameters(salt, iter, 32));
    final keyBytes = pbkdf2.process(
      Uint8List.fromList(utf8.encode(passphrase)),
    );
    return enc.Key(keyBytes);
  }

  static Uint8List _randomBytes(int n) {
    final rng = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => rng.nextInt(256)));
  }

  static const _keySecret = 'enc_secret_v1';

  Future<String?> _getLegacySecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySecret);
  }

  Future<enc.Key> _legacyKey() async {
    final secret = await _getLegacySecret();
    if (secret == null) {
      throw StateError(
        'No legacy key on this install — backup was made elsewhere',
      );
    }
    final hash = sha256.convert(utf8.encode(secret));
    return enc.Key(Uint8List.fromList(hash.bytes));
  }

  Future<String> decryptLegacy(String cipherBase64) async {
    final key = await _legacyKey();
    final combined = base64.decode(cipherBase64);
    final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
    final cipherBytes = Uint8List.fromList(combined.sublist(16));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt(enc.Encrypted(cipherBytes), iv: iv);
  }

  static bool isLegacyEncrypted(String data) {
    final trimmed = data.trim();
    return !trimmed.startsWith('{') && !trimmed.startsWith('[');
  }
}
