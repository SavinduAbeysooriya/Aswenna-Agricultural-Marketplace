import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aswenna/screens/map_location_picker.dart';
import 'package:aswenna/screens/dashboards/buyer_dashboard.dart';
import 'dart:io';

class RetailerProfileScreen extends StatefulWidget {
  const RetailerProfileScreen({super.key});

  @override
  State<RetailerProfileScreen> createState() => _RetailerProfileScreenState();
}

class _RetailerProfileScreenState extends State<RetailerProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Profile data state
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _verificationData = {};

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();

  // Retail specific controllers
  final _brNumberController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _brIssueDateController = TextEditingController();
  final _brExpiryDateController = TextEditingController();

  // Selected dropdown values
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedBusinessType;
  String? _selectedOwnershipType;

  // Selected location coordinates
  double? _latitude;
  double? _longitude;

  // Google Map controllers and state
  GoogleMapController? _mapController;
  bool _isLocating = false;

  // Sri Lanka Provinces and Districts Map
  static const Map<String, List<String>> _provinceDistricts = {
    'Western': ['Colombo', 'Gampaha', 'Kalutara'],
    'Central': ['Kandy', 'Matale', 'Nuwara Eliya'],
    'Southern': ['Galle', 'Matara', 'Hambantota'],
    'Northern': ['Jaffna', 'Kilinochchi', 'Mannar', 'Vavuniya', 'Mullaitivu'],
    'Eastern': ['Batticaloa', 'Ampara', 'Trincomalee'],
    'North Western': ['Kurunegala', 'Puttalam'],
    'North Central': ['Anuradhapura', 'Polonnaruwa'],
    'Uva': ['Badulla', 'Moneragala'],
    'Sabaragamuwa': ['Ratnapura', 'Kegalle'],
  };

  // Image upload state
  String? _brImagePath;
  List<String> _shopPhotoPaths = [];
  String? _profilePicPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _brNumberController.dispose();
    _shopAddressController.dispose();
    _postalCodeController.dispose();
    _brIssueDateController.dispose();
    _brExpiryDateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await ApiService.getRetailSellerProfile();
      debugPrint('DEBUG: getRetailSellerProfile result = $result');

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success'] == true) {
            final profile = result['profile'] ?? {};
            
            final userVal = profile['user'];
            _userData = userVal is Map ? Map<String, dynamic>.from(userVal) : {};

            final verificationVal = profile['verification_data'];
            _verificationData = verificationVal is Map ? Map<String, dynamic>.from(verificationVal) : {};

            // Initialize controllers
            _nameController.text = _userData['full_name']?.toString() ?? '';
            _emailController.text = _userData['email']?.toString() ?? '';
            _phoneController.text = _userData['phone_number']?.toString() ?? '';
            _phone2Controller.text = _userData['phone_number_2']?.toString() ?? '';
            _nicController.text = _userData['national_id']?.toString() ?? '';
            _addressController.text = _userData['address']?.toString() ?? '';
            _cityController.text = _userData['city']?.toString() ?? '';
            _districtController.text = _userData['district']?.toString() ?? '';
            _provinceController.text = _userData['province']?.toString() ?? '';

            // Retail fields
            _brNumberController.text = _verificationData['br_number']?.toString() ?? '';
            _shopAddressController.text = _verificationData['shop_address']?.toString() ?? '';
            _postalCodeController.text = _verificationData['postal_code']?.toString() ?? '';
            _brIssueDateController.text = _verificationData['br_issue_date']?.toString() ?? '';
            _brExpiryDateController.text = _verificationData['br_expiry_date']?.toString() ?? '';

            _selectedBusinessType = _verificationData['business_type']?.toString();
            _selectedOwnershipType = _verificationData['ownership_type']?.toString();

            // Set coordinates
            _latitude = _verificationData['latitude'] != null 
                ? double.tryParse(_verificationData['latitude'].toString()) 
                : (_userData['latitude'] != null ? double.tryParse(_userData['latitude'].toString()) : null);
            _longitude = _verificationData['longitude'] != null 
                ? double.tryParse(_verificationData['longitude'].toString()) 
                : (_userData['longitude'] != null ? double.tryParse(_userData['longitude'].toString()) : null);

            // Province/District sync
            final loadedProvince = _userData['province']?.toString().trim();
            if (loadedProvince != null && loadedProvince.isNotEmpty) {
              final matchedKey = _provinceDistricts.keys.firstWhere(
                (k) => k.toLowerCase() == loadedProvince.toLowerCase(),
                orElse: () => '',
              );
              if (matchedKey.isNotEmpty) {
                _selectedProvince = matchedKey;
                _provinceController.text = matchedKey;

                final loadedDistrict = _userData['district']?.toString().trim();
                if (loadedDistrict != null && loadedDistrict.isNotEmpty) {
                  final matchedDistrict = _provinceDistricts[matchedKey]!.firstWhere(
                    (d) => d.toLowerCase() == loadedDistrict.toLowerCase(),
                    orElse: () => '',
                  );
                  if (matchedDistrict.isNotEmpty) {
                    _selectedDistrict = matchedDistrict;
                    _districtController.text = matchedDistrict;
                  }
                }
              }
            }
          } else {
            _errorMessage = result['message'] ?? 'Failed to load profile details.';
          }
        });
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error initializing profile: $e';
        });
      }
      debugPrint('Error loading profile: $e\n$stack');
    }
  }

  Future<void> _pickBRImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _brImagePath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick BR file: $e')),
      );
    }
  }

  Future<void> _pickShopPhoto() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _shopPhotoPaths.addAll(result.files.map((f) => f.path!).where((p) => p.isNotEmpty));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick shop photo: $e')),
      );
    }
  }

  Future<void> _pickProfilePicture() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _profilePicPath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick profile picture: $e')),
      );
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.deepLeafGreen,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Full Name is required.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final data = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'phone_number_2': _phone2Controller.text.trim(),
        'national_id': _nicController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'province': _provinceController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,

        // Retail verification data
        'br_number': _brNumberController.text.trim(),
        'br_issue_date': _brIssueDateController.text.trim().isEmpty ? null : _brIssueDateController.text.trim(),
        'br_expiry_date': _brExpiryDateController.text.trim().isEmpty ? null : _brExpiryDateController.text.trim(),
        'business_type': _selectedBusinessType,
        'shop_address': _shopAddressController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'ownership_type': _selectedOwnershipType,
      };

      final result = await ApiService.updateRetailSellerProfile(
        data,
        brImagePath: _brImagePath,
        shopPhotosPaths: _shopPhotoPaths,
        profilePicturePath: _profilePicPath,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          if (result['success'] == true) {
            _successMessage = 'Retail profile updated successfully!';
            _brImagePath = null;
            _shopPhotoPaths = [];
            _profilePicPath = null;

            final profile = result['profile'] ?? {};
            final userVal = profile['user'];
            _userData = userVal is Map ? Map<String, dynamic>.from(userVal) : {};

            final verificationVal = profile['verification_data'];
            _verificationData = verificationVal is Map ? Map<String, dynamic>.from(verificationVal) : {};
          } else {
            _errorMessage = result['message'] ?? 'Failed to save changes.';
          }
        });
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Error saving profile changes: $e';
        });
      }
      debugPrint('Error saving profile: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _verificationData['status']?.toString().toLowerCase() ?? 'pending';
    
    String statusText = 'Verification Pending';
    Color statusColor = AppTheme.accentGold;
    IconData statusIcon = Icons.hourglass_empty_rounded;
    String statusDesc = 'Your verification document details are undergoing admin review.';

    if (status == 'verified') {
      statusText = 'Verified Retailer';
      statusColor = AppTheme.deepLeafGreen;
      statusIcon = Icons.verified_rounded;
      statusDesc = 'Your store has been verified by Aswenna Admin! You have direct selling rights.';
    } else if (status == 'rejected') {
      statusText = 'Verification Rejected';
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
      statusDesc = _verificationData['rejected_reason'] != null 
          ? "Reason: ${_verificationData['rejected_reason']}"
          : 'Your shop document verification was rejected. Please review details and update.';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text('Retailer Profile Settings'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                    ),
                                  ),
                                  if (status == 'verified') ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded, color: AppTheme.deepLeafGreen, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Picture Upload
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: _profilePicPath != null
                                ? Image.file(File(_profilePicPath!), fit: BoxFit.cover)
                                : _userData['profile_picture_path'] != null
                                    ? Image.network(
                                        ApiService.fileUrl(_userData['profile_picture_path']) ?? '',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                                      )
                                    : _buildDefaultAvatar(),
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickProfilePicture,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.deepLeafGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error & Success Alert cards
                  if (_errorMessage != null) _buildAlertCard(_errorMessage!, Colors.red),
                  if (_successMessage != null) _buildAlertCard(_successMessage!, AppTheme.deepLeafGreen),

                  // Personal details card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B5E20).withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Owner Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInputField('Full Name *', _nameController, Icons.person_rounded),
                        _buildInputField('Email Address', _emailController, Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                        _buildInputField('Primary Phone *', _phoneController, Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                        _buildInputField('Secondary Phone', _phone2Controller, Icons.phone_rounded, keyboardType: TextInputType.phone),
                        _buildInputField('National ID (NIC) / Driving License', _nicController, Icons.credit_card_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Retail details card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B5E20).withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Business & Shop Verification Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInputField('BR Number (Business Registration)', _brNumberController, Icons.text_snippet_rounded),
                        
                        // BR image picker
                        const Text('Business Registration Certificate Copy (BR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickBRImage,
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!, width: 1.5),
                            ),
                            child: _brImagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(File(_brImagePath!), fit: BoxFit.cover),
                                  )
                                : (_verificationData['br_image_path'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.network(
                                          ApiService.fileUrl(_verificationData['br_image_path']) ?? '',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.file_present_rounded, color: AppTheme.deepLeafGreen, size: 36)),
                                        ),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate_rounded, color: AppTheme.deepLeafGreen, size: 32),
                                          SizedBox(height: 8),
                                          Text('Upload Certificate Copy (PDF/JPEG)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        ],
                                      )),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // BR Dates
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectDate(_brIssueDateController),
                                child: AbsorbPointer(
                                  child: _buildInputField('BR Issue Date', _brIssueDateController, Icons.calendar_month_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectDate(_brExpiryDateController),
                                child: AbsorbPointer(
                                  child: _buildInputField('BR Expiry Date', _brExpiryDateController, Icons.calendar_today_rounded),
                                ),
                              ),
                            ),
                          ],
                        ),

                        _buildDropdownField(
                          label: 'Business Type',
                          value: _selectedBusinessType,
                          items: ['sole_proprietorship', 'partnership', 'private_limited', 'cooperative'],
                          icon: Icons.business_center_rounded,
                          hint: 'Select Business Type',
                          onChanged: (val) => setState(() => _selectedBusinessType = val),
                        ),

                        _buildDropdownField(
                          label: 'Ownership Type',
                          value: _selectedOwnershipType,
                          items: ['owned', 'rental', 'leased'],
                          icon: Icons.real_estate_agent_rounded,
                          hint: 'Select Ownership Type',
                          onChanged: (val) => setState(() => _selectedOwnershipType = val),
                        ),

                        _buildInputField('Shop Physical Address', _shopAddressController, Icons.store_mall_directory_rounded),
                        _buildInputField('Postal Code', _postalCodeController, Icons.local_post_office_rounded),

                        // Google Map Picker
                        const Text('Shop Coordinates Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _openLocationPicker,
                              icon: const Icon(Icons.search_rounded, size: 16, color: AppTheme.deepLeafGreen),
                              label: const Text('Search Picker', style: TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            TextButton.icon(
                              onPressed: _isLocating ? null : _useCurrentLocation,
                              icon: _isLocating
                                  ? const SizedBox(
                                      height: 12,
                                      width: 12,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.deepLeafGreen),
                                    )
                                  : const Icon(Icons.my_location_rounded, size: 16, color: AppTheme.deepLeafGreen),
                              label: const Text('Current Location', style: TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _latitude != null && _longitude != null
                                    ? LatLng(_latitude!, _longitude!)
                                    : const LatLng(7.8731, 80.7718),
                                zoom: _latitude != null && _longitude != null ? 15 : 7,
                              ),
                              markers: _latitude != null && _longitude != null
                                  ? {
                                      Marker(
                                        markerId: const MarkerId('retail_loc'),
                                        position: LatLng(_latitude!, _longitude!),
                                      )
                                    }
                                  : {},
                              onMapCreated: (controller) {
                                _mapController = controller;
                                if (_latitude != null && _longitude != null) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(LatLng(_latitude!, _longitude!), 15),
                                  );
                                }
                              },
                              onTap: _setLocation,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                            ),
                          ),
                        ),
                        if (_latitude != null && _longitude != null) ...[
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Shop Photos Upload
                        const Text('Shop Front & Interior Photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickShopPhoto,
                          child: Container(
                            height: 64,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.lightMint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, color: AppTheme.deepLeafGreen),
                                SizedBox(width: 8),
                                Text('Add Shop Photos', style: TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_shopPhotoPaths.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _shopPhotoPaths.map((p) => Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(p), width: 72, height: 72, fit: BoxFit.cover),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                                  onPressed: () => setState(() => _shopPhotoPaths.remove(p)),
                                ),
                              ],
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepLeafGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.deepLeafGreen.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Save Details & Submit for Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFE8F5E9),
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: AppTheme.deepLeafGreen, size: 48),
    );
  }

  Widget _buildAlertCard(String msg, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(color == Colors.red ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.deepLeafGreen, size: 20),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.deepLeafGreen, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: hint != null ? Text(hint) : null,
        isExpanded: true,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.deepLeafGreen, size: 20),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.deepLeafGreen, width: 2),
          ),
        ),
        items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _setLocation(LatLng location) {
    setState(() {
      _latitude = location.latitude;
      _longitude = location.longitude;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _errorMessage = 'Please enable location services.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _errorMessage = 'Location permission is required.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _setLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() => _errorMessage = 'Failed to fetch location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _openLocationPicker() async {
    final picked = await Navigator.of(context).push<Map<String, double>>(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          title: 'Pick Shop Location',
        ),
      ),
    );

    if (!mounted || picked == null || picked['latitude'] == null || picked['longitude'] == null) return;
    _setLocation(LatLng(picked['latitude']!, picked['longitude']!));
  }
}
