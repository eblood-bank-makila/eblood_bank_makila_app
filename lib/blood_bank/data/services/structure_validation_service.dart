import 'package:flutter/foundation.dart';
import 'package:eblood_bank_mak_app/apps/config/api/ApiConfig.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/structure_validation_model.dart';

/// Reads the logged-in org's structure validation.
///   * 200 → the parsed model (pending / validated / rejected)
///   * 404 → `StructureValidationModel.notLinked` (the org has NO structure row —
///           the backend refuses every write with STRUCTURE_NOT_LINKED)
///   * anything else (403 = seed not applied, network…) → null: unknown, so the
///     UI renders exactly as before and the server stays the only gate.
class StructureValidationService {
  Future<StructureValidationModel?> getMyStructure() async {
    try {
      final res = await getWithDio(ApiConfig.myStructure);
      return fromApiResponse(res);
    } catch (e) {
      debugPrint('StructureValidationService.getMyStructure: $e');
      return null;
    }
  }

  /// Id of the logged-in org's own structure (an order's delivery destination,
  /// the hospital a delivery is received by), or null when unknown. The
  /// server resolves it from the token; /eblood/hospitals/list cannot — it has
  /// no organization filter and returns an arbitrary structure.
  Future<String?> getMyStructureId() async => structureIdOf(await getMyStructure());

  static String? structureIdOf(StructureValidationModel? structure) {
    if (structure == null || structure.isNotLinked || structure.id.isEmpty) return null;
    return structure.id;
  }

  @visibleForTesting
  static StructureValidationModel? fromApiResponse(IApiResponse res) {
    if (res.success) return StructureValidationModel.fromBackendJson(res.data);
    if (res.statusCode == 404) return StructureValidationModel.notLinked;
    return null;
  }
}
