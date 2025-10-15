import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

class WalletManagementPage extends ConsumerStatefulWidget {
  final int initialTabIndex;
  
  const WalletManagementPage({
    super.key, 
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<WalletManagementPage> createState() => _WalletManagementPageState();
}

class _WalletManagementPageState extends ConsumerState<WalletManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _autoReception = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // Load saved settings (in a real app, these would come from persistent storage)
    _emailController.text = 'notification@eblood.com';
    _phoneController.text = '+243 970123456';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab Navigation
            _buildTabNavigation(),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWalletTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion Financière',
                    style: GoogleFonts.ubuntu(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wallet & Paramètres',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.wallet,
                color: Colors.green,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(
              icon: Icon(Iconsax.wallet, size: 20),
              text: 'Wallet',
            ),
            Tab(
              icon: Icon(Iconsax.setting_2, size: 20),
              text: 'Paramètres',
            ),
          ],
        ),
      ),
    );
  }

  // WALLET TAB
  Widget _buildWalletTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Credit card style wallet
          _buildWalletCard(),
          const SizedBox(height: 24),
          
          // Withdraw action
          _buildWithdrawSection(),
          const SizedBox(height: 24),
          
          // Transaction history
          _buildTransactionHistory(),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'E-Blood Wallet',
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Icon(
                  Iconsax.card,
                  color: Colors.white,
                  size: 30,
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Solde Disponible',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1,250.00 USD',
              style: GoogleFonts.ubuntu(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Banque de Sang Makila',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  'Validé',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Effectuer un Retrait',
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant',
                prefixText: 'USD ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmer le Retrait'),
                      content: const Text('Voulez-vous confirmer ce retrait ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Retrait initié avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirmer'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retirer',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    // Sample transaction data
    final transactions = [
      {
        'title': 'Paiement reçu',
        'subtitle': 'De: Hôpital Central',
        'amount': '+320.00 USD',
        'date': 'Aujourd\'hui, 14:30',
        'icon': Iconsax.money_recive,
        'isPositive': true,
      },
      {
        'title': 'Retrait effectué',
        'subtitle': 'Vers: Compte bancaire',
        'amount': '-500.00 USD',
        'date': 'Hier, 10:15',
        'icon': Iconsax.money_send,
        'isPositive': false,
      },
      {
        'title': 'Paiement reçu',
        'subtitle': 'De: Clinique Saint-Joseph',
        'amount': '+180.00 USD',
        'date': '08 Oct, 16:45',
        'icon': Iconsax.money_recive,
        'isPositive': true,
      },
      {
        'title': 'Paiement reçu',
        'subtitle': 'De: Centre Médical Espoir',
        'amount': '+420.00 USD',
        'date': '05 Oct, 09:20',
        'icon': Iconsax.money_recive,
        'isPositive': true,
      },
      {
        'title': 'Retrait effectué',
        'subtitle': 'Vers: Mobile Money',
        'amount': '-300.00 USD',
        'date': '01 Oct, 11:30',
        'icon': Iconsax.money_send,
        'isPositive': false,
      },
    ];

    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique des Transactions',
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final isPositive = transaction['isPositive'] as bool;
                
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPositive 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      transaction['icon'] as IconData,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    transaction['title'] as String,
                    style: GoogleFonts.ubuntu(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    transaction['subtitle'] as String,
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                    ),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        transaction['amount'] as String,
                        style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w700,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        transaction['date'] as String,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // SETTINGS TAB
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification settings
          _buildEmailNotificationSection(),
          const SizedBox(height: 24),
          
          // Mobile payment settings
          _buildMobilePaymentSection(),
          const SizedBox(height: 24),
          
          // Auto reception settings
          _buildAutoReceptionSection(),
        ],
      ),
    );
  }

  Widget _buildEmailNotificationSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.notification, color: Colors.green),
                const SizedBox(width: 10),
                Text(
                  'Notifications Email',
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Email pour les notifications de transactions',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Adresse Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Save email settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paramètres email enregistrés'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Enregistrer',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePaymentSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.mobile, color: Colors.green),
                const SizedBox(width: 10),
                Text(
                  'Paiement Mobile',
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Numéro pour les paiements mobiles',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Numéro de Téléphone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Save phone settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Numéro de téléphone enregistré'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Enregistrer',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoReceptionSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.setting, color: Colors.green),
                const SizedBox(width: 10),
                Text(
                  'Mode de Réception',
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Configurer le mode de réception des paiements',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Réception Automatique',
                style: GoogleFonts.ubuntu(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Accepter automatiquement les paiements entrants',
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              value: _autoReception,
              onChanged: (value) {
                setState(() {
                  _autoReception = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value 
                          ? 'Réception automatique activée' 
                          : 'Réception sur demande activée'
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              activeColor: Colors.green,
            ),
            if (!_autoReception) ...[
              const SizedBox(height: 16),
              Text(
                'Vous recevrez une notification pour chaque paiement entrant et devrez approuver manuellement.',
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}