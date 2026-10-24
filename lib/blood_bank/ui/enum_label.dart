import 'package:get/get.dart';

/// The translated label of a backend enum value (« En attente de livraison »
/// for `rq_status` + `pending_delivery`), or the value made readable when no
/// key exists yet, never the raw snake_case.
String enumLabel(String prefix, String? value) {
  if (value == null || value.isEmpty) return '—';
  final key = '${prefix}_$value';
  final label = key.tr;
  if (label != key) return label;
  final words = value.replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}
