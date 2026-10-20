import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

const _trackColor = Color(0xFFD0021B);
const _disabledColor = Color(0xFF9E9E9E);
const _trackHeight = 64.0;
const _knobSize = 56.0;
const _inset = (_trackHeight - _knobSize) / 2;

/// Share of the track the knob must pass, on release, to count as confirmed.
const _threshold = 0.9;

/// A slide-only control is hard to trigger by accident, which is the point for
/// a courier on a moto; screen readers get a plain tap action instead.
///
/// [onConfirmed] returns whether the step went through: `true` leaves the knob
/// at the end (until [label] changes, i.e. the next step), `false` or a throw
/// sends it back so the courier can retry.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.enabled = true,
  });

  final String label;
  final Future<bool> Function() onConfirmed;
  final bool enabled;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with SingleTickerProviderStateMixin {
  /// 0 = knob at the start of the track, 1 = at the end.
  late final _pos = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  bool _busy = false;
  bool _done = false;

  bool get _active => widget.enabled && !_busy && !_done;

  @override
  void didUpdateWidget(SlideToConfirm old) {
    super.didUpdateWidget(old);
    // The sheet moved on to the next step and reused this element.
    if (_done && old.label != widget.label) {
      _done = false;
      _pos.value = 0;
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_active) return;
    final label = widget.label;
    setState(() => _busy = true);
    _pos.animateTo(1, duration: const Duration(milliseconds: 100));
    var ok = false;
    try {
      ok = await widget.onConfirmed();
    } catch (e, s) {
      // A failed step must not leave the knob stuck; report it and let them retry.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: s,
          library: 'slide_to_confirm',
        ),
      );
    }
    if (!mounted) return;
    // A label change while running means the step already advanced.
    setState(() {
      _busy = false;
      _done = ok && widget.label == label;
    });
    if (!_done) _pos.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled ? _trackColor : _disabledColor;
    return Semantics(
      button: true,
      label: widget.label,
      enabled: widget.enabled,
      onTap: _active ? _confirm : null,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final travel = box.maxWidth - _knobSize - 2 * _inset;
          return Container(
            height: _trackHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(_trackHeight / 2),
            ),
            child: Stack(
              children: [
                // Offset by the knob so the label never starts under it.
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: _knobSize + 2 * _inset,
                      right: 16,
                    ),
                    child: Center(
                      child: Text(
                        widget.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _pos,
                  builder: (context, child) => Positioned(
                    left: _inset + _pos.value * travel,
                    top: _inset,
                    child: child!,
                  ),
                  child: GestureDetector(
                    // Count the touch slop so the knob stays under the finger.
                    dragStartBehavior: DragStartBehavior.down,
                    onHorizontalDragUpdate: _active
                        ? (d) => _pos.value += d.delta.dx / travel
                        : null,
                    onHorizontalDragEnd: _active
                        ? (_) => _pos.value >= _threshold
                              ? _confirm()
                              : _pos.animateTo(0)
                        : null,
                    onHorizontalDragCancel: _active
                        ? () => _pos.animateTo(0)
                        : null,
                    child: Container(
                      key: const Key('slide-knob'),
                      width: _knobSize,
                      height: _knobSize,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _busy
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: color,
                              ),
                            )
                          : Icon(
                              Icons.chevron_right_rounded,
                              size: 36,
                              color: color,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
