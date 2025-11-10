import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../config/theme/ColorPages.dart';
import 'AdvertisementModel.dart';

/// Advertisement Form Page for Creating/Editing Advertisements
class AdvertisementFormPage extends StatefulWidget {
  final AdvertisementModel? advertisement; // null for create, non-null for edit
  
  const AdvertisementFormPage({super.key, this.advertisement});

  @override
  State<AdvertisementFormPage> createState() => _AdvertisementFormPageState();
}

class _AdvertisementFormPageState extends State<AdvertisementFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _videoUrlController;
  late TextEditingController _actionUrlController;
  late TextEditingController _priorityController;
  
  // Form values
  String _advertisementType = 'campaign';
  String _actionType = 'none';
  List<String> _targetAudience = ['all'];
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;

  // File uploads
  File? _selectedImage;
  File? _selectedVideo;
  final ImagePicker _imagePicker = ImagePicker();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _titleController = TextEditingController(text: widget.advertisement?.title ?? '');
    _descriptionController = TextEditingController(text: widget.advertisement?.description ?? '');
    _imageUrlController = TextEditingController(text: widget.advertisement?.imageUrl ?? '');
    _videoUrlController = TextEditingController(text: widget.advertisement?.videoUrl ?? '');
    _actionUrlController = TextEditingController(text: widget.advertisement?.actionUrl ?? '');
    _priorityController = TextEditingController(
      text: widget.advertisement?.priority.toString() ?? '10'
    );
    
    // Initialize form values from existing advertisement
    if (widget.advertisement != null) {
      _advertisementType = widget.advertisement!.advertisementType ?? 'campaign';
      _actionType = widget.advertisement!.actionType ?? 'none';
      _targetAudience = [widget.advertisement!.targetAudience ?? 'all'];
      _isActive = widget.advertisement!.isActive;
      _startDate = widget.advertisement!.startDate;
      _endDate = widget.advertisement!.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _actionUrlController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrlController.text = image.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image sélectionnée')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedVideo = File(result.files.single.path!);
          _videoUrlController.text = result.files.single.path!;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vidéo sélectionnée')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.advertisement != null;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Modifier la Publicité' : 'Nouvelle Publicité',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Iconsax.trash, color: Colors.white),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Titre *',
              hint: 'Ex: Campagne de Don de Sang',
              icon: Iconsax.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le titre est requis';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Décrivez la publicité...',
              icon: Iconsax.document_text,
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Advertisement Type
            _buildDropdown(
              label: 'Type de Publicité *',
              value: _advertisementType,
              items: const [
                {'value': 'campaign', 'label': 'Campagne'},
                {'value': 'promotion', 'label': 'Promotion'},
                {'value': 'announcement', 'label': 'Annonce'},
                {'value': 'urgent', 'label': 'Urgent'},
                {'value': 'event', 'label': 'Événement'},
                {'value': 'education', 'label': 'Éducation'},
              ],
              onChanged: (value) => setState(() => _advertisementType = value!),
            ),
            
            const SizedBox(height: 16),
            
            // Priority
            _buildTextField(
              controller: _priorityController,
              label: 'Priorité *',
              hint: '0-100 (plus élevé = affiché en premier)',
              icon: Iconsax.sort,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La priorité est requise';
                }
                final priority = int.tryParse(value);
                if (priority == null || priority < 0 || priority > 100) {
                  return 'Priorité doit être entre 0 et 100';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Target Audience
            _buildMultiSelect(
              label: 'Audience Cible *',
              options: const [
                {'value': 'all', 'label': 'Tous'},
                {'value': 'hospital', 'label': 'Hôpitaux'},
                {'value': 'blood_bank', 'label': 'Banques de Sang'},
                {'value': 'donor', 'label': 'Donneurs'},
                {'value': 'patient', 'label': 'Patients'},
              ],
              selectedValues: _targetAudience,
              onChanged: (values) => setState(() => _targetAudience = values),
            ),
            
            const SizedBox(height: 16),

            // Image Upload
            _buildMediaUploadSection(
              label: 'Image de la Publicité',
              icon: Iconsax.image,
              file: _selectedImage,
              controller: _imageUrlController,
              onPickFile: _pickImage,
              onClear: () => setState(() {
                _selectedImage = null;
                _imageUrlController.clear();
              }),
            ),

            const SizedBox(height: 16),

            // Video Upload
            _buildMediaUploadSection(
              label: 'Vidéo de la Publicité',
              icon: Iconsax.video,
              file: _selectedVideo,
              controller: _videoUrlController,
              onPickFile: _pickVideo,
              onClear: () => setState(() {
                _selectedVideo = null;
                _videoUrlController.clear();
              }),
            ),

            const SizedBox(height: 16),
            
            // Action Type
            _buildDropdown(
              label: 'Type d\'Action',
              value: _actionType,
              items: const [
                {'value': 'none', 'label': 'Aucune'},
                {'value': 'internal', 'label': 'Navigation Interne'},
                {'value': 'external', 'label': 'URL Externe'},
                {'value': 'modal', 'label': 'Afficher Détails'},
              ],
              onChanged: (value) => setState(() => _actionType = value!),
            ),
            
            const SizedBox(height: 16),
            
            // Action URL (only if action type is not 'none')
            if (_actionType != 'none')
              _buildTextField(
                controller: _actionUrlController,
                label: 'URL d\'Action',
                hint: _actionType == 'internal' ? '/page/route' : 'https://...',
                icon: Iconsax.link,
              ),
            
            if (_actionType != 'none') const SizedBox(height: 16),
            
            // Date Range
            _buildDateRangePicker(),
            
            const SizedBox(height: 16),
            
            // Active Status
            _buildSwitch(
              label: 'Actif',
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            
            const SizedBox(height: 32),
            
            // Save Button
            ElevatedButton(
              onPressed: _saving ? null : _saveAdvertisement,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEdit ? 'Enregistrer les Modifications' : 'Créer la Publicité',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: ColorPages.COLOR_PRINCIPAL),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['value'],
          child: Text(item['label']!),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMultiSelect({
    required String label,
    required List<Map<String, String>> options,
    required List<String> selectedValues,
    required void Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option['value']);
            return FilterChip(
              label: Text(option['label']!),
              selected: isSelected,
              onSelected: (selected) {
                final newValues = List<String>.from(selectedValues);
                if (selected) {
                  newValues.add(option['value']!);
                } else {
                  newValues.remove(option['value']);
                }
                if (newValues.isNotEmpty) {
                  onChanged(newValues);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
              checkmarkColor: ColorPages.COLOR_PRINCIPAL,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Période de Validité',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                label: 'Date de Début',
                date: _startDate,
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateButton(
                label: 'Date de Fin',
                date: _endDate,
                onTap: () => _selectDate(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Non définie',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ColorPages.COLOR_PRINCIPAL,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaUploadSection({
    required String label,
    required IconData icon,
    required File? file,
    required TextEditingController controller,
    required VoidCallback onPickFile,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Preview or placeholder
              if (file != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: icon == Iconsax.image
                        ? DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: icon == Iconsax.video ? Colors.black87 : null,
                  ),
                  child: icon == Iconsax.video
                      ? const Center(
                          child: Icon(
                            Iconsax.video_play,
                            size: 48,
                            color: Colors.white,
                          ),
                        )
                      : null,
                )
              else
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aucun fichier sélectionné',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPickFile,
                      icon: Icon(icon),
                      label: Text(file != null ? 'Changer' : 'Sélectionner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPages.COLOR_PRINCIPAL,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (file != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                      color: Colors.red,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ],
              ),

              // URL field (optional)
              if (controller.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Ou entrez une URL:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveAdvertisement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _saving = true);
    
    // TODO: Call API to create/update advertisement
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _saving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.advertisement != null
                ? 'Publicité modifiée avec succès'
                : 'Publicité créée avec succès',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate success
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette publicité ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, 'deleted'); // Return to list
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

