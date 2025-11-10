import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utilisateurs/business/interactors/UtilisateurInteractor.dart';
import 'BottomNavBarWidget.dart';
import '../../blood_bank/ui/widgets/BloodBankBottomNavWidget.dart';
import 'CustomerBottomNavWidget.dart';
import 'package:get_storage/get_storage.dart';

enum AccountType {
  hospital,
  bloodBank,
  deliveryPerson,
  customer,
  bloodDonor,
  unknown,
}

class AccountTypeBasedNavigation extends ConsumerStatefulWidget {
  const AccountTypeBasedNavigation({super.key});

  @override
  ConsumerState<AccountTypeBasedNavigation> createState() => _AccountTypeBasedNavigationState();
}

class _AccountTypeBasedNavigationState extends ConsumerState<AccountTypeBasedNavigation> {
  AccountType? _accountType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineAccountType();
  }

  Future<void> _determineAccountType() async {
    try {
      // 1) Strongest signal: use stored user_profiles flags (all profiles)
      // The 'enabled' field will be used later to disable actions, not to hide profiles
      final storage = GetStorage();
      final dynamic storedProfiles = storage.read('user_profiles') ?? storage.read('user_profils');
      if (storedProfiles is List && storedProfiles.isNotEmpty) {
        final allProfiles = storedProfiles
            .whereType<Map>()
            .toList();
        final flags = allProfiles
            .map((e) => (e['profil'] ?? e['flag'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toSet();

        AccountType? fromProfiles;
        if (flags.contains('mobile_app_blood_bank_profil')) {
          fromProfiles = AccountType.bloodBank;
        } else if (flags.contains('mobile_app_health_structure_profil')) {
          fromProfiles = AccountType.hospital;
        } else if (flags.contains('mobile_app_simple_user_profil') ||
            flags.contains('mobile_app_blood_donor_profil') ||
            flags.contains('mobile_app_delivery_person_profil')) {
          fromProfiles = AccountType.customer;
        }

        if (fromProfiles != null) {
          setState(() {
            _accountType = fromProfiles;
            _isLoading = false;
          });
          debugPrint('🧭 AccountType from profiles flags: ${_accountType!.name}');
          return; // Done
        }
      }

      // 2) Next: try local persisted user model's uAccountType
      final userInteractor = ref.read(utilisateurInteractorProvider);
      final userData = await userInteractor.getUserLocalCodeUseCase.run();
      if (userData != null && userData.uAccountType.isNotEmpty) {
        final accountType = _parseAccountType(userData.uAccountType);
        setState(() {
          _accountType = accountType;
          _isLoading = false;
        });
        debugPrint('🏥 Account Type Determined from uAccountType: ${accountType.name}');
        return;
      }

      // 3) Fallback: use value persisted by AuthApi from profile derivation
      final stored = (storage.read('account_type') as String?) ?? '';
      final accountType = _parseAccountType(stored.isNotEmpty ? stored : null);
      setState(() {
        _accountType = accountType;
        _isLoading = false;
      });
      debugPrint('ℹ️ Using stored account_type fallback: ${accountType.name}');
    } catch (e) {
      debugPrint('❌ Error determining account type: $e');
      setState(() {
        _accountType = AccountType.unknown;
        _isLoading = false;
      });
    }
  }

  AccountType _parseAccountType(String? accountTypeString) {
    if (accountTypeString == null || accountTypeString.isEmpty) {
      return AccountType.customer; // Default to customer (consumer)
    }

    final lowerType = accountTypeString.toLowerCase().trim();

    // Map different possible account type values
    switch (lowerType) {
      case 'hospital':
      case 'hopital':
      case 'hôpital':
        return AccountType.hospital;
      case 'blood_bank':
      case 'bloodbank':
      case 'banque_sang':
      case 'banque_de_sang':
        return AccountType.bloodBank;
      case 'customer':
      case 'consommateur':
      case 'consumer':
        return AccountType.customer;
      case 'delivery':
      case 'delivery_person':
      case 'livreur':
      case 'deliverer':
        return AccountType.deliveryPerson;
      case 'blood_donor':
      case 'blood donor':
      case 'blooddonor':
      case 'donneur':
      case 'donneur_sang':
      case 'donneur de sang':
        return AccountType.bloodDonor;
      default:
        debugPrint('🤔 Unknown account type: $accountTypeString, defaulting to customer');
        return AccountType.customer;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chargement...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Route to appropriate navigation based on account type
    // Note: customer, bloodDonor, and deliveryPerson all use CustomerBottomNavWidget
    // with conditional UI features based on user profiles
    switch (_accountType!) {
      case AccountType.hospital:
        return const HospitalBottomNavBarWidget(); // Hospital-specific navigation
      case AccountType.bloodBank:
        return const BloodBankBottomNavWidget(); // Blood bank-specific navigation
      case AccountType.customer:
      case AccountType.bloodDonor:
      case AccountType.deliveryPerson:
        // ✅ All consumer types use CustomerBottomNavWidget
        // Features are conditionally shown based on user profiles
        return const CustomerBottomNavWidget();
      case AccountType.unknown:
        return const CustomerBottomNavWidget(); // Fallback to customer navigation
    }
  }
}

// Extension to get display names for account types
extension AccountTypeExtension on AccountType {
  String get displayName {
    switch (this) {
      case AccountType.hospital:
        return 'Hôpital';
      case AccountType.bloodBank:
        return 'Banque de Sang';
      case AccountType.deliveryPerson:
        return 'Livreur';
      case AccountType.customer:
        return 'Client';
      case AccountType.bloodDonor:
        return 'Donneur de Sang';
      case AccountType.unknown:
        return 'Visiteur';
    }
  }

  String get description {
    switch (this) {
      case AccountType.hospital:
        return 'Accès aux demandes de sang et gestion des commandes';
      case AccountType.bloodBank:
        return 'Gestion des stocks et traitement des demandes';
      case AccountType.deliveryPerson:
        return 'Livraison et suivi des commandes';
      case AccountType.customer:
        return 'Espace client: commandes et demandes de sang';
      case AccountType.bloodDonor:
        return 'Profil de donneur de sang avec historique de dons';
      case AccountType.unknown:
        return 'Type de compte non défini';
    }
  }
}
