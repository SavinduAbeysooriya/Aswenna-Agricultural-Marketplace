import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aswenna/screens/map_location_picker.dart';
import 'package:aswenna/screens/dashboards/retailer_dashboard.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'dart:io';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _errorMessage;
  String? _successMessage;

  // Profile data state
  Map<String, dynamic> _userData = {};
  List<dynamic> _documents = [];

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

  // Selected dropdown values
  String? _selectedProvince;
  String? _selectedDistrict;

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

  // Document upload state
  String _selectedDocType = 'National ID';
  String? _frontImagePath;
  String? _backImagePath;
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
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      if (!_isLoading) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final result = await ApiService.getBuyerProfile();
      debugPrint('DEBUG: getBuyerProfile result = $result');

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success'] == true) {
            final profile = result['profile'] ?? {};
            
            // Extremely safe cast for user map
            final userVal = profile['user'];
            if (userVal is Map<String, dynamic>) {
              _userData = userVal;
            } else if (userVal is Map) {
              _userData = Map<String, dynamic>.from(userVal);
            } else {
              _userData = {};
            }

            // Extremely safe cast for documents list
            final docsVal = profile['documents'];
            if (docsVal is List) {
              _documents = docsVal;
            } else {
              _documents = [];
            }

            // Initialize controllers
            _nameController.text = _userData['full_name']?.toString() ?? '';
            _emailController.text = _userData['email']?.toString() ?? '';
            final rawPhone = _userData['phone_number']?.toString() ?? '';
            if (rawPhone.startsWith('REG-') || rawPhone.startsWith('G-')) {
              _phoneController.text = '';
            } else {
              _phoneController.text = rawPhone;
            }
            _phone2Controller.text = _userData['phone_number_2']?.toString() ?? '';
            _nicController.text = _userData['national_id']?.toString() ?? '';
            _addressController.text = _userData['address']?.toString() ?? '';
            _cityController.text = _userData['city']?.toString() ?? '';
            _districtController.text = _userData['district']?.toString() ?? '';
            _provinceController.text = _userData['province']?.toString() ?? '';

            _latitude = _userData['latitude'] != null ? double.tryParse(_userData['latitude'].toString()) : null;
            _longitude = _userData['longitude'] != null ? double.tryParse(_userData['longitude'].toString()) : null;

            // Normalize and initialize province and district dropdown selections
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
                  } else {
                    _selectedDistrict = null;
                    _districtController.text = '';
                  }
                } else {
                  _selectedDistrict = null;
                  _districtController.text = '';
                }
              } else {
                _selectedProvince = null;
                _provinceController.text = '';
                _selectedDistrict = null;
                _districtController.text = '';
              }
            } else {
              _selectedProvince = null;
              _provinceController.text = '';
              _selectedDistrict = null;
              _districtController.text = '';
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

  Future<void> _pickFile(bool isFront) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          if (isFront) {
            _frontImagePath = result.files.single.path;
          } else {
            _backImagePath = result.files.single.path;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
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
        'phone_number': _phoneController.text.trim().isEmpty
            ? (_userData['phone_number']?.toString() ?? '')
            : _phoneController.text.trim(),
        'phone_number_2': _phone2Controller.text.trim(),
        'national_id': _nicController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'province': _provinceController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
      };

      if (_frontImagePath != null) {
        data['document_type'] = _selectedDocType;
      }

      final result = await ApiService.updateBuyerProfile(
        data,
        frontImagePath: _frontImagePath,
        backImagePath: _backImagePath,
        profilePicturePath: _profilePicPath,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          if (result['success'] == true) {
            _successMessage = 'Profile updated successfully!';
            _isEditing = false;
            _frontImagePath = null;
            _backImagePath = null;
            _profilePicPath = null;
            
            final profile = result['profile'] ?? {};
            
            // Extremely safe cast for user map
            final userVal = profile['user'];
            if (userVal is Map<String, dynamic>) {
              _userData = userVal;
            } else if (userVal is Map) {
              _userData = Map<String, dynamic>.from(userVal);
            } else {
              _userData = {};
            }

            // Extremely safe cast for documents list
            final docsVal = profile['documents'];
            if (docsVal is List) {
              _documents = docsVal;
            } else {
              _documents = [];
            }

            // Sync coordinates
            _latitude = _userData['latitude'] != null ? double.tryParse(_userData['latitude'].toString()) : null;
            _longitude = _userData['longitude'] != null ? double.tryParse(_userData['longitude'].toString()) : null;

            // Sync dropdowns with saved profile data
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
            if (result['errors'] != null && result['errors'] is Map) {
              final errorsMap = result['errors'] as Map<String, dynamic>;
              final buffer = StringBuffer();
              errorsMap.forEach((key, value) {
                if (value is List) {
                  buffer.writeln('${key}: ${value.join(', ')}');
                } else {
                  buffer.writeln('${key}: ${value}');
                }
              });
              _errorMessage = buffer.toString().trim();
            } else {
              _errorMessage = result['message'] ?? 'Failed to save changes.';
            }
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

  int _countUncompletedFields() {
    int count = 0;
    if (_emailController.text.trim().isEmpty) count++;
    if (_phone2Controller.text.trim().isEmpty) count++;
    if (_nicController.text.trim().isEmpty) count++;
    if (_addressController.text.trim().isEmpty) count++;
    if (_cityController.text.trim().isEmpty) count++;
    if (_districtController.text.trim().isEmpty) count++;
    if (_provinceController.text.trim().isEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    try {
      final uncompletedCount = _countUncompletedFields();
      final isVerified = _userData is Map ? _userData['is_verified'] == true : false;
      final hasPendingDoc = _documents.any((doc) => doc is Map && doc['verification_status'] == 'pending');
      final hasRejectedDoc = _documents.any((doc) => doc is Map && doc['verification_status'] == 'rejected');
      final verificationDoc = (_documents.isNotEmpty && _documents.first is Map) ? _documents.first : null;
      final String? docStatus = verificationDoc is Map ? verificationDoc['verification_status'] : null;

      String statusText = 'Not Verified';
      Color statusColor = const Color(0xFF757575);
      IconData statusIcon = Icons.error_outline_rounded;
      String statusDesc = 'Submit details and verification documents below to authenticate your account.';

      if (isVerified) {
        statusText = 'Verified Customer';
        statusColor = AppTheme.deepLeafGreen;
        statusIcon = Icons.verified_rounded;
        statusDesc = 'Your profile is fully verified. Enjoy unrestricted trading access!';
      } else if (hasPendingDoc) {
        statusText = 'Verification Pending';
        statusColor = AppTheme.accentGold;
        statusIcon = Icons.hourglass_empty_rounded;
        statusDesc = 'Your documents have been submitted and are undergoing admin authentication review.';
      } else if (hasRejectedDoc) {
        statusText = 'Verification Rejected';
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusDesc = 'Your verification document was rejected. Please review the reason below and resubmit.';
      }

      final bool showUploadForm = !isVerified && (verificationDoc == null || docStatus == 'rejected');

      if (!_isEditing) {
        return Scaffold(
          backgroundColor: AppTheme.softGray,
          appBar: AppBar(
            title: const Text(
              'Customer Profile Settings',
              style: TextStyle(
                color: AppTheme.darkGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkGreen, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppTheme.darkGreen),
                onPressed: () => setState(() => _isEditing = true),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
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
                                child: _userData['profile_picture_path'] != null
                                    ? Image.network(
                                        ApiService.fileUrl(_userData['profile_picture_path']) ?? '',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                                      )
                                    : _buildDefaultAvatar(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _nameController.text.isNotEmpty ? _nameController.text : 'Customer Account',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_phoneController.text.isEmpty || _phoneController.text.startsWith("REG-") || _phoneController.text.startsWith("G-")) ? "No Phone" : _phoneController.text} | ${_emailController.text.isNotEmpty ? _emailController.text : "No Email"}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) _buildAlertCard(_errorMessage!, Colors.red),
                      if (_successMessage != null) _buildAlertCard(_successMessage!, AppTheme.deepLeafGreen),
                      if (uncompletedCount > 0 && !isVerified)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_rounded, color: Color(0xFFE65100), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Complete the remaining $uncompletedCount profile details to enable account verification.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildMenuTile(
                        icon: Icons.badge_outlined,
                        iconColor: const Color(0xFF2E7D32),
                        iconBgColor: const Color(0xFFE8F5E9),
                        title: 'Personal Details',
                        subtitle: 'Name, email, phone numbers & national ID',
                        onTap: _showPersonalDetailsSheet,
                      ),
                      _buildMenuTile(
                        icon: Icons.map_rounded,
                        iconColor: const Color(0xFF1565C0),
                        iconBgColor: const Color(0xFFE3F2FD),
                        title: 'Address & Coordinates Map',
                        subtitle: 'Manage home/business address & location coordinate settings',
                        onTap: _showAddressLocationSheet,
                      ),
                      _buildMenuTile(
                        icon: Icons.assignment_turned_in_rounded,
                        iconColor: const Color(0xFF7B1FA2),
                        iconBgColor: const Color(0xFFF3E5F5),
                        title: 'Verification Documents',
                        subtitle: 'Manage driving license, passport or national ID uploads',
                        onTap: _showDocumentsSheet,
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                          label: const Text(
                            'Edit Profile Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await ApiService.logout();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                          label: const Text(
                            'Logout Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      }

      return Scaffold(
        backgroundColor: AppTheme.softGray,
        appBar: AppBar(
          title: const Text(
            'Edit Profile Settings',
            style: TextStyle(
              color: AppTheme.darkGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.darkGreen, size: 20),
            onPressed: () => setState(() => _isEditing = false),
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
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
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
                                if (hasRejectedDoc && verificationDoc is Map && verificationDoc['rejection_reason'] != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Reason: ${verificationDoc['rejection_reason']}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFC62828),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

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

                    // Uncompleted Fields Banner
                    if (uncompletedCount > 0 && !isVerified)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_rounded, color: Color(0xFFE65100), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You have $uncompletedCount uncompleted profile details. Fill them in to get verified!',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Messages
                    if (_errorMessage != null) _buildAlertCard(_errorMessage!, Colors.red),
                    if (_successMessage != null) _buildAlertCard(_successMessage!, AppTheme.deepLeafGreen),



                    // Form details card
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
                            'Personal Details',
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
                          
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F1F1)),
                          const SizedBox(height: 16),
                          const Text(
                            'Address & Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField('Home/Business Address', _addressController, Icons.home_rounded),
                          _buildInputField('City', _cityController, Icons.location_city_rounded),
                          
                          // Google Map & Location Section (Aligned with Farmer Dashboard pattern)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.map_rounded, color: AppTheme.deepLeafGreen, size: 22),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Google Map Location',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _openLocationPicker,
                                      icon: const Icon(Icons.search_rounded, size: 16, color: AppTheme.deepLeafGreen),
                                      label: const Text('Pick/Search', style: TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12, fontWeight: FontWeight.bold)),
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
                                      label: const Text('Current', style: TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12, fontWeight: FontWeight.bold)),
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
                                      border: Border.all(color: Colors.grey[200] ?? Colors.grey),
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
                                                markerId: const MarkerId('buyer_loc'),
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
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.deepLeafGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _buildDropdownField(
                            label: 'Province',
                            value: _selectedProvince,
                            items: _provinceDistricts.keys.toList(),
                            icon: Icons.explore_rounded,
                            hint: 'Select Province',
                            onChanged: (val) {
                              setState(() {
                                _selectedProvince = val;
                                _provinceController.text = val ?? '';
                                
                                // Reset district when province changes
                                _selectedDistrict = null;
                                _districtController.text = '';
                              });
                            },
                          ),
                          if (_selectedProvince != null)
                            _buildDropdownField(
                              label: 'District',
                              value: _selectedDistrict,
                              items: _provinceDistricts[_selectedProvince] ?? [],
                              icon: Icons.map_rounded,
                              hint: 'Select District',
                              onChanged: (val) {
                                setState(() {
                                  _selectedDistrict = val;
                                  _districtController.text = val ?? '';
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verification Documents Section
                    // Uploaded Verification Document Info Card
                    if (verificationDoc is Map) ...[
                      Container(
                        width: double.infinity,
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
                              'Uploaded Verification Document',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 14),
                            
                            // Display details of uploaded doc
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFEFEFEF)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Document Type',
                                        style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '${verificationDoc['document_type']}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Status',
                                        style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                      ),
                                      _buildStatusChip(docStatus ?? 'pending'),
                                    ],
                                  ),
                                  if (docStatus == 'rejected' && verificationDoc['rejection_reason'] != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'Rejection Reason:',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE65100)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${verificationDoc['rejection_reason']}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFFBF360C), fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Display Preview of Uploaded images if available
                            Row(
                              children: [
                                if (verificationDoc['front_image_path'] != null)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const Text(
                                          'Front Image',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            ApiService.fileUrl(verificationDoc['front_image_path']) ?? '',
                                            height: 110,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildPlaceholderDocPreview(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (verificationDoc['back_image_path'] != null) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const Text(
                                          'Back Image',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            ApiService.fileUrl(verificationDoc['back_image_path']) ?? '',
                                            height: 110,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildPlaceholderDocPreview(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Upload Verification Document Input Section (Shown only if not verified and either no doc uploaded or rejected)
                    if (showUploadForm) ...[
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
                            Text(
                              docStatus == 'rejected' ? 'Resubmit Verification Document' : 'Upload Verification Document',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              docStatus == 'rejected'
                                  ? 'Upload fresh document images to replace the rejected document.'
                                  : 'Provide document images to start authentication process.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 16),

                            // Doc Type Dropdown
                            DropdownButtonFormField<String>(
                              value: ['National ID', 'Driving License'].contains(_selectedDocType)
                                  ? _selectedDocType
                                  : 'National ID',
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Document Type',
                                filled: true,
                                fillColor: const Color(0xFFFAFAFA),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: ['National ID', 'Driving License']
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedDocType = val);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Front Image picker
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDocPickerCard(
                                    'Front Page Image',
                                    _frontImagePath,
                                    () => _pickFile(true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDocPickerCard(
                                    'Back Page Image (Optional)',
                                    _backImagePath,
                                    () => _pickFile(false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

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
                            : Text(
                                !showUploadForm
                                    ? 'Save Profile Changes'
                                    : (verificationDoc != null && docStatus == 'rejected'
                                        ? 'Resubmit & Save Changes'
                                        : 'Save Profile & Verify'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      );
    } catch (e, stack) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F4),
        appBar: AppBar(
          title: const Text('Customer Profile Settings'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rendering Diagnostic Panel',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'A layout or runtime exception was caught during rendering:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.15)),
                  ),
                  child: Text(
                    '$e',
                    style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Stack Trace:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '$stack',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _loadProfile();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Reloading Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepLeafGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
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
            borderSide: BorderSide(color: Colors.grey[200] ?? Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200] ?? Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.deepLeafGreen, width: 2),
          ),
        ),
      ),
    );
  }

  String _formatDropdownValue(String value) {
    if (value.isEmpty) return '';
    return value
        .split('_')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
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
            borderSide: BorderSide(color: Colors.grey[200] ?? Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200] ?? Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.deepLeafGreen, width: 2),
          ),
        ),
        items: items.map((t) => DropdownMenuItem(value: t, child: Text(_formatDropdownValue(t)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDocPickerCard(String title, String? path, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300] ?? Colors.grey, width: 1.5, style: BorderStyle.solid),
        ),
        child: path != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(path), fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.deepLeafGreen, size: 32),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'approved':
        color = AppTheme.deepLeafGreen;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'pending':
      default:
        color = AppTheme.accentGold;
        label = 'Pending';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildPlaceholderDocPreview() {
    return Container(
      height: 100,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Icon(Icons.description_rounded, color: Colors.grey[400], size: 36),
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
          title: 'Pick Business Location',
        ),
      ),
    );

    if (!mounted || picked == null || picked['latitude'] == null || picked['longitude'] == null) return;
    _setLocation(LatLng(picked['latitude']!, picked['longitude']!));
  }

  void _showPersonalDetailsSheet() {
    _showModalSheet(
      title: 'Personal Details',
      children: [
        _buildSheetDetailRow(Icons.person_rounded, 'Full Name', _nameController.text.isNotEmpty ? _nameController.text : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.email_rounded, 'Email Address', _emailController.text.isNotEmpty ? _emailController.text : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.phone_android_rounded, 'Primary Phone', _phoneController.text.isNotEmpty ? _phoneController.text : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.phone_rounded, 'Secondary Phone', _phone2Controller.text.isNotEmpty ? _phone2Controller.text : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.credit_card_rounded, 'National ID (NIC)', _nicController.text.isNotEmpty ? _nicController.text : '-'),
      ],
    );
  }

  void _showAddressLocationSheet() {
    final LatLng pinTarget = _latitude != null && _longitude != null
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(6.9271, 79.8612);

    _showModalSheet(
      title: 'Address & Pinned Map',
      children: [
        _buildSheetDetailRow(Icons.home_rounded, 'Street Address', _addressController.text.isNotEmpty ? _addressController.text : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.location_city_rounded, 'City', _cityController.text.isNotEmpty ? _cityController.text : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.explore_rounded, 'Province', _selectedProvince ?? '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.map_rounded, 'District', _selectedDistrict ?? '-'),
        const SizedBox(height: 16),
        const Text(
          'Pinned Location Coordinates',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200] ?? Colors.grey),
            ),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: pinTarget, zoom: _latitude != null ? 15 : 7),
              markers: _latitude != null && _longitude != null
                  ? {Marker(markerId: const MarkerId('buyer_loc_read'), position: pinTarget)}
                  : {},
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
        ),
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Pinned: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 11, color: AppTheme.deepLeafGreen, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  void _showDocumentsSheet() {
    final verificationDoc = (_documents.isNotEmpty && _documents.first is Map) ? _documents.first : null;
    final String? docStatus = verificationDoc is Map ? verificationDoc['verification_status'] : null;

    _showModalSheet(
      title: 'Verification Documents',
      children: [
        if (verificationDoc == null) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No verification documents submitted yet.',
                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ] else ...[
          _buildSheetDetailRow(
            Icons.assignment_ind_rounded,
            'Document Type',
            (verificationDoc['document_type'] ?? '').toString().toUpperCase().replaceAll('_', ' '),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Verification Status', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (docStatus == 'verified' ? AppTheme.deepLeafGreen : (docStatus == 'pending' ? AppTheme.accentGold : Colors.red)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (verificationDoc['verification_status'] ?? '').toString().toUpperCase(),
                  style: TextStyle(
                    color: docStatus == 'verified' ? AppTheme.deepLeafGreen : (docStatus == 'pending' ? AppTheme.accentGold : Colors.red),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (docStatus == 'rejected' && verificationDoc['rejection_reason'] != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rejection Reason:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  Text(
                    '${verificationDoc['rejection_reason']}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFC62828), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (verificationDoc['front_image_path'] != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Front Image',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ApiService.fileUrl(verificationDoc['front_image_path']) ?? '',
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderDocPreview(),
                        ),
                      ),
                    ],
                  ),
                ),
              if (verificationDoc['back_image_path'] != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Back Image',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ApiService.fileUrl(verificationDoc['back_image_path']) ?? '',
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderDocPreview(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }



  Widget _buildSheetDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF94A3B8),
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showModalSheet({
    required String title,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
