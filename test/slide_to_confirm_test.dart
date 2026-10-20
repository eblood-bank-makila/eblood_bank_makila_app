import 'dart:async';

import 'package:eblood_bank_mak_app/delivery/ui/widgets/slide_to_confirm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

const _label = 'Glisser · Arrivé à la banque';
final _knob = find.byKey(const Key('slide-knob'));

Widget _host({
  required Future<bool> Function() onConfirmed,
  bool enabled = true,
  String label = _label,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 320,
        child: SlideToConfirm(
          label: label,
          onConfirmed: onConfirmed,
          enabled: enabled,
        ),
      ),
    ),
  ),
);

/// Horizontal distance the knob can travel (track width minus knob and insets).
double _travel(WidgetTester t) =>
    t.getSize(find.byType(SlideToConfirm)).width - t.getSize(_knob).width - 8;

void main() {
  testWidgets('a half-way drag does not confirm and the knob springs back', (
    t,
  ) async {
    var calls = 0;
    await t.pumpWidget(
      _host(
        onConfirmed: () async {
          calls++;
          return true;
        },
      ),
    );
    final start = t.getTopLeft(_knob);

    await t.drag(_knob, Offset(_travel(t) * 0.5, 0));
    await t.pumpAndSettle();

    expect(calls, 0);
    expect(t.getTopLeft(_knob), start);
  });

  testWidgets('just under 90 % does not confirm', (t) async {
    var calls = 0;
    await t.pumpWidget(
      _host(
        onConfirmed: () async {
          calls++;
          return true;
        },
      ),
    );

    await t.drag(_knob, Offset(_travel(t) * 0.85, 0));
    await t.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('a 95 % drag confirms exactly once, spinner while running', (
    t,
  ) async {
    var calls = 0;
    final done = Completer<bool>();
    await t.pumpWidget(
      _host(
        onConfirmed: () {
          calls++;
          return done.future;
        },
      ),
    );
    final start = t.getTopLeft(_knob);

    await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
    await t.pump();
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Dragging the knob again (back and forth) while it runs must not re-fire
    // nor move it.
    final atEnd = t.getTopLeft(_knob);
    await t.drag(_knob, Offset(-_travel(t), 0));
    await t.drag(_knob, Offset(_travel(t), 0));
    await t.pump();
    expect(calls, 1);
    expect(t.getTopLeft(_knob), atEnd);
    expect(atEnd.dx, greaterThan(start.dx));

    done.complete(true);
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(calls, 1);
  });

  testWidgets('onConfirmed false sends the knob back to its start', (t) async {
    final done = Completer<bool>();
    await t.pumpWidget(_host(onConfirmed: () => done.future));
    final start = t.getTopLeft(_knob);

    await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
    await t.pump();
    expect(t.getTopLeft(_knob).dx, greaterThan(start.dx));

    done.complete(false);
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(t.getTopLeft(_knob), start);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('after a failure the control can be slid again', (t) async {
    var calls = 0;
    await t.pumpWidget(_host(onConfirmed: () async => ++calls > 1));

    await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
    await t.pumpAndSettle();
    await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
    await t.pumpAndSettle();

    expect(calls, 2);
  });

  testWidgets('a throwing onConfirmed also resets the knob', (t) async {
    await t.pumpWidget(_host(onConfirmed: () async => throw StateError('x')));
    final start = t.getTopLeft(_knob);

    await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
    await t.pumpAndSettle();

    expect(t.takeException(), isStateError);
    expect(t.getTopLeft(_knob), start);
  });

  testWidgets('disabled: a drag does nothing', (t) async {
    var calls = 0;
    await t.pumpWidget(
      _host(
        enabled: false,
        onConfirmed: () async {
          calls++;
          return true;
        },
      ),
    );
    final start = t.getTopLeft(_knob);

    await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
    await t.pumpAndSettle();

    expect(calls, 0);
    expect(t.getTopLeft(_knob), start);
  });

  testWidgets('the label is not hidden under the knob at rest', (t) async {
    await t.pumpWidget(_host(onConfirmed: () async => true));

    final label = t.getRect(find.text(_label));
    final knob = t.getRect(_knob);
    expect(label.left, greaterThanOrEqualTo(knob.right));
  });

  group('accessibility', () {
    testWidgets('screen readers get a button they can double-tap to confirm', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      var calls = 0;
      await t.pumpWidget(
        _host(
          onConfirmed: () async {
            calls++;
            return true;
          },
        ),
      );

      final node = t.getSemantics(find.byType(SlideToConfirm));
      expect(node.label, _label);
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      t.semantics.tap(find.semantics.byLabel(_label));
      await t.pumpAndSettle();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('disabled exposes no tap action', (t) async {
      final handle = t.ensureSemantics();
      await t.pumpWidget(_host(enabled: false, onConfirmed: () async => true));

      final node = t.getSemantics(find.byType(SlideToConfirm));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });
  });
}
