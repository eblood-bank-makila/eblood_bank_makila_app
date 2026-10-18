import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/HospitalBagPurchaseFlow.dart';

/// "Commander en ligne", bank step: each bank card showed a hard-coded
/// "$10 par poche" while the bags cost $1, and "Distance de vous" without the
/// distance. The price must come from the bags the backend returns, and the
/// distance string must keep its @distance placeholder.
Map<String, dynamic> _row(String bankId, String type, String rhesus, num price, {String symbol = r'$'}) => {
      'blood_bag_info': {
        '_id': 'bag-$bankId-$price',
        'blood_type_info': {'blood_type_name': type},
        'blood_rhesus_info': {'blood_rheusus_name': rhesus},
      },
      'blood_bank_info': {'_id': bankId},
      'blood_stock_count': 1,
      'price': price,
      'currency_symbol': symbol,
    };

void main() {
  group('bankPricesFromRows', () {
    test('per bank: lowest and highest price of the requested blood type', () {
      final prices = HospitalBagPurchaseFlow.bankPricesFromRows([
        _row('dannico', 'AB', '-', 1),
        _row('dannico', 'AB', '-', 3),
        _row('dannico', 'O', '+', 50), // other type: ignored
        _row('lobiko', 'AB', '-', 2, symbol: 'FC'),
        {'price': 9}, // no bank: ignored
        'junk',
      ], bloodType: 'AB-');

      expect(prices.keys, unorderedEquals(['dannico', 'lobiko']));
      expect(prices['dannico']!.min, 1);
      expect(prices['dannico']!.max, 3);
      expect(prices['lobiko']!.currencySymbol, 'FC');
    });
  });

  group('BankBagPrice.label', () {
    test('one price', () {
      expect(const BankBagPrice(min: 1, max: 1, currencySymbol: r'$').label, r'$1');
    });
    test('a range', () {
      expect(const BankBagPrice(min: 1, max: 3, currencySymbol: r'$').label, r'$1 – $3');
    });
    test('cents are kept', () {
      expect(const BankBagPrice(min: 1.5, max: 1.5, currencySymbol: r'$').label, r'$1.50');
    });
  });

  group('distance strings', () {
    final locales = AppTranslations().keys;
    final source = File('lib/apps/translations/AppTranslations.dart').readAsStringSync();

    test('the bank card string carries @distance in every locale', () {
      for (final entry in locales.entries) {
        expect(entry.value['distance_away_from_you'], contains('@distance'), reason: entry.key);
      }
    });

    test('the plain label used by the payment page has no placeholder', () {
      for (final entry in locales.entries) {
        final label = entry.value['distance_from_you'];
        expect(label, isNotNull, reason: entry.key);
        expect(label, isNot(contains('@distance')), reason: entry.key);
      }
    });

    test('each key is defined once per locale (a later duplicate silently wins)', () {
      for (final key in ['distance_from_you', 'distance_away_from_you', 'price_per_bag']) {
        final count = RegExp("^      '$key':", multiLine: true).allMatches(source).length;
        expect(count, locales.length, reason: key);
      }
    });
  });
}
