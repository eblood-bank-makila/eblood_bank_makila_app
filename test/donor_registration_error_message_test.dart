import 'package:flutter_test/flutter_test.dart';
import 'package:eblood_bank_mak_app/blood_bank/controllers/donor_registration_controller.dart';

/// A refused registration used to reach the screen as
/// "Erreur lors de l'inscription: Failed to register donor: Exception: <msg>".
/// The backend message (e.g. the 409 structure gate) must be shown once, as is.
void main() {
  const gate = 'Votre structure est en attente de validation par eBlood. Cette action sera disponible une fois la validation effectuée.';

  test('a backend message is surfaced once, without the wrapper chain', () {
    expect(DonorRegistrationController.userFacingError(Exception(gate)), gate);
    expect(DonorRegistrationController.userFacingError(Exception('Failed to register donor: Exception: $gate')), gate);
  });

  test('non-Exception errors get the generic French fallback', () {
    expect(DonorRegistrationController.userFacingError(StateError('x')),
        'Une erreur inattendue est survenue. Veuillez réessayer.');
  });
}
