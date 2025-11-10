import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme/ColorPages.dart';
import 'AdvertisementModel.dart';
import 'AdvertisementService.dart';
import 'AdvertisementFormPage.dart';
import 'AdvertisementAnalyticsDashboard.dart';

/// Advertisement Admin Panel
/// For managing advertisements (CRUD operations)
class AdvertisementAdminPage extends StatefulWidget {
  const AdvertisementAdminPage({super.key});

  @override
  State<AdvertisementAdminPage> createState() => _AdvertisementAdminPageState();
}

class _AdvertisementAdminPageState extends State<AdvertisementAdminPage> {
  List<AdvertisementModel> _advertisements = [];
  bool _loading = true;
  String _filter = 'all'; // all, active, draft, expired

  @override
  void initState() {
    super.initState();
    _loadAdvertisements();
  }

  Future<void> _loadAdvertisements() async {
    setState(() => _loading = true);
    
    // TODO: Load from API
    await Future.delayed(const Duration(seconds: 1));
    _advertisements = AdvertisementService.getMockAdvertisements();
    
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gestion des Publicités',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.chart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvertisementAnalyticsDashboard(),
                ),
              );
            },
            tooltip: 'Tableau de Bord Analytique',
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.white),
            onPressed: _loadAdvertisements,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildAdvertisementList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text(
          'Nouvelle Pub',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tous', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Actifs', 'active'),
            const SizedBox(width: 8),
            _buildFilterChip('Brouillons', 'draft'),
            const SizedBox(width: 8),
            _buildFilterChip('Expirés', 'expired'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
      },
      backgroundColor: Colors.white,
      selectedColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
      checkmarkColor: ColorPages.COLOR_PRINCIPAL,
      labelStyle: TextStyle(
        color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildAdvertisementList() {
    if (_advertisements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.document, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune publicité',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _advertisements.length,
      itemBuilder: (context, index) {
        return _buildAdvertisementCard(_advertisements[index]);
      },
    );
  }

  Widget _buildAdvertisementCard(AdvertisementModel ad) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditDialog(ad),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  child: ad.imageUrl != null && ad.imageUrl!.isNotEmpty
                      ? Image.asset(ad.imageUrl!, fit: BoxFit.cover)
                      : Icon(Iconsax.image, color: ColorPages.COLOR_PRINCIPAL),
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (ad.description != null)
                      Text(
                        ad.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusBadge(ad.isActive ? 'Actif' : 'Inactif', ad.isActive),
                        const SizedBox(width: 8),
                        Text(
                          'Priorité: ${ad.priority}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton(
                icon: const Icon(Iconsax.more),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Iconsax.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Iconsax.trash, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog(ad);
                  } else if (value == 'delete') {
                    _confirmDelete(ad);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdvertisementFormPage(),
      ),
    );

    if (result == true) {
      _loadAdvertisements(); // Reload list after creation
    }
  }

  Future<void> _showEditDialog(AdvertisementModel ad) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvertisementFormPage(advertisement: ad),
      ),
    );

    if (result == true || result == 'deleted') {
      _loadAdvertisements(); // Reload list after edit/delete
    }
  }

  void _confirmDelete(AdvertisementModel ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${ad.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete from API
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publicité supprimée')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

