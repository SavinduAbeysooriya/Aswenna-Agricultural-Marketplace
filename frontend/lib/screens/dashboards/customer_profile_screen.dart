import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/map_location_picker.dart';
import 'package:aswenna/screens/login_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocating = false;
  String? _errorMessage;
  String? _successMessage;

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

  double? _latitude;
  double? _longitude;
  GoogleMapController? _mapController;

  // Profile data & documents state
  Map<String, dynamic> _userData = {};
  List<dynamic> _documents = [];

  // Verification Documents Selection State
  String _selectedDocType = 'national_id';
  String? _frontImagePath;
  String? _backImagePath;
  String? _profilePicPath;

  // Sri Lanka Provinces and Districts Map for Dropdowns
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

  String? _selectedProvince;
  String? _selectedDistrict;

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
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.getBuyerProfile();
      if (response['success'] == true && response['profile'] != null) {
        final profile = response['profile'];
        _userData = Map<String, dynamic>.from(profile['user'] ?? {});
        _documents = List<dynamic>.from(profile['documents'] ?? []);

        setState(() {
          _nameController.text = (_userData['full_name'] ?? '').toString();
          _emailController.text = (_userData['email'] ?? '').toString();
          _phoneController.text = (_userData['phone_number'] ?? '').toString();
          _phone2Controller.text = (_userData['phone_number_2'] ?? '').toString();
          _nicController.text = (_userData['national_id'] ?? '').toString();
          _addressController.text = (_userData['address'] ?? '').toString();
          _cityController.text = (_userData['city'] ?? '').toString();
          _districtController.text = (_userData['district'] ?? '').toString();
          _provinceController.text = (_userData['province'] ?? '').toString();
          
          _latitude = _userData['latitude'] != null ? double.tryParse(_userData['latitude'].toString()) : null;
          _longitude = _userData['longitude'] != null ? double.tryParse(_userData['longitude'].toString()) : null;

          // Set province and district dropdown selection if valid
          final loadedProvince = _userData['province']?.toString().trim();
          if (loadedProvince != null && loadedProvince.isNotEmpty) {
            final matchedProvince = _provinceDistricts.keys.firstWhere(
              (p) => p.toLowerCase() == loadedProvince.toLowerCase(),
              orElse: () => '',
            );
            if (matchedProvince.isNotEmpty) {
              _selectedProvince = matchedProvince;
              
              final loadedDistrict = _userData['district']?.toString().trim();
              if (loadedDistrict != null && loadedDistrict.isNotEmpty) {
                final matchedDistrict = _provinceDistricts[matchedProvince]!.firstWhere(
                  (d) => d.toLowerCase() == loadedDistrict.toLowerCase(),
                  orElse: () => '',
                );
                if (matchedDistrict.isNotEmpty) {
                  _selectedDistrict = matchedDistrict;
                }
              }
            }
          }
        });

        if (_latitude != null && _longitude != null) {
          try {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(_latitude!, _longitude!), 15),
            );
          } catch (e) {
            // Fail silently if map is disposed or not ready
          }
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load profile details.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _useGPS() async {
    if (!mounted) return;
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable device location services.')),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are required.')),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        _updateCoordinates(LatLng(position.latitude, position.longitude));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to acquire location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _openMapPicker() async {
    final picked = await Navigator.of(context).push<Map<String, double>>(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          title: 'Select Delivery Location',
        ),
      ),
    );

    if (picked != null && picked['latitude'] != null && picked['longitude'] != null && mounted) {
      _updateCoordinates(LatLng(picked['latitude']!, picked['longitude']!));
    }
  }

  void _updateCoordinates(LatLng coords) {
    if (!mounted) return;
    setState(() {
      _latitude = coords.latitude;
      _longitude = coords.longitude;
    });
    try {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(coords, 15),
      );
    } catch (e) {
      // Fail silently if map is disposed or not ready
    }
  }

  Future<void> _pickProfilePicture() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: false);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _profilePicPath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking profile picture: $e')));
    }
  }

  Future<void> _pickVerificationDoc(bool isFront) async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: false);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking document photo: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final data = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'phone_number_2': _phone2Controller.text.trim().isEmpty ? null : _phone2Controller.text.trim(),
      'national_id': _nicController.text.trim().isEmpty ? null : _nicController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'province': _provinceController.text.trim(),
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,
      if (_frontImagePath != null) 'document_type': _selectedDocType,
    };

    try {
      final response = await ApiService.updateBuyerProfile(
        data,
        frontImagePath: _frontImagePath,
        backImagePath: _backImagePath,
        profilePicturePath: _profilePicPath,
      );
      if (response['success'] == true) {
        setState(() {
          _successMessage = 'Profile updated successfully!';
          _frontImagePath = null;
          _backImagePath = null;
          _profilePicPath = null;
        });
        _loadProfile();
      } else {
        setState(() {
          if (response['errors'] != null && response['errors'] is Map) {
            final errorsMap = response['errors'] as Map<String, dynamic>;
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
            _errorMessage = response['message'] ?? 'Failed to update profile.';
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: $e';
      });
    } finally {
      setState(() => _isSaving = false);
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

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppTheme.lightMint,
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: AppTheme.deepLeafGreen, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialTarget = _latitude != null && _longitude != null
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(6.9271, 79.8612);

    final uncompletedCount = _countUncompletedFields();
    final isVerified = _userData['is_verified'] == true;
    final hasPendingDoc = _documents.any((doc) => doc['verification_status'] == 'pending');
    final hasRejectedDoc = _documents.any((doc) => doc['verification_status'] == 'rejected');
    final verificationDoc = _documents.isNotEmpty ? _documents.first : null;
    final String? docStatus = verificationDoc != null ? verificationDoc['verification_status'] : null;

    String statusText = 'Not Verified';
    Color statusColor = const Color(0xFF757575);
    IconData statusIcon = Icons.error_outline_rounded;
    String statusDesc = 'Submit verification documents below to authenticate your customer account.';

    if (isVerified) {
      statusText = 'Verified Customer';
      statusColor = AppTheme.deepLeafGreen;
      statusIcon = Icons.verified_rounded;
      statusDesc = 'Your profile is fully verified. Enjoy secure marketplace delivery services!';
    } else if (hasPendingDoc) {
      statusText = 'Verification Pending';
      statusColor = AppTheme.accentGold;
      statusIcon = Icons.hourglass_empty_rounded;
      statusDesc = 'Your documents are undergoing admin authentication review.';
    } else if (hasRejectedDoc) {
      statusText = 'Verification Rejected';
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
      statusDesc = 'Your document was rejected. Please review the reason below and upload again.';
    }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
          : _isSaving
              ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verification Status Banner
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
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: statusColor),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      statusDesc,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4, fontWeight: FontWeight.w500),
                                    ),
                                    if (hasRejectedDoc && verificationDoc != null && verificationDoc['rejection_reason'] != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                        child: Text(
                                          "Reason: ${verificationDoc['rejection_reason']}",
                                          style: const TextStyle(fontSize: 11, color: Color(0xFFC62828), fontWeight: FontWeight.w700),
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

                        // Profile Picture upload
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
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16)],
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
                                  decoration: const BoxDecoration(color: AppTheme.deepLeafGreen, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Alerts
                        if (_errorMessage != null) _buildAlertCard(_errorMessage!, Colors.red),
                        if (_successMessage != null) _buildAlertCard(_successMessage!, AppTheme.deepLeafGreen),

                        // Uncompleted Info Alert
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
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Profile Details Section Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Personal Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              const SizedBox(height: 16),
                              _buildInputField('Full Name *', _nameController, Icons.person_rounded, validator: (v) => v!.isEmpty ? 'Required' : null),
                              _buildInputField('Email Address', _emailController, Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                              _buildInputField('Primary Phone *', _phoneController, Icons.phone_android_rounded, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
                              _buildInputField('Secondary Phone', _phone2Controller, Icons.phone_rounded, keyboardType: TextInputType.phone),
                              _buildInputField('National ID (NIC) / ID Number', _nicController, Icons.credit_card_rounded),
                              
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFF1F1F1)),
                              const SizedBox(height: 16),
                              const Text('Address & Collection site', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              const SizedBox(height: 16),
                              _buildInputField('Street Address *', _addressController, Icons.home_rounded, validator: (v) => v!.isEmpty ? 'Required' : null),
                              _buildInputField('City *', _cityController, Icons.location_city_rounded, validator: (v) => v!.isEmpty ? 'Required' : null),

                              // Map Selection
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
                                          child: Text('Map Delivery Coordinates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                        ),
                                        TextButton.icon(
                                          onPressed: _openMapPicker,
                                          icon: const Icon(Icons.search_rounded, size: 16, color: AppTheme.deepLeafGreen),
                                          label: const Text('Pick Map', style: TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        TextButton.icon(
                                          onPressed: _isLocating ? null : _useGPS,
                                          icon: _isLocating
                                              ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.deepLeafGreen))
                                              : const Icon(Icons.my_location_rounded, size: 16, color: AppTheme.deepLeafGreen),
                                          label: const Text('GPS', style: TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        height: 180,
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                                        child: GoogleMap(
                                          initialCameraPosition: CameraPosition(target: initialTarget, zoom: _latitude != null ? 15 : 7),
                                          markers: _latitude != null && _longitude != null
                                              ? {Marker(markerId: const MarkerId('buyer_loc'), position: LatLng(_latitude!, _longitude!))}
                                              : {},
                                          onMapCreated: (controller) {
                                            _mapController = controller;
                                            if (_latitude != null && _longitude != null) {
                                              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(_latitude!, _longitude!), 15));
                                            }
                                          },
                                          onTap: _updateCoordinates,
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
                                ),
                              ),

                              _buildDropdownField(
                                label: 'Province *',
                                value: _selectedProvince,
                                items: _provinceDistricts.keys.toList(),
                                icon: Icons.explore_rounded,
                                hint: 'Select Province',
                                onChanged: (val) {
                                  setState(() {
                                    _selectedProvince = val;
                                    _provinceController.text = val ?? '';
                                    _selectedDistrict = null;
                                    _districtController.text = '';
                                  });
                                },
                              ),
                              if (_selectedProvince != null)
                                _buildDropdownField(
                                  label: 'District *',
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

                        // Identity documents upload
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Identity Verification Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              const SizedBox(height: 14),
                              
                              if (verificationDoc != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 16),
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
                                          const Text('Document Type', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                                          Text(
                                            (verificationDoc['document_type'] ?? '').toString().toUpperCase().replaceAll('_', ' '),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Status', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text(
                                              (verificationDoc['verification_status'] ?? '').toString().toUpperCase(),
                                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (!isVerified && (verificationDoc == null || docStatus == 'rejected')) ...[
                                _buildDropdownField(
                                  label: 'Select Document to Upload',
                                  value: _selectedDocType,
                                  items: ['national_id', 'driving_license', 'passport'],
                                  icon: Icons.assignment_ind_rounded,
                                  hint: 'Select document type',
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedDocType = val);
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                                        onPressed: () => _pickVerificationDoc(true),
                                        icon: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.deepLeafGreen),
                                        label: Text(_frontImagePath == null ? 'Front Image' : 'Front Selected', style: const TextStyle(color: AppTheme.darkGreen, fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                                        onPressed: () => _pickVerificationDoc(false),
                                        icon: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.deepLeafGreen),
                                        label: Text(_backImagePath == null ? 'Back Image (Opt)' : 'Back Selected', style: const TextStyle(color: AppTheme.darkGreen, fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

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
                                    !( !isVerified && (verificationDoc == null || docStatus == 'rejected') )
                                        ? 'Save Profile Changes'
                                        : (verificationDoc != null && docStatus == 'rejected'
                                            ? 'Resubmit & Save Changes'
                                            : 'Save Profile & Verify'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Logout Button ──────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmLogout(context),
                            icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                            label: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(90, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String msg, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(msg, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text, FormFieldValidator<String>? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.deepLeafGreen, size: 20),
              fillColor: const Color(0xFFFAFAFA),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({required String label, required String? value, required List<String> items, required IconData icon, required String hint, required ValueChanged<String?> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text(hint, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                dropdownColor: AppTheme.pureWhite,
                onChanged: onChanged,
                items: items
                    .map((val) => DropdownMenuItem(
                          value: val,
                          child: Text(
                            val.toUpperCase().replaceAll('_', ' '),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
