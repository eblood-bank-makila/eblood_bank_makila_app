import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/structure_validation_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/data/services/structure_validation_service.dart';

final structureValidationServiceProvider =
    Provider<StructureValidationService>((ref) => StructureValidationService());

/// Lazy: only requested once something watches it (the RBAC shell banner for
/// blood-bank / CNTS / hospital accounts, the gated pages). Re-read on every
/// home refresh via `ref.invalidate(myStructureProvider)`.
final myStructureProvider = FutureProvider<StructureValidationModel?>(
  (ref) => ref.watch(structureValidationServiceProvider).getMyStructure(),
);
