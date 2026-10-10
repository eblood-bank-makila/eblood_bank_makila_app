import 'package:flutter_test/flutter_test.dart';
import 'package:eblood_bank_mak_app/apps/config/api/ApiConfig.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/structure_validation_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/data/services/structure_validation_service.dart';

void main() {
  test('path', () {
    expect(ApiConfig.myStructure, '/eblood/health-structures/mine');
  });

  test('fromBackendJson unwraps the envelope and maps statuses', () {
    final row = {'id': 's1', 'name': 'bb lobiko', 'main_validation_status': 'rejected', 'main_validation_note': 'adresse', 'main_validated_at': '2026-09-15T10:00:00+00:00'};
    final m = StructureValidationModel.fromBackendJson({'data': row})!;
    expect(m.id, 's1');
    expect(m.isRejected, isTrue);
    expect(m.blocksActions, isTrue);
    expect(m.note, 'adresse');
    expect(m.validatedAt, DateTime.parse('2026-09-15T10:00:00+00:00'));
    expect(StructureValidationModel.fromBackendJson(row)!.isRejected, isTrue);
    expect(StructureValidationModel.fromBackendJson({'data': {'name': 'x'}}), isNull);
    expect(StructureValidationModel.fromBackendJson(null), isNull);
    final p = StructureValidationModel.fromBackendJson({'id': 's2', 'name': 'y'})!;
    expect(p.isPending, isTrue); // missing status → pending, like the server default
    final v = StructureValidationModel.fromBackendJson({'id': 's3', 'name': 'z', 'main_validation_status': 'validated'})!;
    expect(v.isValidated, isTrue);
    expect(v.blocksActions, isFalse);
  });

  test('fromApiResponse: 404 = no structure linked, success = parsed, other failures = unknown (null)', () {
    final notLinked = StructureValidationService.fromApiResponse(
        IApiResponse(success: false, message: 'Resource not found', statusCode: 404));
    expect(notLinked, isNotNull);
    expect(notLinked!.isNotLinked, isTrue);
    expect(notLinked.blocksActions, isTrue);
    expect(StructureValidationService.fromApiResponse(IApiResponse(success: false, statusCode: 403)), isNull);
    expect(StructureValidationService.fromApiResponse(IApiResponse(success: false, statusCode: 500)), isNull);
    final ok = StructureValidationService.fromApiResponse(
        IApiResponse(success: true, data: {'id': 's1', 'name': 'x', 'main_validation_status': 'validated'}));
    expect(ok!.isValidated, isTrue);
  });
}
