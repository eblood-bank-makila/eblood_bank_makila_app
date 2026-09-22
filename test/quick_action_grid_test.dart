import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/apps/home/widgets/quick_action_grid.dart';

/// The customer home "Actions rapides" cards overflowed on a real device
/// ("BOTTOM OVERFLOWED BY 2.6 PIXELS", and 23 px for the two-line
/// "Banques de sang à proximité" title). The tiles had a fixed aspect ratio,
/// so any extra content height — a wrapped title or a larger system font
/// scale — pushed the card past the tile.
void main() {
  Widget harness({
    required double width,
    required double textScale,
    required List<Widget> cards,
  }) {
    return MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [QuickActionGrid(cards: cards)],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> homeCards() => <Widget>[
        QuickActionCard(
          title: 'Devenir donneur',
          subtitle: 'Donneur de sang',
          icon: Icons.favorite_border,
          color: Colors.redAccent,
          onTap: () {},
        ),
        QuickActionCard(
          title: 'Top donneurs',
          subtitle: 'Donneurs',
          icon: Icons.star_border,
          color: Colors.orange,
          onTap: () {},
        ),
        QuickActionCard(
          title: 'Trouver du sang',
          subtitle: 'Recherche',
          icon: Icons.search,
          color: Colors.indigo,
          onTap: () {},
        ),
        // The long title wraps to two lines — the 23 px overflow in the report.
        QuickActionCard(
          title: 'Banques de sang à proximité',
          subtitle: 'Réseau médical',
          icon: Icons.local_hospital_outlined,
          color: Colors.green,
          onTap: () {},
        ),
      ];

  testWidgets('cards do not overflow at the default font scale', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(width: 360, textScale: 1.0, cards: homeCards()));

    expect(tester.takeException(), isNull);
  });

  testWidgets('cards do not overflow when the system font is enlarged', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(width: 360, textScale: 1.3, cards: homeCards()));

    expect(tester.takeException(), isNull);
  });

  testWidgets('cards do not overflow on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(720, 1440);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(width: 320, textScale: 1.2, cards: homeCards()));

    expect(tester.takeException(), isNull);
  });

  testWidgets('an odd number of cards keeps the two-column width', (tester) async {
    await tester.pumpWidget(harness(
      width: 360,
      textScale: 1.0,
      cards: homeCards().take(3).toList(),
    ));

    expect(tester.takeException(), isNull);

    final sizes = tester
        .widgetList<QuickActionCard>(find.byType(QuickActionCard))
        .map((card) => tester.getSize(find.byWidget(card)).width)
        .toSet();
    expect(sizes.length, 1, reason: 'every card should keep the same column width');
  });
}
