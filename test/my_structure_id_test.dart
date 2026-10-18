import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/blood_bank/business/models/structure_validation_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/data/services/structure_validation_service.dart';

/// A hospital's own structure id (delivery destination of an order, owner of
/// the deliveries it receives) must come from GET /health-structures/mine,
/// which the server resolves from the token. /eblood/hospitals/list has no
/// organization filter: `filter__sys_organization_id` was silently dropped,
/// so the lookup got the first structure of the whole list ("banque de sang
/// lobiko" for every hospital) or, parsed differently, nothing at all
/// ("Hôpital introuvable" on the order page).
void main() {
  group('structureIdOf', () {
    test('returns the id of the caller\'s structure', () {
      const mine = StructureValidationModel(id: '6acd31c0fcf168ff7d67c9e8', name: 'cs bolingo', status: 'validated');
      expect(StructureValidationService.structureIdOf(mine), '6acd31c0fcf168ff7d67c9e8');
    });

    test('no structure row or no answer means no id', () {
      expect(StructureValidationService.structureIdOf(StructureValidationModel.notLinked), isNull);
      expect(StructureValidationService.structureIdOf(null), isNull);
    });
  });

  test('no code looks up its own hospital through hospitals/list', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('filter__sys_organization_id'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty,
        reason: 'hospitals/list ignores filter__sys_organization_id and returns an arbitrary structure; '
            'use StructureValidationService.getMyStructureId()');
  });
}
