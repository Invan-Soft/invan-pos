// ONKM so'rovi — `OnkmValidator`.
//
// So'rov tanasi biznes uchun muhim: `kmIds`, `commitentTin`, `productCode`
// (MXIK) yoki `packageCode` noto'g'ri ketsa soliq xizmati rad javob beradi
// va kassir markirovkali tovarni sota olmaydi.
//
// Bu kod Faza 9.5 gacha `_markingCheck` ichida, `http.post` chaqiruvining
// o'rtasida edi — testlab bo'lmasdi.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/services/onkm_validator.dart';

ItemModel item({
  String? commissionTin = '123456789',
  String? mxik = '02202001001000000',
  String? packageCode = 'PACK-1',
}) {
  final m = ItemModel();
  m.id = 'suv-id';
  m.name = 'Suv';
  m.commissionTin = commissionTin;
  m.mxikCode = mxik;
  m.packageCode = packageCode;
  return m;
}

Map<String, dynamic> body({
  String ownerTin = '305123456',
  String km = 'KM-001',
  ItemModel? product,
}) =>
    OnkmValidator.buildBody(
        ownerTin: ownerTin, km: km, item: product ?? item());

Map<String, dynamic> firstProduct(Map<String, dynamic> b) =>
    (b['products'] as List).first as Map<String, dynamic>;

void main() {
  group('buildBody — so\'rov tanasi', () {
    test('do\'kon INN si ownerTin ga tushadi', () {
      expect(body(ownerTin: '305999888')['ownerTin'], '305999888');
    });

    test('refund har doim 0 (sotuv, qaytarish emas)', () {
      expect(body()['refund'], 0);
    });

    test('bitta mahsulot yuboriladi', () {
      expect(body()['products'], hasLength(1));
    });

    test('KM `kmIds` massivida ketadi', () {
      expect(firstProduct(body(km: 'KM-XYZ'))['kmIds'], ['KM-XYZ']);
    });

    test('komissiya INN si commitentTin ga tushadi', () {
      expect(firstProduct(body())['commitentTin'], '123456789');
    });

    test('MXIK productCode ga tushadi', () {
      expect(firstProduct(body())['productCode'], '02202001001000000');
    });

    test('paket kodi packageCode ga tushadi', () {
      expect(firstProduct(body())['packageCode'], 'PACK-1');
    });

    test('amount har doim 1 (har skan bitta dona)', () {
      expect(firstProduct(body())['amount'], 1);
    });

    test('bo\'sh maydonlar null bo\'lib ketadi (o\'zgartirilmaydi)', () {
      final b = body(
          product: item(commissionTin: null, mxik: null, packageCode: null));
      final p = firstProduct(b);
      expect(p['commitentTin'], isNull);
      expect(p['productCode'], isNull);
      expect(p['packageCode'], isNull);
    });

    test('JSON ga o\'giriladi (jsonEncode xato bermaydi)', () {
      expect(() => jsonEncode(body()), returnsNormally);
    });
  });

  group('toResult — javobni o\'girish', () {
    test('200 → isSuccess true va JSON tahlil qilinadi', () {
      final r = OnkmValidator.toResult(
          http.Response('{"success":true}', 200));
      expect(r.isSuccess, isTrue);
      expect(r.statusCode, 200);
      expect(r.result['success'], isTrue);
    });

    test('200 — UTF-8 (kirill) matn to\'g\'ri o\'qiladi', () {
      final r = OnkmValidator.toResult(http.Response.bytes(
          utf8.encode('{"messageRu":"Успешно"}'), 200));
      expect(r.result['messageRu'], 'Успешно');
    });

    test('500 → isSuccess false, statusCode 1 bo\'lib qoladi', () {
      final r = OnkmValidator.toResult(http.Response('server error', 500));
      expect(r.isSuccess, isFalse);
      expect(r.statusCode, 1,
          reason: 'chaqiruvchi 500 ni response.statusCode dan ko\'radi');
      expect(r.result, isNull);
    });

    test('401 → ham muvaffaqiyatsiz', () {
      expect(OnkmValidator.toResult(http.Response('', 401)).isSuccess, isFalse);
    });

    test('204 (bo\'sh javob) → muvaffaqiyatsiz', () {
      expect(OnkmValidator.toResult(http.Response('', 204)).isSuccess, isFalse);
    });
  });

  group('Doimiylar', () {
    test('endpoint tasnif.soliq.uz ONKM manzili', () {
      expect(OnkmValidator.endpoint,
          'https://tasnif.soliq.uz/api/cl-api/marking/validation-onkm');
    });

    test('so\'rov JSON sifatida yuboriladi', () {
      expect(OnkmValidator.headers['Content-Type'], 'application/json');
    });

    test('Basic avtorizatsiya sarlavhasi bor', () {
      expect(OnkmValidator.headers['Authorization'], startsWith('Basic '));
    });
  });
}
