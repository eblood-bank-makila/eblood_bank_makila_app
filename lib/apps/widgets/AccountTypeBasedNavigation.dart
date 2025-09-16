import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utilisateurs/business/interactors/UtilisateurInteractor.dart';
import 'BottomNavBarWidget.dart';
import '../../blood_bank/ui/widgets/BloodBankBottomNavWidget.dart';
import 'DeliveryPersonBottomNavWidget.dart';

enum AccountType {
  hospital,
  bloodBank,
  deliveryPerson,
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
      final userInteractor = ref.read(utilisateurInteractorProvider);
      final userData = await userInteractor.getUserLocalCodeUseCase.run();
      
      if (userData != null) {
        final accountType = _parseAccountType(userData.uAccountType);
        setState(() {
          _accountType = accountType;
          _isLoading = false;
        });
        
        debugPrint('🏥 Account Type Determined: ${accountType.name}');
      } else {
        setState(() {
          _accountType = AccountType.unknown;
          _isLoading = false;
        });
        debugPrint('❌ No user data found');
      }
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
      return AccountType.hospital; // Default to hospital
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
      case 'delivery':
      case 'delivery_person':
      case 'livreur':
      case 'deliverer':
        return AccountType.deliveryPerson;
      default:
        debugPrint('🤔 Unknown account type: $accountTypeString, defaulting to hospital');
        return AccountType.hospital;
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
    switch (_accountType!) {
      case AccountType.hospital:
        return const BottomNavBarWidget(); // Current hospital navigation
      case AccountType.bloodBank:
        return const BloodBankBottomNavWidget();
      case AccountType.deliveryPerson:
        return const DeliveryPersonBottomNavWidget();
      case AccountType.unknown:
        return const BottomNavBarWidget(); // Fallback to hospital navigation
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
      case AccountType.unknown:
        return 'Inconnu';
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
      case AccountType.unknown:
        return 'Type de compte non défini';
    }
  }
}
