import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/blood_bank/controllers/donor_registration_controller.dart';

/// The blood-bank donor registration endpoint
/// (POST /api/v1/eblood-connect/blood-donors/register) validates the body with
/// BloodBankDonorRegistrationRequest, which declares `registration_origin`,
/// `emergency_contact_name` and `emergency_contact_phone` as REQUIRED.
/// Omitting any of them returns 422 "<Field>: Ce champ est obligatoire.".
void main() {
  DonorData buildDonor({
    String emergencyContactName = 'Rodri',
    String emergencyContactPhone = '0897500142',
    bool createAccount = false,
  }) {
    return DonorData(
      firstName: 'Jean',
      lastName: 'Kabila',
      phoneNumber: '0897500142',
      gender: 'M',
      bloodType: 'O+',
      dateOfBirth: '1990-01-01',
      email: 'jean@example.com',
      address: 'ngaliema',
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      createAccount: createAccount,
      username: createAccount ? 'jean@example.com' : null,
      password: createAccount ? 'Passw0rd!' : null,
    );
  }

  group('DonorData.toJson', () {
    test('sends registration_origin, which the API requires', () {
      final json = buildDonor().toJson();

      expect(json.containsKey('registration_origin'), isTrue);
      expect(json['registration_origin'], 'registration');
    });

    test('sends the emergency contact fields even when the user left them blank', () {
      final json = buildDonor(
        emergencyContactName: '',
        emergencyContactPhone: '',
      ).toJson();

      expect(json.containsKey('emergency_contact_name'), isTrue);
      expect(json.containsKey('emergency_contact_phone'), isTrue);
      expect(json['emergency_contact_name'], '');
      expect(json['emergency_contact_phone'], '');
    });

    test('still carries the fields the API needs when an account is created', () {
      final json = buildDonor(createAccount: true).toJson();

      expect(json['registration_origin'], 'registration');
      expect(json['create_account'], isTrue);
      expect(json['username'], 'jean@example.com');
    });
  });
}
