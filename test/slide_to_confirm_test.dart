import 'dart:async';
import 'dart:ui' show Tristate;

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

  group('after a confirmed step', () {
    testWidgets('the knob stays at the end and cannot confirm again', (
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

      await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
      await t.pumpAndSettle();
      final atEnd = t.getTopLeft(_knob);
      expect(atEnd.dx, start.dx + _travel(t));
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await t.drag(_knob, Offset(-_travel(t), 0));
      await t.drag(_knob, Offset(_travel(t), 0));
      await t.pumpAndSettle();

      expect(calls, 1);
      expect(t.getTopLeft(_knob), atEnd);
    });

    testWidgets('a new label (next step) resets the knob and confirms again', (
      t,
    ) async {
      var calls = 0;
      Future<bool> confirm() async {
        calls++;
        return true;
      }

      await t.pumpWidget(_host(onConfirmed: confirm));
      final start = t.getTopLeft(_knob);
      await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
      await t.pumpAndSettle();
      expect(calls, 1);

      await t.pumpWidget(
        _host(onConfirmed: confirm, label: 'Glisser · Livré au patient'),
      );
      await t.pumpAndSettle();
      expect(t.getTopLeft(_knob), start);
      expect(find.text('Glisser · Livré au patient'), findsOneWidget);

      await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
      await t.pumpAndSettle();
      expect(calls, 2);
    });

    testWidgets('a label change while running resets instead of locking', (
      t,
    ) async {
      var calls = 0;
      final first = Completer<bool>();
      Future<bool> confirm() {
        calls++;
        return calls == 1 ? first.future : Future.value(true);
      }

      await t.pumpWidget(_host(onConfirmed: confirm));
      final start = t.getTopLeft(_knob);
      await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
      await t.pump();
      expect(calls, 1);

      // onConfirmed advanced the step: the parent rebuilds with the next label
      // before the future resolves.
      await t.pumpWidget(
        _host(onConfirmed: confirm, label: 'Glisser · Livré au patient'),
      );
      first.complete(true);
      await t.pumpAndSettle();

      expect(t.getTopLeft(_knob), start);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
      await t.pumpAndSettle();
      expect(calls, 2);
    });
  });

  testWidgets('disabled mid-drag sends the knob back to its start', (t) async {
    var calls = 0;
    Future<bool> confirm() async {
      calls++;
      return true;
    }

    await t.pumpWidget(_host(onConfirmed: confirm));
    final start = t.getTopLeft(_knob);

    final finger = await t.startGesture(t.getCenter(_knob));
    await finger.moveBy(Offset(_travel(t) * 0.5, 0));
    await t.pump();
    expect(t.getTopLeft(_knob).dx, greaterThan(start.dx));

    await t.pumpWidget(_host(onConfirmed: confirm, enabled: false));
    await t.pumpAndSettle();
    expect(t.getTopLeft(_knob), start);

    await finger.up();
    await t.pumpAndSettle();
    expect(t.getTopLeft(_knob), start);
    expect(calls, 0);
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
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      t.semantics.tap(find.semantics.byLabel(_label));
      await t.pumpAndSettle();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets('while running it is not enabled, has no tap, and a hint', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      final done = Completer<bool>();
      await t.pumpWidget(_host(onConfirmed: () => done.future));
      expect(t.getSemantics(find.byType(SlideToConfirm)).hint, isEmpty);

      await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
      await t.pump();

      final node = t.getSemantics(find.byType(SlideToConfirm));
      expect(node.label, _label);
      expect(node.hint, 'En cours…');
      expect(node.flagsCollection.isEnabled, isNot(Tristate.isTrue));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);

      done.complete(true);
      await t.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('once done it is not enabled and has no tap action', (t) async {
      final handle = t.ensureSemantics();
      await t.pumpWidget(_host(onConfirmed: () async => true));
      await t.drag(_knob, Offset(_travel(t) * 0.95, 0));
      await t.pumpAndSettle();

      final node = t.getSemantics(find.byType(SlideToConfirm));
      expect(node.hint, isEmpty);
      expect(node.flagsCollection.isEnabled, isNot(Tristate.isTrue));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
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
