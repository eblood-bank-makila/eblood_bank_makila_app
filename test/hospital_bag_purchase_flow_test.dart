/// The logged-in hospital "Commander en ligne" / "Adresses des banques"
/// wizard mirrors the welcome-QR (visitor) flow: bags come from the
/// whitelisted `blood-bags/search-simple` rows filtered to the selected
/// bank, the address-access fee is 10% of the bag price computed
/// on-device, and the mobile-money phone is normalised to +243… exactly
/// like the visitor payment page does.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/stock_management/business/service/HospitalBagPurchaseFlow.dart';

Map<String, dynamic> _row({
  required String bagId,
  required String bankId,
  required String type,
  required String rhesus,
  int price = 25,
  String currency = 'USD',
}) =>
    <String, dynamic>{
      'blood_bag_info': <String, dynamic>{
        '_id': bagId,
        'identifier': 'BAG-$bagId',
        'blood_type_info': <String, dynamic>{'blood_type_name': type},
        'blood_rhesus_info': <String, dynamic>{'blood_rheusus_name': rhesus},
        'blood_volume_info': <String, dynamic>{'blood_volume_name': '450'},
      },
      'blood_bank_info': <String, dynamic>{
        '_id': bankId,
        'blood_bank_name': 'Bank $bankId',
      },
      'blood_stock_count': 1,
      'price': price,
      'currency_code': currency,
      'currency_symbol': r'$',
      'status': 'available',
      'days_until_expiry': 12,
    };

void main() {
  group('HospitalBagPurchaseFlow.filterBankBags', () {
    test('keeps only rows of the selected bank AND the full blood type', () {
      final rows = <dynamic>[
        _row(bagId: 'a1', bankId: 'bank1', type: 'A', rhesus: '+'),
        _row(bagId: 'a2', bankId: 'bank2', type: 'A', rhesus: '+'), // other bank
        _row(bagId: 'a3', bankId: 'bank1', type: 'A', rhesus: '-'), // other rhesus
        _row(bagId: 'a4', bankId: 'bank1', type: 'O', rhesus: '+'), // other type
        _row(bagId: 'a5', bankId: 'bank1', type: 'A', rhesus: '+'),
      ];

      final bags = HospitalBagPurchaseFlow.filterBankBags(
        rows,
        bloodBankId: 'bank1',
        bloodType: 'A+',
      );

      expect(bags.map((b) => b.bloodBagInfo.id), ['a1', 'a5']);
    });

    test('tolerates junk rows and an `id`-keyed bank block', () {
      final bankIdKeyed = _row(bagId: 'b1', bankId: 'x', type: 'B', rhesus: '+');
      (bankIdKeyed['blood_bank_info'] as Map<String, dynamic>)
        ..remove('_id')
        ..['id'] = 'bank9';
      final rows = <dynamic>[
        null,
        'garbage',
        <String, dynamic>{'price': 3},
        bankIdKeyed,
      ];

      final bags = HospitalBagPurchaseFlow.filterBankBags(
        rows,
        bloodBankId: 'bank9',
        bloodType: 'B+',
      );

      expect(bags.length, 1);
      expect(bags.single.bloodBagInfo.id, 'b1');
      expect(bags.single.price, 25);
      expect(bags.single.currencyCode, 'USD');
    });

    test('unwraps both the {data:{data:[…]}} and {data:[…]} envelopes', () {
      final row = _row(bagId: 'c1', bankId: 'bank1', type: 'AB', rhesus: '-');
      expect(
        HospitalBagPurchaseFlow.rowsFromResponse({'data': {'data': [row], 'total': 1}}),
        [row],
      );
      expect(HospitalBagPurchaseFlow.rowsFromResponse({'data': [row]}), [row]);
      expect(HospitalBagPurchaseFlow.rowsFromResponse([row]), [row]);
      expect(HospitalBagPurchaseFlow.rowsFromResponse(null), isEmpty);
      expect(HospitalBagPurchaseFlow.totalFromResponse({'data': {'data': [row], 'total': 37}}), 37);
      expect(HospitalBagPurchaseFlow.totalFromResponse({'data': [row]}), isNull);
    });
  });

  group('HospitalBagPurchaseFlow.addressAccessFeeCents', () {
    test('is 10% of the bag price in cents, like the visitor payment page', () {
      // visitor page: (_bloodBagPrice * 0.10 * 100).round()
      expect(HospitalBagPurchaseFlow.addressAccessFeeCents(25), 250);
      expect(HospitalBagPurchaseFlow.addressAccessFeeCents(33), 330);
      expect(HospitalBagPurchaseFlow.addressAccessFeeCents(7), 70);
    });

    test('never goes below the backend minimum of 1 cent for a priced bag', () {
      // /payments/initiate/payment rejects amount_cents < 1 (ge=1).
      expect(HospitalBagPurchaseFlow.addressAccessFeeCents(0.05), 1);
      expect(HospitalBagPurchaseFlow.addressAccessFeeCents(0), 0);
    });
  });

  group('HospitalBagPurchaseFlow.normalizeMomoPhone', () {
    test('produces the +243-prefixed number the visitor flow sends', () {
      expect(HospitalBagPurchaseFlow.normalizeMomoPhone('243991234567'), '+243991234567');
      expect(HospitalBagPurchaseFlow.normalizeMomoPhone('+243991234567'), '+243991234567');
      expect(HospitalBagPurchaseFlow.normalizeMomoPhone('0991234567'), '+243991234567');
      expect(HospitalBagPurchaseFlow.normalizeMomoPhone('991 234 567'), '+243991234567');
    });

    test('returns null for an empty input', () {
      expect(HospitalBagPurchaseFlow.normalizeMomoPhone(''), isNull);
      expect(HospitalBagPurchaseFlow.normalizeMomoPhone('   '), isNull);
    });
  });
}
