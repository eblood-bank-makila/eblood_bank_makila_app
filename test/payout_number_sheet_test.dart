import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eblood_bank_mak_app/blood_bank/ui/widgets/payout_number_sheet.dart';

void main() {
  setUpAll(() {
    // No network in tests: fall back to the bundled default font instead of
    // trying to fetch Ubuntu from Google Fonts.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('validatePayoutForm', () {
    expect(validatePayoutForm(phone: '+243998857000', cap: '500', priority: '1'), isNull);
    expect(validatePayoutForm(phone: '12', cap: '500', priority: '1'), 'enter_valid_phone');
    expect(validatePayoutForm(phone: '+243998857000', cap: '0', priority: '1'), 'enter_valid_daily_cap');
    expect(validatePayoutForm(phone: '+243998857000', cap: '5', priority: '0'), 'enter_valid_priority');
  });

  testWidgets('save with an empty phone shows the enter_valid_phone key and does not submit', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PayoutNumberSheet(
            onSubmit: (_) async {
              submitted = true;
              return true;
            },
          ),
        ),
      ),
    );

    // GetX `.tr` returns the raw key when no translations delegate is
    // installed, so the button and the error render as their keys.
    await tester.tap(find.text('save'));
    await tester.pump();

    expect(find.text('enter_valid_phone'), findsOneWidget);
    expect(submitted, isFalse);
  });
}
