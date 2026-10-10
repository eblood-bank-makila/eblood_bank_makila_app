/// eBlood (MAIN) validation of the logged-in org's structure — mirrors the backend
/// `GET /eblood/health-structures/mine` payload (spec 2026-09-15 §7, addendum
/// 2026-10-10). Missing / unknown status reads as pending, like the server default.
/// `not_linked` is the client-side name for the 404 case: the org has no
/// structure row at all, and the backend refuses every write with
/// STRUCTURE_NOT_LINKED.
class StructureValidationModel {
  final String id;
  final String name;
  /// pending | validated | rejected | not_linked
  final String status;
  final String? note;
  final DateTime? validatedAt;

  const StructureValidationModel({
    required this.id,
    required this.name,
    required this.status,
    this.note,
    this.validatedAt,
  });

  static const notLinked = StructureValidationModel(id: '', name: '', status: 'not_linked');

  bool get isValidated => status == 'validated';
  bool get isRejected => status == 'rejected';
  bool get isNotLinked => status == 'not_linked';
  bool get isPending => !isValidated && !isRejected && !isNotLinked;

  /// True whenever the backend write gate would answer 409.
  bool get blocksActions => !isValidated;

  static StructureValidationModel? fromBackendJson(dynamic json) {
    if (json is! Map) return null;
    var m = Map<String, dynamic>.from(json);
    if (m['data'] is Map) m = Map<String, dynamic>.from(m['data'] as Map);
    final id = m['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final raw = m['main_validation_status']?.toString();
    final at = m['main_validated_at']?.toString();
    return StructureValidationModel(
      id: id,
      name: m['name']?.toString() ?? '',
      status: (raw == 'validated' || raw == 'rejected') ? raw! : 'pending',
      note: m['main_validation_note']?.toString(),
      validatedAt: at == null || at.isEmpty ? null : DateTime.tryParse(at),
    );
  }
}
