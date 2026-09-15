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
    // Spaces/dashes from a human-formatted number are stripped before the
    // digits-only regex runs (the backend strips them too).
    expect(validatePayoutForm(phone: '+243 99 885 7000', cap: '500', priority: '1'), isNull);
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

  testWidgets('a failed submit keeps the sheet open instead of popping', (tester) async {
    // The default 800x600 test surface is too short for the modal's content
    // (note box + 4 fields + buttons), which would hit-test-miss the "save"
    // button off the bottom edge — grow the surface so the tap actually lands.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Push the sheet as a real modal route (matching production's
    // showModalBottomSheet(isScrollControlled: true) call) so a stray
    // Navigator.pop from a bug would have something to pop and the test
    // would actually catch it disappearing.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => PayoutNumberSheet(
                    onSubmit: (_) async => false,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(PayoutNumberSheet), findsOneWidget);

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '+243998857000'); // phone
    await tester.enterText(textFields.at(2), '500'); // daily cap
    await tester.enterText(textFields.at(3), '1'); // priority

    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();

    // onSubmit resolved to false, so `_save` never calls Navigator.pop —
    // the sheet (still showing the inline error) is exactly one widget.
    expect(find.byType(PayoutNumberSheet), findsOneWidget);
  });
}
