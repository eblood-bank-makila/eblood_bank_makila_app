import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../apps/services/LocationService.dart';

/// Country dial-code picker for mobile-money numbers: the platform's covered
/// countries (public registration-system-countries endpoint), « +243 » first
/// and selected by default.
class DialCodeDropdown extends StatefulWidget {
  const DialCodeDropdown({super.key, required this.value, required this.onChanged, this.style});

  static const String defaultCode = '+243';

  final String value;
  final ValueChanged<String> onChanged;
  final TextStyle? style;

  static List<String>? _cache;

  /// Dial codes as "+NNN", DRC first; falls back to DRC alone when the
  /// countries cannot be loaded (offline, visitor without a token…).
  static Future<List<String>> codes() async {
    if (_cache != null) return _cache!;
    final found = <String>{defaultCode};
    try {
      final response = await LocationService().fetchLocationData();
      for (final country in response.data) {
        for (final code in country.countryCodes ?? const []) {
          final digits = code.countryCode.replaceAll(RegExp(r'[^\d]'), '');
          if (digits.isNotEmpty) found.add('+$digits');
        }
      }
    } catch (e) {
      debugPrint('⚠️ DialCodeDropdown: countries unavailable, DRC only ($e)');
    }
    _cache = found.toList();
    return _cache!;
  }

  @override
  State<DialCodeDropdown> createState() => _DialCodeDropdownState();
}

class _DialCodeDropdownState extends State<DialCodeDropdown> {
  List<String> _codes = const [DialCodeDropdown.defaultCode];

  @override
  void initState() {
    super.initState();
    DialCodeDropdown.codes().then((codes) {
      if (mounted) setState(() => _codes = codes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700);
    final items = _codes.contains(widget.value) ? _codes : [widget.value, ..._codes];
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: widget.value,
        isDense: true,
        style: style,
        items: [for (final c in items) DropdownMenuItem(value: c, child: Text(c, style: style))],
        onChanged: (v) {
          if (v != null) widget.onChanged(v);
        },
      ),
    );
  }
}
