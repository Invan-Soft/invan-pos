// Kaftpay — so'rov imzosi va kaft vektorini shifrlash testlari.
//
// Nega kerak: imzo yoki shifr bir bayt farq qilsa server 1100/1106 beradi va
// kaft bilan to'lov umuman ishlamaydi — buni faqat haqiqiy terminalda bilib
// olish qimmat. Shuning uchun:
//   - shifr: Kaftpay hujjatidagi known-answer vektori (server ham shu
//     vektor bilan build qilinadi — PalmVectorCipherTest);
//   - imzo: Dart'dan mustaqil, Python (hmac/hashlib) bilan hisoblangan
//     qiymatlar (2026-10-29).
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_crypto.dart';

String hex(List<int> b) =>
    b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

List<int> unhex(String s) => [
      for (var i = 0; i < s.length; i += 2)
        int.parse(s.substring(i, i + 2), radix: 16)
    ];

const kSecret = 'kat-terminal-secret';
const kTs = '1893456000';
const kNonce = '6f1c9e2a-3d47-4b58-9c10-2e5f7a8b4d33';

void main() {
  group('KaftpaySigner', () {
    test('bo\'sh body xeshi swagger\'dagi qat\'iy nuqta bilan bir xil', () {
      expect(KaftpaySigner.bodyHash(const []), KaftpaySigner.emptyBodyHash);
      expect(KaftpaySigner.emptyBodyHash,
          '47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=');
    });

    test('canonical — 5 qism \\n bilan, METHOD katta harfda', () {
      expect(
        KaftpaySigner.canonical(
          method: 'post',
          path: '/api/v1/pay',
          bodyHash: 'H',
          timestamp: '1',
          nonce: 'N',
        ),
        'POST\n/api/v1/pay\nH\n1\nN',
      );
    });

    test('GET /ping imzosi Python bilan bir xil', () {
      expect(
        KaftpaySigner.sign(
          secret: kSecret,
          method: 'GET',
          path: '/api/v1/ping',
          body: const [],
          timestamp: kTs,
          nonce: kNonce,
        ),
        'bIFmhcMCUv+n+DOipXRKBalTdO1UAiALXLZaSZ88QEM=',
      );
    });

    test('POST /pay imzosi Python bilan bir xil (aniq body baytlari)', () {
      const body = '{"requestId":"7e9a4b21-3c8d-4f56-9a0b-2d4e6f8a1c33",'
          '"consumerGuid":"9c1f2a77-5d63-4a10-8f2b-1c0d5e6a7b88",'
          '"amount":2500000,"cashierId":"c-17","cashierName":"Nodira S."}';
      final bytes = utf8.encode(body);
      expect(KaftpaySigner.bodyHash(bytes),
          'ZS07RJfrNhLnOaGX78L6Df0BN0UT0cW7mz2GFz3lIkM=');
      expect(
        KaftpaySigner.sign(
          secret: kSecret,
          method: 'POST',
          path: '/api/v1/pay',
          body: bytes,
          timestamp: kTs,
          nonce: kNonce,
        ),
        'uWEhx3okoLx8aWJamI4SVBmJ39nU5stu45lNbwtSfDY=',
      );
    });

    test('kirill secret va body — UTF-8 baytlari imzolanadi', () {
      final body = utf8.encode(
          '{"cashierId":"c-17","cashierName":"Нодира С.","reason":"qaytarildi"}');
      expect(KaftpaySigner.bodyHash(body),
          'o2AZhENA0eM9mrBWPrvjIoIRbKcMTVZscVaqrwaSj9E=');
      expect(
        KaftpaySigner.sign(
          secret: 'sekret-ўзбек',
          method: 'POST',
          path: '/api/v1/pay/5b1e0d84-6f2a-4c37-9b55-0e7a3c1d9f60/refund',
          body: body,
          timestamp: kTs,
          nonce: kNonce,
        ),
        'e7A8rdq9bRKMNP8wJg9x7mN/EJlPAJBHB0GDIHBJZ4U=',
      );
    });

    test('body bir bayt o\'zgarsa imzo boshqa', () {
      String s(String body) => KaftpaySigner.sign(
            secret: kSecret,
            method: 'POST',
            path: '/api/v1/pay',
            body: utf8.encode(body),
            timestamp: kTs,
            nonce: kNonce,
          );
      expect(s('{"amount":100}'), isNot(s('{"amount": 100}')));
    });
  });

  group('KaftpayPalmCipher — hujjatdagi test vektori', () {
    test('HKDF kaliti', () async {
      final key = await KaftpayPalmCipher.deriveKey(
          secret: kSecret, timestamp: kTs, nonce: kNonce);
      expect(hex(key),
          '0bae90ee94bb1c68d5d441f52166e64df275362320836bcfb2d4e93321e3a361');
    });

    test('bo\'sh info — hujjatdagi "noto\'g\'ri" kalit (info shartligi)',
        () async {
      final key = await KaftpayPalmCipher.deriveKey(
          secret: kSecret, timestamp: kTs, nonce: kNonce, hkdfInfo: '');
      expect(hex(key),
          '8f8f3a000791c73ce3f0d9654b4ebfe0ec521da6966decaba0e8b9baa5ac11c3');
    });

    test('kirill secret — Python HKDF bilan bir xil', () async {
      final key = await KaftpayPalmCipher.deriveKey(
          secret: 'sekret-ўзбек', timestamp: '1700000000', nonce: 'abc');
      expect(hex(key),
          '1878cf4b872ab5bfabf9beea04153e27e9f775c1f0a783e28c2a23162cee5812');
    });

    test('belgilangan IV bilan shifr — hujjatdagi palmDataEnc', () async {
      final blob = await KaftpayPalmCipher.encryptBytes(
        secret: kSecret,
        timestamp: kTs,
        nonce: kNonce,
        plaintext: utf8.encode(
            '{"ir": [0.125, -0.5, 0.0, 3.75, -12.5], "rgb": [1.5, -2.25]}'),
        iv: unhex('000102030405060708090a0b'),
      );
      expect(
        blob,
        'AAECAwQFBgcICQoLaT+cZgCmskkWrMrg8GpR4rszNjkGu1niFiXyvCqVWZoQz4jjz288'
        'uoBLBvOJrFJb/8x3tvy4gR/l5TgSVQjJOkQzS4gZIbeXcPD0mA==',
      );
    });

    test('blob tuzilishi: IV(12) ‖ ciphertext ‖ tag(16)', () async {
      final plain = utf8.encode('{"ir":[1.0],"rgb":null}');
      final blob = await KaftpayPalmCipher.encryptBytes(
        secret: kSecret,
        timestamp: kTs,
        nonce: kNonce,
        plaintext: plain,
        iv: List.filled(12, 7),
      );
      final raw = base64.decode(blob);
      expect(raw.length, 12 + plain.length + 16);
      expect(raw.sublist(0, 12), List.filled(12, 7));
    });

    test('decrypt — round trip', () async {
      final plain = utf8.encode('{"ir":[0.1,0.2],"rgb":null}');
      final blob = await KaftpayPalmCipher.encryptBytes(
          secret: kSecret, timestamp: kTs, nonce: kNonce, plaintext: plain);
      final back = await KaftpayPalmCipher.decryptBytes(
          secret: kSecret, timestamp: kTs, nonce: kNonce, palmDataEnc: blob);
      expect(back, plain);
    });

    test('boshqa nonce yoki timestamp bilan ochilmaydi (server 1106)',
        () async {
      final blob = await KaftpayPalmCipher.encryptBytes(
          secret: kSecret,
          timestamp: kTs,
          nonce: kNonce,
          plaintext: utf8.encode('{}'));
      await expectLater(
        KaftpayPalmCipher.decryptBytes(
            secret: kSecret, timestamp: kTs, nonce: 'boshqa', palmDataEnc: blob),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      await expectLater(
        KaftpayPalmCipher.decryptBytes(
            secret: kSecret,
            timestamp: '1893456001',
            nonce: kNonce,
            palmDataEnc: blob),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      await expectLater(
        KaftpayPalmCipher.decryptBytes(
            secret: 'boshqa', timestamp: kTs, nonce: kNonce, palmDataEnc: blob),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('tasodifiy IV — 12 bayt va har safar boshqa', () async {
      final a = KaftpayPalmCipher.randomIv();
      final b = KaftpayPalmCipher.randomIv();
      expect(a.length, 12);
      expect(a, isNot(b));
      final x = await KaftpayPalmCipher.encryptBytes(
          secret: kSecret,
          timestamp: kTs,
          nonce: kNonce,
          plaintext: utf8.encode('{}'));
      final y = await KaftpayPalmCipher.encryptBytes(
          secret: kSecret,
          timestamp: kTs,
          nonce: kNonce,
          plaintext: utf8.encode('{}'));
      expect(x, isNot(y));
    });

    test('IV uzunligi 12 dan farq qilsa xato', () {
      expect(
        () => KaftpayPalmCipher.encryptBytes(
            secret: kSecret,
            timestamp: kTs,
            nonce: kNonce,
            plaintext: const [1],
            iv: const [1, 2, 3]),
        throwsArgumentError,
      );
    });
  });
}
