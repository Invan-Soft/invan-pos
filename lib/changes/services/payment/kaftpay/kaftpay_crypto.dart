/*
    Kaftpay (pp-pos-api) — so'rov imzosi va kaft vektorini shifrlash.

    Token yo'q: HAR so'rov o'zi imzolanadi (swagger §1):
      X-Signature = base64(HMAC-SHA256(secret, canonical))
      canonical   = METHOD \n PATH \n base64(sha256(body)) \n X-Timestamp \n X-Nonce
    PATH — context'siz va query'siz (`/api/v1/pay`, `/pp-pos-api/api/v1/pay` emas).
    Body — aynan yuboriladigan baytlar: imzodan keyin JSON qayta serializatsiya
    qilinsa imzo buziladi.

    `palmDataEnc` (identify/enroll) — kaft vektori ochiq JSON'da yurmasligi uchun:
      kalit = HKDF-SHA256(ikm = secret (UTF-8), salt = "TS\nNONCE", info = "pp-palm-vector:v1")
      blob  = base64(IV(12) ‖ AES-256-GCM ciphertext ‖ tag(16))
    TS/NONCE — aynan shu so'rovning header qiymatlari, shuning uchun body imzodan
    OLDIN, o'sha TS/NONCE bilan yasaladi.

    Testlar: test/kaftpay_crypto_test.dart (hujjatdagi known-answer vektori).
*/

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

class KaftpaySigner {
  const KaftpaySigner._();

  /// Bo'sh body (GET) xeshi — swagger'dagi qat'iy nuqta.
  static const String emptyBodyHash =
      '47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=';

  static String bodyHash(List<int> body) =>
      base64.encode(crypto.sha256.convert(body).bytes);

  static String canonical({
    required String method,
    required String path,
    required String bodyHash,
    required String timestamp,
    required String nonce,
  }) =>
      [method.toUpperCase(), path, bodyHash, timestamp, nonce].join('\n');

  static String sign({
    required String secret,
    required String method,
    required String path,
    required List<int> body,
    required String timestamp,
    required String nonce,
  }) {
    final canon = canonical(
      method: method,
      path: path,
      bodyHash: bodyHash(body),
      timestamp: timestamp,
      nonce: nonce,
    );
    final mac = crypto.Hmac(crypto.sha256, utf8.encode(secret))
        .convert(utf8.encode(canon));
    return base64.encode(mac.bytes);
  }
}

class KaftpayPalmCipher {
  const KaftpayPalmCipher._();

  /// HKDF `info`. Bo'sh `info` boshqa kalit beradi → server `1106`.
  static const String info = 'pp-palm-vector:v1';

  static const int ivLength = 12;
  static const int tagLength = 16;

  static final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final AesGcm _aes = AesGcm.with256bits();

  static Future<List<int>> deriveKey({
    required String secret,
    required String timestamp,
    required String nonce,
    String hkdfInfo = info,
  }) async {
    final key = await _hkdf.deriveKey(
      secretKey: SecretKey(utf8.encode(secret)),
      nonce: utf8.encode('$timestamp\n$nonce'),
      info: utf8.encode(hkdfInfo),
    );
    return key.extractBytes();
  }

  /// [iv] faqat testda beriladi; ishda har so'rovga yangi CSPRNG IV.
  static Future<String> encryptBytes({
    required String secret,
    required String timestamp,
    required String nonce,
    required List<int> plaintext,
    List<int>? iv,
  }) async {
    final ivBytes = iv ?? randomIv();
    if (ivBytes.length != ivLength) {
      throw ArgumentError('IV $ivLength bayt bo\'lishi kerak');
    }
    final key = await deriveKey(
      secret: secret,
      timestamp: timestamp,
      nonce: nonce,
    );
    final box = await _aes.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: ivBytes,
    );
    return base64.encode([...ivBytes, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Teskari amal — server nima ko'rishini testda tekshirish uchun.
  /// Kalit/IV/tag mos kelmasa [SecretBoxAuthenticationError].
  static Future<List<int>> decryptBytes({
    required String secret,
    required String timestamp,
    required String nonce,
    required String palmDataEnc,
  }) async {
    final raw = base64.decode(palmDataEnc);
    if (raw.length < ivLength + tagLength) {
      throw const FormatException('palmDataEnc juda qisqa');
    }
    final key = await deriveKey(
      secret: secret,
      timestamp: timestamp,
      nonce: nonce,
    );
    final box = SecretBox(
      raw.sublist(ivLength, raw.length - tagLength),
      nonce: raw.sublist(0, ivLength),
      mac: Mac(raw.sublist(raw.length - tagLength)),
    );
    return _aes.decrypt(box, secretKey: SecretKey(key));
  }

  static final Random _random = Random.secure();

  static List<int> randomIv() =>
      List<int>.generate(ivLength, (_) => _random.nextInt(256));
}
