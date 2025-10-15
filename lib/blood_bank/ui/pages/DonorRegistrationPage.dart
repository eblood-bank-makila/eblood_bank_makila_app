import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../controllers/donor_registration_controller.dart';

class DonorRegistrationPage extends ConsumerStatefulWidget {
  const DonorRegistrationPage({super.key});

  @override
  ConsumerState<DonorRegistrationPage> createState() => _DonorRegistrationPageState();
}

class _DonorRegistrationPageState extends ConsumerState<DonorRegistrationPage> {
  // Step tracking
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form data
  File? _donorPhoto;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactPhoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedBloodType;
  String? _selectedGender;
  bool _needsAccount = false;
  bool _isSubmitting = false;
  bool _submissionSuccessful = false;
  String _errorMessage = '';

  // Available blood types
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _dobController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inscription Donneur de Sang',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // If we're on the first step or showing results, go back to previous page
            if (_currentStep == 0 || _submissionSuccessful) {
              Navigator.pop(context);
            } else {
              // Otherwise go back to previous step
              setState(() {
                _currentStep--;
              });
            }
          },
        ),
      ),
      body: _isSubmitting
          ? _buildLoadingState()
          : _submissionSuccessful
              ? _buildSuccessState()
              : _buildRegistrationStep(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildRegistrationStep() {
    switch (_currentStep) {
      case 0:
        return _buildPhotoStep();
      case 1:
        return _buildFormStep();
      case 2:
        return _buildOverviewStep();
      default:
        return _buildPhotoStep();
    }
  }

  Widget _buildPhotoStep() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Photo du Donneur',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Prenez une photo claire du visage du donneur',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _donorPhoto == null
                ? Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.file(
                      _donorPhoto!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _takeDonorPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text('Appareil photo', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => _takeDonorPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text('Galerie', style: GoogleFonts.poppins()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations du Donneur',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Personal Information
            _buildSectionTitle('Informations Personnelles'),
            
            // First Name
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.user),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer le prénom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Last Name
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.user),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer le nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Phone Number
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.call),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer le numéro de téléphone';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Email (optional)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.message),
              ),
            ),
            const SizedBox(height: 16),
            
            // Gender Selection
            _buildSectionTitle('Genre'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Masculin', style: GoogleFonts.poppins()),
                    value: 'M',
                    groupValue: _selectedGender,
                    activeColor: Colors.red,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Féminin', style: GoogleFonts.poppins()),
                    value: 'F',
                    groupValue: _selectedGender,
                    activeColor: Colors.red,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Blood Type Dropdown
            _buildSectionTitle('Groupe Sanguin'),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.bloodtype),
              ),
              value: _selectedBloodType,
              items: _bloodTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBloodType = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner un groupe sanguin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Date of Birth
            TextFormField(
              controller: _dobController,
              decoration: InputDecoration(
                labelText: 'Date de Naissance',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.calendar),
                hintText: 'YYYY-MM-DD',
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer la date de naissance';
                }
                // Validate date format
                final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                if (!datePattern.hasMatch(value)) {
                  return 'Format de date invalide (YYYY-MM-DD)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Address
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.location),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            
            // Emergency Contact Information
            _buildSectionTitle('Contact d\'Urgence'),
            const SizedBox(height: 8),
            
            // Emergency Contact Name
            TextFormField(
              controller: _emergencyContactNameController,
              decoration: InputDecoration(
                labelText: 'Nom du contact d\'urgence',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.user_tag),
              ),
            ),
            const SizedBox(height: 16),
            
            // Emergency Contact Phone
            TextFormField(
              controller: _emergencyContactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Téléphone du contact d\'urgence',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.call),
              ),
            ),
            const SizedBox(height: 30),
            
            // Account Creation Checkbox
            CheckboxListTile(
              title: Text(
                'Créer un compte utilisateur pour ce donneur',
                style: GoogleFonts.poppins(),
              ),
              value: _needsAccount,
              activeColor: Colors.red,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  _needsAccount = value ?? false;
                });
              },
            ),
            
            // Account Creation Fields (conditionally visible)
            if (_needsAccount) ...[
              const SizedBox(height: 20),
              _buildSectionTitle('Informations de Compte'),
              const SizedBox(height: 10),
              
              // Username/Email
              TextFormField(
                controller: _usernameController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email (Nom d\'utilisateur)',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Iconsax.user),
                ),
                validator: (value) {
                  if (_needsAccount) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une adresse email';
                    }
                    // Simple email validation
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Veuillez entrer une adresse email valide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de Passe',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Iconsax.lock),
                ),
                validator: (value) {
                  if (_needsAccount) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 8) {
                      return 'Le mot de passe doit contenir au moins 8 caractères';
                    }
                  }
                  return null;
                },
              ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vérification des Informations',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Donor Photo
          Center(
            child: _donorPhoto == null
                ? Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.file(
                      _donorPhoto!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          
          // Personal Information Summary
          _buildSummaryCard(
            title: 'Informations Personnelles',
            items: [
              SummaryItem(label: 'Prénom', value: _firstNameController.text),
              SummaryItem(label: 'Nom', value: _lastNameController.text),
              SummaryItem(label: 'Téléphone', value: _phoneController.text),
              SummaryItem(label: 'Email', value: _emailController.text.isEmpty ? 'Non spécifié' : _emailController.text),
              SummaryItem(label: 'Genre', value: _selectedGender == 'M' ? 'Masculin' : 'Féminin'),
              SummaryItem(label: 'Groupe Sanguin', value: _selectedBloodType ?? ''),
              SummaryItem(label: 'Date de Naissance', value: _dobController.text),
              SummaryItem(label: 'Adresse', value: _addressController.text.isEmpty ? 'Non spécifiée' : _addressController.text),
            ],
          ),
          
          // Emergency Contact Information
          if (_emergencyContactNameController.text.isNotEmpty || _emergencyContactPhoneController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSummaryCard(
              title: 'Contact d\'Urgence',
              items: [
                SummaryItem(
                  label: 'Nom', 
                  value: _emergencyContactNameController.text.isEmpty ? 'Non spécifié' : _emergencyContactNameController.text
                ),
                SummaryItem(
                  label: 'Téléphone', 
                  value: _emergencyContactPhoneController.text.isEmpty ? 'Non spécifié' : _emergencyContactPhoneController.text
                ),
              ],
            ),
          ],
          
          if (_needsAccount) ...[
            const SizedBox(height: 16),
            _buildSummaryCard(
              title: 'Informations de Compte',
              items: [
                SummaryItem(label: 'Email', value: _usernameController.text),
                SummaryItem(label: 'Mot de Passe', value: '••••••••'),
              ],
            ),
          ],
          
          // Error message if any
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.red),
          const SizedBox(height: 24),
          Text(
            'Enregistrement en cours...',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veuillez patienter',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Inscription Réussie!',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: [
                Column(
                  children: [
                    Text(
                      'Le donneur a été enregistré avec succès!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Veuillez conserver le code donneur pour référence future.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        InkWell(
                          onTap: () {
                            final donorCode = ref.read(donorRegistrationProvider.notifier).donorCode;
                            Clipboard.setData(ClipboardData(text: donorCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Code copié dans le presse-papiers',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red.shade200)
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.code, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Code Donneur: ${ref.read(donorRegistrationProvider.notifier).donorCode}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Iconsax.copy, color: Colors.red, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300)
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment_ind, color: Colors.grey.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ID Donneur: ${ref.read(donorRegistrationProvider.notifier).donorId}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_donorPhoto != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'La photo a été téléchargée avec succès.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Reset the form and start a new registration
                  setState(() {
                    _currentStep = 0;
                    _submissionSuccessful = false;
                    _donorPhoto = null;
                    _firstNameController.clear();
                    _lastNameController.clear();
                    _phoneController.clear();
                    _emailController.clear();
                    _addressController.clear();
                    _emergencyContactNameController.clear();
                    _emergencyContactPhoneController.clear();
                    _dobController.clear();
                    _usernameController.clear();
                    _passwordController.clear();
                    _selectedBloodType = null;
                    _selectedGender = null;
                    _needsAccount = false;
                  });
                },
                icon: const Icon(Iconsax.add_circle),
                label: Text(
                  'Nouvel Enregistrement',
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: GoogleFonts.poppins(fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, true); // Return true to refresh donor list
                    },
                    icon: const Icon(Icons.home),
                    label: Text(
                      'Retourner à l\'accueil',
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      textStyle: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Return to donor list and refresh
                      Navigator.pop(context, true); // Pass true to indicate refresh
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'Voir les donneurs',
                      style: GoogleFonts.poppins(),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      textStyle: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    if (_isSubmitting || _submissionSuccessful) {
      return const SizedBox.shrink(); // Hide navigation when loading or successful
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index <= _currentStep ? Colors.red : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button (hidden on first step)
              _currentStep > 0
                  ? OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('Précédent', style: GoogleFonts.poppins()),
                    )
                  : const SizedBox(width: 100),
              
              // Step indicator text
              Text(
                'Étape ${_currentStep + 1}/$_totalSteps',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              // Next/Submit Button
              ElevatedButton(
                onPressed: () {
                  _handleNextStep();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  _currentStep == _totalSteps - 1 ? 'Soumettre' : 'Suivant',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  Future<void> _takeDonorPhoto(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _donorPhoto = File(image.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime(now.year - 18, now.month, now.day);
    final DateTime firstDate = DateTime(now.year - 100);
    final DateTime lastDate = now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format in YYYY-MM-DD as required by the API
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _handleNextStep() {
    // For the photo step, check if photo is taken
    if (_currentStep == 0) {
      if (_donorPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez prendre une photo du donneur'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Move to next step
      setState(() {
        _currentStep++;
      });
      return;
    }
    
    // For form step, validate inputs
    if (_currentStep == 1) {
      if (_formKey.currentState!.validate() && _selectedGender != null) {
        // Form is valid, move to next step
        setState(() {
          _currentStep++;
        });
      } else {
        // Show error if gender is not selected (form validation handles the rest)
        if (_selectedGender == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez sélectionner le genre'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }
    
    // For overview step, submit the form
    if (_currentStep == 2) {
      _submitDonorRegistration();
    }
  }

  Future<void> _submitDonorRegistration() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });
    
    try {
      // Create donor data model
      final donorData = DonorData(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        gender: _selectedGender ?? 'M',
        bloodType: _selectedBloodType ?? 'O+',
        dateOfBirth: _dobController.text,
        address: _addressController.text,
        emergencyContactName: _emergencyContactNameController.text,
        emergencyContactPhone: _emergencyContactPhoneController.text,
        photo: _donorPhoto,
        createAccount: _needsAccount,
        username: _needsAccount ? _usernameController.text : null,
        password: _needsAccount ? _passwordController.text : null,
      );
      
      // Get the registration controller
      final registrationController = ref.read(donorRegistrationProvider.notifier);
      
      // Submit registration - now returns Map with additional info
      final result = await registrationController.registerDonor(donorData);
      
      if (result['success']) {
        // Store donor ID and code in case we need them later
        final donorId = result['donorId'];
        final donorCode = result['donorCode'];
        debugPrint('Donor registered successfully with ID: $donorId, Code: $donorCode');
        
        setState(() {
          _isSubmitting = false;
          _submissionSuccessful = true;
        });
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = result['message'] ?? 'Une erreur s\'est produite. Veuillez réessayer.';
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Une erreur s\'est produite: ${e.toString()}';
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required List<SummaryItem> items}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(),
            ...items.map((item) => _buildSummaryRow(item.label, item.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryItem {
  final String label;
  final String value;

  SummaryItem({required this.label, required this.value});
}