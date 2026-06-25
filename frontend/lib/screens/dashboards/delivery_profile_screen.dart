import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/map_location_picker.dart';
import 'package:aswenna/screens/login_screen.dart';

class DeliveryProfileScreen extends StatefulWidget {
  const DeliveryProfileScreen({super.key});

  @override
  State<DeliveryProfileScreen> createState() => _DeliveryProfileScreenState();
}

class _DeliveryProfileScreenState extends State<DeliveryProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocating = false;
  bool _isEditing = false;
  String? _errorMessage;
  String? _successMessage;

  // Controllers - Personal
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _nicController = TextEditingController();

  // Controllers - Location
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();

  // Controllers - Vehicle Details
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _maxWeightController = TextEditingController();

  // Selected vehicle type
  String? _selectedVehicleType;
  final List<String> _vehicleTypes = [
    'motorcycle',
    'threewheeler',
    'van',
    'small_truck',
    'medium_truck',
    'large_truck',
  ];

  double? _latitude;
  double? _longitude;
  GoogleMapController? _mapController;

  // Profile data & documents state
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _verificationData = {};
  List<dynamic> _documents = [];

  // Expiry Dates
  DateTime? _licenseExpiry;
  DateTime? _insuranceExpiry;
  DateTime? _revenueLicenseExpiry;

  // Image Paths for uploading
  String? _profilePicPath;
  String? _licenseFrontPath;
  String? _licenseBackPath;
  String? _insuranceImagePath;
  String? _revenueLicenseImagePath;
  String? _vehicleFrontImagePath;
  String? _vehicleBackImagePath;
  List<String> _vehicleOtherImagesPaths = [];
  List<String> _existingOtherImagesUrls = [];

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
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleColorController.dispose();
    _registrationNumberController.dispose();
    _maxWeightController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.getDeliveryPartnerProfile();
      if (response['success'] == true && response['profile'] != null) {
        final profile = response['profile'];
        _userData = Map<String, dynamic>.from(profile['user'] ?? {});
        _verificationData = Map<String, dynamic>.from(profile['verification_data'] ?? {});
        _documents = List<dynamic>.from(profile['documents'] ?? []);

        setState(() {
          // Personal Details
          _nameController.text = (_userData['full_name'] ?? '').toString();
          _emailController.text = (_userData['email'] ?? '').toString();
          _phoneController.text = (_userData['phone_number'] ?? '').toString();
          _phone2Controller.text = (_userData['phone_number_2'] ?? '').toString();
          _nicController.text = (_userData['national_id'] ?? '').toString();

          // Location
          _addressController.text = (_userData['address'] ?? '').toString();
          _cityController.text = (_userData['city'] ?? '').toString();
          _districtController.text = (_userData['district'] ?? '').toString();
          _provinceController.text = (_userData['province'] ?? '').toString();
          
          _latitude = _userData['latitude'] != null ? double.tryParse(_userData['latitude'].toString()) : null;
          _longitude = _userData['longitude'] != null ? double.tryParse(_userData['longitude'].toString()) : null;

          // Vehicle Specs
          _vehicleMakeController.text = (_verificationData['vehicle_make'] ?? '').toString();
          _vehicleModelController.text = (_verificationData['model'] ?? '').toString();
          _vehicleYearController.text = (_verificationData['year'] ?? '').toString();
          _vehicleColorController.text = (_verificationData['color'] ?? '').toString();
          _registrationNumberController.text = (_verificationData['registration_number'] ?? '').toString();
          _maxWeightController.text = (_verificationData['max_weight'] ?? '').toString();

          final loadedVehicleType = _verificationData['vehicle_type']?.toString();
          if (loadedVehicleType != null && _vehicleTypes.contains(loadedVehicleType)) {
            _selectedVehicleType = loadedVehicleType;
          }

          // Dates
          if (_verificationData['driving_license_expiry_date'] != null) {
            _licenseExpiry = DateTime.tryParse(_verificationData['driving_license_expiry_date'].toString());
          }
          if (_verificationData['insurance_expiry'] != null) {
            _insuranceExpiry = DateTime.tryParse(_verificationData['insurance_expiry'].toString());
          }
          if (_verificationData['revenue_license_expiry'] != null) {
            _revenueLicenseExpiry = DateTime.tryParse(_verificationData['revenue_license_expiry'].toString());
          }

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
          
          // Existing other images URLs
          _existingOtherImagesUrls = [];
          var otherUrls = _verificationData['vehicle_other_images_urls'];
          var otherRaw = _verificationData['vehicle_other_images'];
          List<dynamic>? rawList;
          if (otherUrls != null && otherUrls is List) {
            rawList = otherUrls;
          } else if (otherRaw != null) {
            if (otherRaw is List) {
              rawList = otherRaw;
            } else if (otherRaw is String && otherRaw.trim().isNotEmpty) {
              try {
                final decoded = jsonDecode(otherRaw);
                if (decoded is List) {
                  rawList = decoded;
                }
              } catch (_) {}
            }
          }
          if (rawList != null) {
            for (final item in rawList) {
              final resolvedUrl = ApiService.fileUrl(item.toString());
              if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
                _existingOtherImagesUrls.add(resolvedUrl);
              }
            }
          }
        });

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
          title: 'Select Base Location',
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
      // Fail silently if map is disposed or controller not ready
    }
  }

  Future<void> _pickImage(String type) async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: false);
      if (result != null && result.files.single.path != null) {
        setState(() {
          switch (type) {
            case 'profile':
              _profilePicPath = result.files.single.path;
              break;
            case 'license_front':
              _licenseFrontPath = result.files.single.path;
              break;
            case 'license_back':
              _licenseBackPath = result.files.single.path;
              break;
            case 'insurance':
              _insuranceImagePath = result.files.single.path;
              break;
            case 'revenue_license':
              _revenueLicenseImagePath = result.files.single.path;
              break;
            case 'vehicle_front':
              _vehicleFrontImagePath = result.files.single.path;
              break;
            case 'vehicle_back':
              _vehicleBackImagePath = result.files.single.path;
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking photo: $e')));
    }
  }

  Future<void> _pickOtherImages() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: true);
      if (result != null) {
        final paths = result.files.map((f) => f.path).whereType<String>().toList();
        setState(() {
          _vehicleOtherImagesPaths.addAll(paths);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking other photos: $e')));
    }
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
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
        if (field == 'license') {
          _licenseExpiry = picked;
        } else if (field == 'insurance') {
          _insuranceExpiry = picked;
        } else if (field == 'revenue') {
          _revenueLicenseExpiry = picked;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final String? formattedLicenseExpiry = _licenseExpiry != null
        ? "${_licenseExpiry!.year}-${_licenseExpiry!.month.toString().padLeft(2, '0')}-${_licenseExpiry!.day.toString().padLeft(2, '0')}"
        : null;

    final String? formattedInsuranceExpiry = _insuranceExpiry != null
        ? "${_insuranceExpiry!.year}-${_insuranceExpiry!.month.toString().padLeft(2, '0')}-${_insuranceExpiry!.day.toString().padLeft(2, '0')}"
        : null;

    final String? formattedRevenueExpiry = _revenueLicenseExpiry != null
        ? "${_revenueLicenseExpiry!.year}-${_revenueLicenseExpiry!.month.toString().padLeft(2, '0')}-${_revenueLicenseExpiry!.day.toString().padLeft(2, '0')}"
        : null;

    final data = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'phone_number_2': _phone2Controller.text.trim().isEmpty ? null : _phone2Controller.text.trim(),
      'national_id': _nicController.text.trim().isEmpty ? null : _nicController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'district': _selectedDistrict ?? '',
      'province': _selectedProvince ?? '',
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,

      // Vehicle
      'vehicle_type': _selectedVehicleType ?? '',
      'vehicle_make': _vehicleMakeController.text.trim(),
      'model': _vehicleModelController.text.trim(),
      'year': int.tryParse(_vehicleYearController.text.trim()),
      'color': _vehicleColorController.text.trim(),
      'registration_number': _registrationNumberController.text.trim(),
      'max_weight': double.tryParse(_maxWeightController.text.trim()),

      // Dates
      if (formattedLicenseExpiry != null) 'driving_license_expiry_date': formattedLicenseExpiry,
      if (formattedInsuranceExpiry != null) 'insurance_expiry': formattedInsuranceExpiry,
      if (formattedRevenueExpiry != null) 'revenue_license_expiry': formattedRevenueExpiry,
    };

    try {
      final response = await ApiService.updateDeliveryPartnerProfile(
        data,
        frontImagePath: _licenseFrontPath,
        backImagePath: _licenseBackPath,
        insuranceImagePath: _insuranceImagePath,
        revenueLicenseImagePath: _revenueLicenseImagePath,
        vehicleFrontImagePath: _vehicleFrontImagePath,
        vehicleBackImagePath: _vehicleBackImagePath,
        profilePicturePath: _profilePicPath,
        vehicleOtherImagesPaths: _vehicleOtherImagesPaths,
      );

      if (response['success'] == true) {
        setState(() {
          _successMessage = 'Profile updated successfully!';
          _licenseFrontPath = null;
          _licenseBackPath = null;
          _insuranceImagePath = null;
          _revenueLicenseImagePath = null;
          _vehicleFrontImagePath = null;
          _vehicleBackImagePath = null;
          _profilePicPath = null;
          _vehicleOtherImagesPaths = [];
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

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppTheme.lightMint,
      alignment: Alignment.center,
      child: const Icon(Icons.directions_bike_rounded, color: AppTheme.deepLeafGreen, size: 48),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select Date';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _getVehicleTypeLabel(String val) {
    switch (val) {
      case 'motorcycle': return 'Motorcycle / Scooter';
      case 'threewheeler': return 'Three Wheeler';
      case 'van': return 'Delivery Van';
      case 'small_truck': return 'Small Truck (e.g. Dimo Batta)';
      case 'medium_truck': return 'Medium Cargo Truck';
      case 'large_truck': return 'Large Heavy Truck';
      default: return val;
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialTarget = _latitude != null && _longitude != null
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(6.9271, 79.8612);

    final partnerStatus = _verificationData['status'] ?? 'pending';
    final hasPendingDoc = partnerStatus == 'pending';
    final isVerified = partnerStatus == 'verified';
    final isRejected = partnerStatus == 'rejected';

    String statusText = 'Not Verified';
    Color statusColor = const Color(0xFF757575);
    IconData statusIcon = Icons.error_outline_rounded;
    String statusDesc = 'Submit vehicle details and driving license photo below for verification.';

    if (isVerified) {
      statusText = 'Verified Delivery Partner';
      statusColor = AppTheme.deepLeafGreen;
      statusIcon = Icons.verified_rounded;
      statusDesc = 'Your account is verified. You are authorized to accept and deliver orders!';
    } else if (hasPendingDoc) {
      statusText = 'Verification Pending';
      statusColor = AppTheme.accentGold;
      statusIcon = Icons.hourglass_empty_rounded;
      statusDesc = 'Your verification files are under review by the administrator.';
    } else if (isRejected) {
      statusText = 'Verification Rejected';
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
      statusDesc = 'Reason: ${_verificationData['rejected_reason'] ?? "Documents are invalid or illegible."}';
    }

    final avatarUrl = _userData['profile_picture_path'] != null
        ? ApiService.fileUrl(_userData['profile_picture_path'])
        : null;

    if (!_isEditing) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F4),
        appBar: AppBar(
          title: const Text('Rider Profile Settings', style: TextStyle(color: AppTheme.darkGreen, fontWeight: FontWeight.w900)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
            : SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
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
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),

                    if (_successMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                        child: Text(_successMessage!, style: const TextStyle(color: AppTheme.deepLeafGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),

                    // Avatar Card
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: avatarUrl != null
                                  ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildDefaultAvatar())
                                  : _buildDefaultAvatar(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nameController.text.isNotEmpty ? _nameController.text : 'Rider Account',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_phoneController.text} | ${_emailController.text.isNotEmpty ? _emailController.text : "No Email"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Option tiles
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
                      title: 'Base Location & Map',
                      subtitle: 'Home address, city, district & coordinate map',
                      onTap: _showAddressLocationSheet,
                    ),
                    _buildMenuTile(
                      icon: Icons.directions_car_rounded,
                      iconColor: const Color(0xFFEF6C00),
                      iconBgColor: const Color(0xFFFFF3E0),
                      title: 'Vehicle Specifications',
                      subtitle: 'Type, model, year, color, capacity & registration',
                      onTap: _showVehicleSpecsSheet,
                    ),
                    _buildMenuTile(
                      icon: Icons.folder_zip_rounded,
                      iconColor: const Color(0xFF7B1FA2),
                      iconBgColor: const Color(0xFFF3E5F5),
                      title: 'Verification & Files',
                      subtitle: 'License, insurance, revenue files and status',
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
                          _redirectToLogin();
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
            ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text('Edit Rider Profile', style: TextStyle(color: AppTheme.darkGreen, fontWeight: FontWeight.w900)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          onPressed: () => setState(() => _isEditing = false),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
          : _isSaving
              ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
              : SafeArea(
                  child: SingleChildScrollView(
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
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ),

                        if (_successMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                            child: Text(_successMessage!, style: const TextStyle(color: AppTheme.deepLeafGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),

                        // Avatar Picker Card
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _profilePicPath != null
                                      ? Image.file(File(_profilePicPath!), fit: BoxFit.cover)
                                      : avatarUrl != null
                                          ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildDefaultAvatar())
                                          : _buildDefaultAvatar(),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () => _pickImage('profile'),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.deepLeafGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 1: Personal Details
                        _buildSectionHeader('Personal Details', Icons.person_rounded),
                        _buildCardContainer([
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required.' : null,
                          ),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address (Optional)',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Primary Phone Number',
                            keyboardType: TextInputType.phone,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Phone number is required.' : null,
                          ),
                          _buildTextField(
                            controller: _phone2Controller,
                            label: 'Secondary Phone Number (Optional)',
                            keyboardType: TextInputType.phone,
                          ),
                          _buildTextField(
                            controller: _nicController,
                            label: 'National ID Number (NIC)',
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Section 2: Home/Base Location
                        _buildSectionHeader('Base Area Location', Icons.location_on_rounded),
                        _buildCardContainer([
                          _buildTextField(
                            controller: _addressController,
                            label: 'Home Address',
                            maxLines: 2,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Address is required.' : null,
                          ),
                          _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            validator: (val) => val == null || val.trim().isEmpty ? 'City is required.' : null,
                          ),
                          
                          // Province Dropdown
                          _buildProvinceDropdown(),
                          
                          // District Dropdown
                          _buildDistrictDropdown(),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _useGPS,
                                  icon: _isLocating
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.gps_fixed_rounded, size: 16, color: Colors.white),
                                  label: const Text('Use Current GPS', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.deepLeafGreen,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _openMapPicker,
                                  icon: const Icon(Icons.map_rounded, size: 16, color: AppTheme.deepLeafGreen),
                                  label: const Text('Pick on Map', style: TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.deepLeafGreen),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_latitude != null && _longitude != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Selected Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 140,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(target: initialTarget, zoom: 15),
                                  markers: {
                                    Marker(markerId: const MarkerId('partner_location'), position: initialTarget),
                                  },
                                  onMapCreated: (c) => _mapController = c,
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                ),
                              ),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 24),

                        // Section 3: Driving License
                        _buildSectionHeader('Driving License Verification', Icons.assignment_ind_rounded),
                        _buildCardContainer([
                          const Text(
                            'General Delivery Partner Document Verification (Driving License ONLY)',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          // Date Picker for Expiry
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('License Expiry Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: () => _selectDate(context, 'license'),
                                icon: const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.deepLeafGreen),
                                label: Text(_formatDate(_licenseExpiry), style: const TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildImagePickerRow(
                            label: 'Driving License (Front)',
                            filePath: _licenseFrontPath,
                            existingPath: _documents.isNotEmpty ? _documents.first['front_image_path']?.toString() : null,
                            onPick: () => _pickImage('license_front'),
                          ),
                          const SizedBox(height: 12),
                          _buildImagePickerRow(
                            label: 'Driving License (Back)',
                            filePath: _licenseBackPath,
                            existingPath: _documents.isNotEmpty ? _documents.first['back_image_path']?.toString() : null,
                            onPick: () => _pickImage('license_back'),
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Section 4: Vehicle Details
                        _buildSectionHeader('Vehicle Specifications', Icons.directions_car_rounded),
                        _buildCardContainer([
                          // Vehicle Type Dropdown
                          _buildVehicleTypeDropdown(),

                          _buildTextField(
                            controller: _vehicleMakeController,
                            label: 'Vehicle Manufacturer (e.g. Honda, Bajaj)',
                          ),
                          _buildTextField(
                            controller: _vehicleModelController,
                            label: 'Vehicle Model (e.g. Super Cub, Pulsar)',
                          ),
                          _buildTextField(
                            controller: _vehicleYearController,
                            label: 'Manufacturing Year',
                            keyboardType: TextInputType.number,
                          ),
                          _buildTextField(
                            controller: _vehicleColorController,
                            label: 'Vehicle Color',
                          ),
                          _buildTextField(
                            controller: _registrationNumberController,
                            label: 'Plate Number (Registration Number)',
                          ),
                          _buildTextField(
                            controller: _maxWeightController,
                            label: 'Max Carrying Capacity (kg)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Section 5: Insurance & Revenue License Documents
                        _buildSectionHeader('Vehicle Documents', Icons.folder_zip_rounded),
                        _buildCardContainer([
                          // Insurance Expiry Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Insurance Expiry Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: () => _selectDate(context, 'insurance'),
                                icon: const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.deepLeafGreen),
                                label: Text(_formatDate(_insuranceExpiry), style: const TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          _buildImagePickerRow(
                            label: 'Insurance Document Photo',
                            filePath: _insuranceImagePath,
                            existingPath: _verificationData['insurance_image_path']?.toString(),
                            onPick: () => _pickImage('insurance'),
                          ),
                          const Divider(height: 24, color: AppTheme.softGray),

                          // Revenue License Expiry Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Revenue License Expiry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: () => _selectDate(context, 'revenue'),
                                icon: const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.deepLeafGreen),
                                label: Text(_formatDate(_revenueLicenseExpiry), style: const TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          _buildImagePickerRow(
                            label: 'Revenue License Photo',
                            filePath: _revenueLicenseImagePath,
                            existingPath: _verificationData['revenue_license_image_path']?.toString(),
                            onPick: () => _pickImage('revenue_license'),
                          ),
                          const Divider(height: 24, color: AppTheme.softGray),

                          _buildImagePickerRow(
                            label: 'Vehicle Photo (Front)',
                            filePath: _vehicleFrontImagePath,
                            existingPath: _verificationData['vehicle_front_image']?.toString(),
                            onPick: () => _pickImage('vehicle_front'),
                          ),
                          const SizedBox(height: 12),
                          _buildImagePickerRow(
                            label: 'Vehicle Photo (Back)',
                            filePath: _vehicleBackImagePath,
                            existingPath: _verificationData['vehicle_back_image']?.toString(),
                            onPick: () => _pickImage('vehicle_back'),
                          ),
                          const Divider(height: 24, color: AppTheme.softGray),
                          const Text('Other Vehicle Photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          
                          if (_existingOtherImagesUrls.isNotEmpty || _vehicleOtherImagesPaths.isNotEmpty) ...[
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1,
                              ),
                              itemCount: _existingOtherImagesUrls.length + _vehicleOtherImagesPaths.length,
                              itemBuilder: (context, index) {
                                if (index < _existingOtherImagesUrls.length) {
                                  final url = _existingOtherImagesUrls[index];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(url, fit: BoxFit.cover),
                                  );
                                } else {
                                  final localIndex = index - _existingOtherImagesUrls.length;
                                  final path = _vehicleOtherImagesPaths[localIndex];
                                  return Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(File(path), fit: BoxFit.cover),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _vehicleOtherImagesPaths.removeAt(localIndex);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          ElevatedButton.icon(
                            onPressed: _pickOtherImages,
                            icon: const Icon(Icons.add_photo_alternate_rounded, size: 16, color: AppTheme.deepLeafGreen),
                            label: const Text('Add Other Photos', style: TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.lightMint,
                              foregroundColor: AppTheme.deepLeafGreen,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.deepLeafGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save Profile & Submit Verification',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.deepLeafGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
          floatingLabelStyle: const TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.deepLeafGreen, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildProvinceDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedProvince,
        decoration: InputDecoration(
          labelText: 'Province',
          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
          floatingLabelStyle: const TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        items: _provinceDistricts.keys.map((province) {
          return DropdownMenuItem(
            value: province,
            child: Text(province, style: const TextStyle(fontSize: 13)),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _selectedProvince = val;
            _selectedDistrict = null; // reset district
            _provinceController.text = val ?? '';
            _districtController.text = '';
          });
        },
        validator: (val) => val == null ? 'Province is required.' : null,
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    final districts = _selectedProvince != null ? _provinceDistricts[_selectedProvince]! : <String>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedDistrict,
        disabledHint: Text(_selectedDistrict ?? 'Select province first', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        decoration: InputDecoration(
          labelText: 'District',
          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
          floatingLabelStyle: const TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        items: districts.map((district) {
          return DropdownMenuItem(
            value: district,
            child: Text(district, style: const TextStyle(fontSize: 13)),
          );
        }).toList(),
        onChanged: _selectedProvince == null
            ? null
            : (val) {
                setState(() {
                  _selectedDistrict = val;
                  _districtController.text = val ?? '';
                });
              },
        validator: (val) => val == null ? 'District is required.' : null,
      ),
    );
  }

  Widget _buildVehicleTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedVehicleType,
        decoration: InputDecoration(
          labelText: 'Vehicle Type',
          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
          floatingLabelStyle: const TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        items: _vehicleTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(_getVehicleTypeLabel(type), style: const TextStyle(fontSize: 13)),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _selectedVehicleType = val;
          });
        },
        validator: (val) => val == null ? 'Vehicle type is required.' : null,
      ),
    );
  }

  Widget _buildImagePickerRow({
    required String label,
    required String? filePath,
    required String? existingPath,
    required VoidCallback onPick,
  }) {
    final hasImage = filePath != null || existingPath != null;
    final imageUrl = existingPath != null ? ApiService.fileUrl(existingPath) : null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                filePath != null
                    ? 'Selected: ${filePath.split(Platform.pathSeparator).last}'
                    : existingPath != null
                        ? 'Uploaded File Saved'
                        : 'No image selected',
                style: TextStyle(fontSize: 10, color: hasImage ? AppTheme.deepLeafGreen : Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (imageUrl != null && filePath == null)
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
            ),
          ),
        if (filePath != null)
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(image: FileImage(File(filePath)), fit: BoxFit.cover),
            ),
          ),
        ElevatedButton(
          onPressed: onPick,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightMint,
            foregroundColor: AppTheme.deepLeafGreen,
            elevation: 0,
            minimumSize: const Size(0, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Pick Image', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
        color = AppTheme.deepLeafGreen;
        label = 'Verified';
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
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
      title: 'Base Location Area',
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
                  ? {Marker(markerId: const MarkerId('delivery_loc_read'), position: pinTarget)}
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

  void _showVehicleSpecsSheet() {
    _showModalSheet(
      title: 'Vehicle Specifications',
      children: [
        _buildSheetDetailRow(Icons.directions_car_rounded, 'Vehicle Type', _selectedVehicleType != null ? _getVehicleTypeLabel(_selectedVehicleType!) : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.business_rounded, 'Manufacturer', _vehicleMakeController.text.isNotEmpty ? _vehicleMakeController.text : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.model_training_rounded, 'Model Name', _vehicleModelController.text.isNotEmpty ? _vehicleModelController.text : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.calendar_today_rounded, 'Mfg Year', _vehicleYearController.text.isNotEmpty ? _vehicleYearController.text : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.palette_rounded, 'Vehicle Color', _vehicleColorController.text.isNotEmpty ? _vehicleColorController.text : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.tag_rounded, 'Plate Number', _registrationNumberController.text.isNotEmpty ? _registrationNumberController.text : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.scale_rounded, 'Carrying Capacity', _maxWeightController.text.isNotEmpty ? '${_maxWeightController.text} kg' : '-'),
      ],
    );
  }

  Widget _buildDocPreviewCard(String label, String? remotePath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: remotePath != null
              ? Image.network(
                  ApiService.fileUrl(remotePath) ?? '',
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 110,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28),
                  ),
                )
              : Container(
                  height: 110,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 28),
                ),
        ),
      ],
    );
  }

  void _showDocumentsSheet() {
    final partnerStatus = _verificationData['status'] ?? 'pending';
    final frontImage = _documents.isNotEmpty ? _documents.first['front_image_path']?.toString() : null;
    final backImage = _documents.isNotEmpty ? _documents.first['back_image_path']?.toString() : null;

    _showModalSheet(
      title: 'Verification & Files',
      children: [
        _buildSheetDetailRow(Icons.event_busy_rounded, 'License Expiry', _licenseExpiry != null ? _formatDate(_licenseExpiry) : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.event_busy_rounded, 'Insurance Expiry', _insuranceExpiry != null ? _formatDate(_insuranceExpiry) : '-'),
        const SizedBox(height: 12),
        _buildSheetDetailRow(Icons.event_busy_rounded, 'Revenue Expiry', _revenueLicenseExpiry != null ? _formatDate(_revenueLicenseExpiry) : '-'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Verification Status', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
            _buildStatusChip(partnerStatus),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Document Proof Previews', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildDocPreviewCard('License Front', frontImage)),
            const SizedBox(width: 12),
            Expanded(child: _buildDocPreviewCard('License Back', backImage)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDocPreviewCard('Insurance Image', _verificationData['insurance_image_path']?.toString())),
            const SizedBox(width: 12),
            Expanded(child: _buildDocPreviewCard('Revenue License', _verificationData['revenue_license_image_path']?.toString())),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDocPreviewCard('Vehicle Front', _verificationData['vehicle_front_image']?.toString())),
            const SizedBox(width: 12),
            Expanded(child: _buildDocPreviewCard('Vehicle Back', _verificationData['vehicle_back_image']?.toString())),
          ],
        ),
        if (_existingOtherImagesUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Other Vehicle Photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _existingOtherImagesUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(_existingOtherImagesUrls[index], fit: BoxFit.cover),
              );
            },
          ),
        ],
      ],
    );
  }
}
