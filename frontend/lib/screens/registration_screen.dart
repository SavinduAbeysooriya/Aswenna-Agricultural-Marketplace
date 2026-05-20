import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/services/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  final String role;
  final Map<String, String>? registrationData;

  const RegistrationScreen({super.key, required this.role, this.registrationData});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with TickerProviderStateMixin {
  int _currentStep = 1;
  final _formKey = GlobalKey<FormState>();

  // Upload State Variables
  String? _profilePhotoName;
  bool _isUploadingProfile = false;
  double _profileUploadProgress = 0;

  String? _docName;
  bool _isUploadingDoc = false;
  double _docUploadProgress = 0;

  // OTP verification flag
  bool _emailVerified = false;

  @override
  void initState() {
    super.initState();
    if (widget.registrationData != null) {
      _emailController.text = widget.registrationData!['email'] ?? '';
      _passwordController.text = widget.registrationData!['password'] ?? '';
      if (widget.registrationData!.containsKey('name')) {
        _nameController.text = widget.registrationData!['name'] ?? '';
      }
      // Google users are pre-verified
      _emailVerified = true;
    }
  }

  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedProvince;
  String? _selectedDistrict;

  // Role-Specific Fields
  // Farmer
  final _farmNameController = TextEditingController();
  final _cropCategoriesController = TextEditingController();
  final _landSizeController = TextEditingController();
  final _experienceController = TextEditingController();

  // Buyer
  final _deliveryAddressController = TextEditingController();
  final _favCategoriesController = TextEditingController();

  // Retail Seller
  final _businessNameController = TextEditingController();
  final _bizRegController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _productCatsController = TextEditingController();

  // Delivery
  String? _selectedVehicleType;
  final _nicController = TextEditingController();

  final List<String> _provinces = ['Central', 'North Central', 'Southern', 'Uva', 'Western'];
  final List<String> _districts = ['Nuwara Eliya', 'Anuradhapura', 'Badulla', 'Colombo', 'Galle'];
  final List<String> _vehicles = ['Motorcycle', 'Three-Wheeler', 'Mini Truck (Dimo Batta)', 'Light Truck'];

  bool get _isGoogleSignup => widget.registrationData != null;

  @override
  Widget build(BuildContext context) {
    String roleLabel = widget.role.replaceAll('_', ' ').toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Register Account'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Progress Header
            Container(
              color: AppTheme.pureWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step $_currentStep of 2',
                        style: const TextStyle(
                          color: AppTheme.freshGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Row(
                        children: [
                          if (_isGoogleSignup)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, size: 12, color: AppTheme.freshGreen),
                                  SizedBox(width: 3),
                                  Text(
                                    'GOOGLE',
                                    style: TextStyle(
                                      color: AppTheme.freshGreen,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.lightMint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              roleLabel,
                              style: const TextStyle(
                                color: AppTheme.deepLeafGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress indicator bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _currentStep / 2,
                      minHeight: 8,
                      backgroundColor: AppTheme.softGray,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.freshGreen),
                    ),
                  ),
                ],
              ),
            ),
            // Form viewport scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 1 ? _buildCommonFields() : _buildRoleFields(),
                  ),
                ),
              ),
            ),
            // Bottom Action control button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  shadowColor: AppTheme.deepLeafGreen.withOpacity(0.3),
                  elevation: 6,
                ),
                child: Text(_currentStep == 1 ? 'Continue' : 'Complete Registration'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Interactive Profile Photo Uploader Widget
  // ──────────────────────────────────────────────────────
  Widget _buildProfilePhotoUploader() {
    return Center(
      child: GestureDetector(
        onTap: _profilePhotoName != null ? null : () => _showPhotoPickerSheet(),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _profilePhotoName != null
                    ? AppTheme.lightMint
                    : AppTheme.pureWhite,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _profilePhotoName != null
                      ? AppTheme.freshGreen
                      : AppTheme.deepLeafGreen.withOpacity(0.15),
                  width: _profilePhotoName != null ? 3 : 4,
                ),
                boxShadow: [
                  if (_profilePhotoName != null)
                    BoxShadow(
                      color: AppTheme.freshGreen.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: _isUploadingProfile
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            value: _profileUploadProgress,
                            strokeWidth: 3,
                            backgroundColor: AppTheme.softGray,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.freshGreen),
                          ),
                        ),
                        Text(
                          '${(_profileUploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppTheme.deepLeafGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : _profilePhotoName != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              color: AppTheme.freshGreen,
                              size: 40,
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppTheme.freshGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Icon(
                            Icons.add_a_photo_rounded,
                            color: AppTheme.deepLeafGreen,
                            size: 32,
                          ),
                        ),
            ),
            const SizedBox(height: 8),
            if (_profilePhotoName != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.freshGreen, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _profilePhotoName!,
                    style: const TextStyle(
                      color: AppTheme.freshGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _profilePhotoName = null),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 11, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ] else
              const Text(
                'Upload Profile Photo',
                style: TextStyle(
                  color: AppTheme.deepLeafGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Photo Picker Bottom Sheet (simulated)
  // ──────────────────────────────────────────────────────
  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPickerOption(
                    Icons.camera_alt_rounded,
                    'Camera',
                    const Color(0xFF2196F3),
                    () {
                      Navigator.pop(context);
                      _simulateUpload(isProfile: true, fileName: 'camera_photo.jpg');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerOption(
                    Icons.photo_library_rounded,
                    'Gallery',
                    const Color(0xFF4CAF50),
                    () {
                      Navigator.pop(context);
                      _simulateUpload(isProfile: true, fileName: 'gallery_photo.jpg');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerOption(
                    Icons.account_circle_rounded,
                    'Avatar',
                    const Color(0xFF9C27B0),
                    () {
                      Navigator.pop(context);
                      _simulateUpload(isProfile: true, fileName: 'avatar_default.png');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Simulated Upload with animated progress
  // ──────────────────────────────────────────────────────
  void _simulateUpload({required bool isProfile, required String fileName}) {
    if (isProfile) {
      setState(() {
        _isUploadingProfile = true;
        _profileUploadProgress = 0;
      });
    } else {
      setState(() {
        _isUploadingDoc = true;
        _docUploadProgress = 0;
      });
    }

    Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (isProfile) {
          _profileUploadProgress += 0.05;
          if (_profileUploadProgress >= 1.0) {
            _profileUploadProgress = 1.0;
            _isUploadingProfile = false;
            _profilePhotoName = fileName;
            timer.cancel();
          }
        } else {
          _docUploadProgress += 0.04;
          if (_docUploadProgress >= 1.0) {
            _docUploadProgress = 1.0;
            _isUploadingDoc = false;
            _docName = fileName;
            timer.cancel();
          }
        }
      });
    });
  }

  // ──────────────────────────────────────────────────────
  // Step 1: General fields for all users
  // ──────────────────────────────────────────────────────
  Widget _buildCommonFields() {
    final bool isGoogle = _isGoogleSignup;

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'General Information',
          style: TextStyle(
            color: AppTheme.darkGreen,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isGoogle
              ? 'Your Google account is verified. Complete the remaining fields.'
              : 'Provide your primary personal contact details.',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 20),
        // Interactive Profile Photo Uploader
        _buildProfilePhotoUploader(),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.deepLeafGreen),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
            hintText: 'e.g. 0771234567',
            prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppTheme.deepLeafGreen),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !isGoogle,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'yourname@example.com',
            prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppTheme.deepLeafGreen),
            suffixIcon: isGoogle
                ? const Icon(Icons.verified_rounded, color: AppTheme.freshGreen, size: 20)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          enabled: !isGoogle,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Create secure password',
            prefixIcon: const Icon(Icons.lock_open_rounded, color: AppTheme.deepLeafGreen),
            suffixIcon: isGoogle
                ? const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 20)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedProvince,
                hint: const Text('Province'),
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14)),
                items: _provinces.map((prov) {
                  return DropdownMenuItem(value: prov, child: Text(prov));
                }).toList(),
                onChanged: (val) => setState(() => _selectedProvince = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDistrict,
                hint: const Text('District'),
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14)),
                items: _districts.map((dist) {
                  return DropdownMenuItem(value: dist, child: Text(dist));
                }).toList(),
                onChanged: (val) => setState(() => _selectedDistrict = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────
  // Step 2: Custom fields depending on user role
  // ──────────────────────────────────────────────────────
  Widget _buildRoleFields() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workspace Verification',
          style: TextStyle(
            color: AppTheme.darkGreen,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Provide specific credentials matching your user group.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 24),
        if (widget.role == 'farmer') ...[
          TextFormField(
            controller: _farmNameController,
            decoration: const InputDecoration(
              labelText: 'Farm Name',
              hintText: 'e.g. Nuwara Eliya Organic Fields',
              prefixIcon: Icon(Icons.landscape_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cropCategoriesController,
            decoration: const InputDecoration(
              labelText: 'Crop Categories',
              hintText: 'e.g. Potato, Carrot, Beetroot',
              prefixIcon: Icon(Icons.grass_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _landSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Land Size (Acres)',
                    hintText: 'e.g. 2.5',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Farming Experience',
                    hintText: 'e.g. 5 Years',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInteractiveCertUploader('Upload GAP / Organic Certifications'),
        ] else if (widget.role == 'buyer') ...[
          TextFormField(
            controller: _deliveryAddressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Default Delivery Address',
              hintText: 'Enter your office or factory address',
              prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _favCategoriesController,
            decoration: const InputDecoration(
              labelText: 'Favorite Purchasing Categories',
              hintText: 'e.g. Grains, Vegetables, Spices',
              prefixIcon: Icon(Icons.favorite_outline_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
        ] else if (widget.role == 'retail_seller') ...[
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Registered Business Name',
              hintText: 'e.g. Agro Lanka Supermarkets',
              prefixIcon: Icon(Icons.store_mall_directory_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bizRegController,
            decoration: const InputDecoration(
              labelText: 'Business Registration (BR) Number',
              hintText: 'e.g. PV/12345/LK',
              prefixIcon: Icon(Icons.badge_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _storeAddressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Physical Store Address',
              hintText: 'Where customers pick up orders',
              prefixIcon: Icon(Icons.pin_drop_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _productCatsController,
            decoration: const InputDecoration(
              labelText: 'Product Categories',
              hintText: 'e.g. Seedlings, Fertilizers, Pots',
              prefixIcon: Icon(Icons.category_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
        ] else if (widget.role == 'delivery_partner') ...[
          DropdownButtonFormField<String>(
            value: _selectedVehicleType,
            hint: const Text('Select Vehicle Type'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.delivery_dining_rounded, color: AppTheme.deepLeafGreen),
            ),
            items: _vehicles.map((v) {
              return DropdownMenuItem(value: v, child: Text(v));
            }).toList(),
            onChanged: (val) => setState(() => _selectedVehicleType = val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nicController,
            decoration: const InputDecoration(
              labelText: 'National Identity Card (NIC)',
              hintText: 'e.g. 199012345678 or 901234567V',
              prefixIcon: Icon(Icons.perm_identity_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 20),
          _buildInteractiveCertUploader('Upload Driving License Photo'),
        ] else ...[
          // Default Customer options
          const Text(
            'Preferred Categories',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPrefChip('Fresh Veggies'),
              _buildPrefChip('Organic Fruits'),
              _buildPrefChip('Grains & Rice'),
              _buildPrefChip('Farming Tools'),
              _buildPrefChip('Seeds & Plants'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPrefChip(String label) {
    return FilterChip(
      label: Text(label),
      selectedColor: AppTheme.lightMint,
      checkmarkColor: AppTheme.deepLeafGreen,
      onSelected: (val) {},
    );
  }

  // ──────────────────────────────────────────────────────
  // Interactive Certificate / Document Uploader
  // ──────────────────────────────────────────────────────
  Widget _buildInteractiveCertUploader(String label) {
    final bool hasDoc = _docName != null;

    return GestureDetector(
      onTap: hasDoc ? null : () => _showDocPickerSheet(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasDoc ? const Color(0xFFF0FFF4) : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasDoc
                ? AppTheme.freshGreen.withOpacity(0.4)
                : AppTheme.deepLeafGreen.withOpacity(0.15),
            width: hasDoc ? 2 : 1,
          ),
          boxShadow: [
            if (hasDoc)
              BoxShadow(
                color: AppTheme.freshGreen.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: _isUploadingDoc
            ? Column(
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload_rounded, color: AppTheme.deepLeafGreen, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Uploading document...',
                              style: TextStyle(
                                color: AppTheme.deepLeafGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _docUploadProgress,
                                minHeight: 6,
                                backgroundColor: AppTheme.softGray,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.freshGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(_docUploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: AppTheme.deepLeafGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              )
            : hasDoc
                ? Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.freshGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_rounded, color: AppTheme.freshGreen, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _docName!,
                              style: const TextStyle(
                                color: AppTheme.darkGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Uploaded successfully',
                              style: TextStyle(color: AppTheme.freshGreen, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: AppTheme.freshGreen, size: 22),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _docName = null),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close, size: 15, color: Colors.red),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.upload_file_rounded,
                        color: AppTheme.deepLeafGreen,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.deepLeafGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to select file',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                    ],
                  ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Document Picker Bottom Sheet
  // ──────────────────────────────────────────────────────
  void _showDocPickerSheet(String label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select from available sources',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPickerOption(
                    Icons.camera_alt_rounded,
                    'Camera',
                    const Color(0xFF2196F3),
                    () {
                      Navigator.pop(context);
                      _simulateUpload(isProfile: false, fileName: 'camera_scan.jpg');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerOption(
                    Icons.folder_open_rounded,
                    'Files',
                    const Color(0xFFFF9800),
                    () {
                      Navigator.pop(context);
                      _simulateUpload(isProfile: false, fileName: 'certificate.pdf');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerOption(
                    Icons.photo_library_rounded,
                    'Gallery',
                    const Color(0xFF4CAF50),
                    () {
                      Navigator.pop(context);
                      _simulateUpload(isProfile: false, fileName: 'doc_photo.jpg');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // OTP Verification Bottom Sheet (Email)
  // ──────────────────────────────────────────────────────
  void _showOtpVerificationSheet() {
    final otpController = TextEditingController();
    bool isPending = false;
    bool isSending = true;
    String errorMessage = '';
    String successMessage = '';

    final email = _emailController.text.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Auto-send OTP on first build
            if (isSending) {
              Future.microtask(() async {
                final res = await ApiService.sendOtp(email);
                if (!context.mounted) return;
                setSheetState(() {
                  isSending = false;
                  if (res['success'] == true) {
                    successMessage = 'Verification code sent to $email';
                  } else {
                    successMessage = 'Using sandbox code 123456 for testing';
                  }
                });
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Icon Badge
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.freshGreen.withOpacity(0.15),
                            AppTheme.deepLeafGreen.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: AppTheme.deepLeafGreen,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSending ? 'Sending code to $email...' : successMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isSending)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
                        ),
                      )
                    else ...[
                      // OTP Input
                      TextFormField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                          color: AppTheme.darkGreen,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••',
                          hintStyle: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 28,
                            letterSpacing: 12,
                          ),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.deepLeafGreen.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppTheme.freshGreen, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isPending
                              ? null
                              : () async {
                                  if (otpController.text.length != 6) {
                                    setSheetState(() => errorMessage = 'Enter a 6-digit code');
                                    return;
                                  }
                                  setSheetState(() {
                                    isPending = true;
                                    errorMessage = '';
                                  });

                                  final res = await ApiService.verifyOtp(email, otpController.text);

                                  if (!context.mounted) return;

                                  if (res['success'] == true) {
                                    Navigator.pop(sheetContext);
                                    setState(() {
                                      _emailVerified = true;
                                      _currentStep = 2;
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✅ Email verified successfully!'),
                                          backgroundColor: AppTheme.freshGreen,
                                        ),
                                      );
                                    }
                                  } else {
                                    setSheetState(() {
                                      isPending = false;
                                      errorMessage = res['message'] ?? 'Invalid code.';
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isPending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Verify & Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Resend link
                      TextButton(
                        onPressed: isPending
                            ? null
                            : () async {
                                setSheetState(() {
                                  isSending = true;
                                  errorMessage = '';
                                });
                                final res = await ApiService.sendOtp(email);
                                if (!context.mounted) return;
                                setSheetState(() {
                                  isSending = false;
                                  if (res['success'] == true) {
                                    successMessage = 'New code sent to $email';
                                  } else {
                                    successMessage = 'Using sandbox code 123456';
                                  }
                                });
                              },
                        child: const Text(
                          'Resend Verification Code',
                          style: TextStyle(
                            color: AppTheme.deepLeafGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────
  // Handle Continue Button
  // ──────────────────────────────────────────────────────
  void _handleContinue() async {
    if (_currentStep == 1) {
      // For standard (non-Google) signups, verify email via OTP first
      if (!_isGoogleSignup && !_emailVerified) {
        final email = _emailController.text.trim();
        if (email.isEmpty || !email.contains('@')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid email address to verify.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _showOtpVerificationSheet();
        return;
      }

      // Google users or already verified: advance to step 2
      setState(() {
        _currentStep = 2;
      });
    } else {
      // Validate general form logic
      if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
        return;
      }

      // Show sleek loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
          ),
        ),
      );

      // Extract details
      final result = await ApiService.registerUser(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        province: _selectedProvince ?? '',
        district: _selectedDistrict ?? '',
        role: widget.role,
        farmingLicense: _farmNameController.text.isNotEmpty ? _farmNameController.text : null,
        brNumber: _bizRegController.text.isNotEmpty ? _bizRegController.text : null,
        shopAddress: _storeAddressController.text.isNotEmpty ? _storeAddressController.text : null,
        vehicleType: _selectedVehicleType,
      );

      // Dismiss loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.freshGreen, size: 28),
                  SizedBox(width: 8),
                  Text('Success!'),
                ],
              ),
              content: const Text(
                'Your Aswenna account has been created successfully. Welcome to the Direct-to-Marketplace digital ecosystem.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss Dialog
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } else {
        // Show validation or network errors
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 8),
                  Text('Failed to Register'),
                ],
              ),
              content: Text(
                result['errors'] != null
                    ? 'Registration validation failed:\n\n${result['errors'].toString()}'
                    : result['message'] ?? 'Unable to connect to the backend server.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}
