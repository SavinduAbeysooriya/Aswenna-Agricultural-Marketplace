import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getBuyerProfile();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          final profile = result['profile'] ?? {};
          _userData = profile['user'] ?? {};
          _documents = profile['documents'] ?? [];

          // Initialize controllers
          _nameController.text = _userData['full_name'] ?? '';
          _emailController.text = _userData['email'] ?? '';
          _phoneController.text = _userData['phone_number'] ?? '';
          _phone2Controller.text = _userData['phone_number_2'] ?? '';
          _nicController.text = _userData['national_id'] ?? '';
          _addressController.text = _userData['address'] ?? '';
          _cityController.text = _userData['city'] ?? '';
          _districtController.text = _userData['district'] ?? '';
          _provinceController.text = _userData['province'] ?? '';

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
          _frontImagePath = null;
          _backImagePath = null;
          _profilePicPath = null;
          
          final profile = result['profile'] ?? {};
          _userData = profile['user'] ?? {};
          _documents = profile['documents'] ?? [];

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
          _errorMessage = result['message'] ?? 'Failed to save changes.';
        }
      });
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
    final uncompletedCount = _countUncompletedFields();
    final isVerified = _userData['is_verified'] == true;
    final hasPendingDoc = _documents.any((doc) => doc['verification_status'] == 'pending');
    final hasRejectedDoc = _documents.any((doc) => doc['verification_status'] == 'rejected');
    final verificationDoc = _documents.isNotEmpty ? _documents.first : null;
    final String? docStatus = verificationDoc?['verification_status'];

    String statusText = 'Not Verified';
    Color statusColor = const Color(0xFF757575);
    IconData statusIcon = Icons.error_outline_rounded;
    String statusDesc = 'Submit details and verification documents below to authenticate your account.';

    if (isVerified) {
      statusText = 'Verified Buyer';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text('Buyer Profile Settings'),
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
                              if (hasRejectedDoc && verificationDoc?['rejection_reason'] != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Reason: ${verificationDoc?['rejection_reason']}",
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
                  if (verificationDoc != null) ...[
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                          width: double.infinity,
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                          width: double.infinity,
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

  Widget _buildDocPickerCard(String title, String? path, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 1.5, style: BorderStyle.solid),
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
}
