import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/crop_picker_screen.dart';
import 'package:aswenna/screens/map_location_picker.dart';

class HarvestListingForm extends StatefulWidget {
  final Map<String, dynamic>? existingListing;
  const HarvestListingForm({super.key, this.existingListing});

  @override
  State<HarvestListingForm> createState() => _HarvestListingFormState();
}

class _HarvestListingFormState extends State<HarvestListingForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLocating = false;
  bool _isLoadingLimits = false;

  // Form Fields State
  Map<String, dynamic>? _selectedCrop;
  String _selectedGrade = 'A';
  String _selectedUnit = 'kg';
  String _selectedCondition = 'Fresh';
  bool _deliveryAvailable = false;

  // Real-time market limit pricing state
  double? _marketAvg;
  double? _marketMin;
  double? _marketMax;

  // Location State
  double? _pickupLatitude;
  double? _pickupLongitude;
  GoogleMapController? _mapController;

  // Controllers
  final _notesController = TextEditingController();
  final _qtyController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxOrderController = TextEditingController();
  final _priceController = TextEditingController();
  final _minBidController = TextEditingController();
  final _storageController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _maxDeliveryDistController = TextEditingController();

  DateTime? _harvestDate = DateTime.now();
  DateTime? _availableFromDate = DateTime.now();
  DateTime? _availableToDate = DateTime.now().add(const Duration(days: 7));

  // Upload images path state
  final List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingListing != null) {
      final listing = widget.existingListing!;
      _notesController.text = (listing['notes'] ?? '').toString();
      _qtyController.text = (listing['available_quantity'] ?? '').toString();
      _minOrderController.text = (listing['minimum_order_quantity'] ?? '').toString();
      _maxOrderController.text = (listing['maximum_order_quantity'] ?? '').toString();
      _priceController.text = (listing['price_per_unit'] ?? '').toString();
      _minBidController.text = (listing['min_bid_price_per_unit'] ?? '').toString();
      _storageController.text = (listing['storage_method'] ?? '').toString();
      _deliveryFeeController.text = (listing['delivery_fee_per_km'] ?? '').toString();
      _maxDeliveryDistController.text = (listing['max_delivery_distance'] ?? '').toString();
      
      _selectedGrade = (listing['grade'] ?? 'A').toString();
      _selectedUnit = (listing['unit'] ?? 'kg').toString();
      _selectedCondition = (listing['harvest_condition'] ?? 'Fresh').toString();
      _deliveryAvailable = listing['delivery_available'] == 1 || listing['delivery_available'] == true;
      
      _pickupLatitude = listing['pickup_latitude'] != null ? double.tryParse(listing['pickup_latitude'].toString()) : null;
      _pickupLongitude = listing['pickup_longitude'] != null ? double.tryParse(listing['pickup_longitude'].toString()) : null;

      if (listing['harvest_date'] != null) {
        _harvestDate = DateTime.tryParse(listing['harvest_date'].toString());
      }
      if (listing['available_from_date'] != null) {
        _availableFromDate = DateTime.tryParse(listing['available_from_date'].toString());
      }
      if (listing['available_to_date'] != null) {
        _availableToDate = DateTime.tryParse(listing['available_to_date'].toString());
      }

      _selectedCrop = {
        'id': listing['crop_id'],
        'cropname': listing['cropname'] ?? 'Loaded Crop',
        'image_path': listing['crop_image'],
      };

      for (int i = 1; i <= 4; i++) {
        final img = listing['image_$i'];
        if (img != null && img.toString().isNotEmpty) {
          _imagePaths.add(img.toString());
        }
      }

      _fetchMarketLimits();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _qtyController.dispose();
    _minOrderController.dispose();
    _maxOrderController.dispose();
    _priceController.dispose();
    _minBidController.dispose();
    _storageController.dispose();
    _deliveryFeeController.dispose();
    _maxDeliveryDistController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _pickCrop() async {
    final pickedIds = await Navigator.push<Set<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => CropPickerScreen(
          initialSelectedIds: _selectedCrop != null
              ? {int.tryParse(_selectedCrop!['id'].toString()) ?? 0}
              : <int>{},
          title: 'Select Crop',
        ),
      ),
    );
    if (pickedIds != null && pickedIds.isNotEmpty) {
      final selectedId = pickedIds.first;
      final result = await ApiService.getApprovedCrops();
      if (result['success'] == true && result['crops'] != null) {
        final cropsList = List<Map<String, dynamic>>.from(
          (result['crops'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        final found = cropsList.firstWhere(
          (c) => (int.tryParse(c['id']?.toString() ?? '') ?? -1) == selectedId,
          orElse: () => <String, dynamic>{},
        );
        if (found.isNotEmpty) {
          setState(() {
            _selectedCrop = found;
          });
          _fetchMarketLimits();
        }
      }
    }
  }

  Future<void> _fetchMarketLimits() async {
    if (_selectedCrop == null) return;
    setState(() {
      _isLoadingLimits = true;
      _marketAvg = null;
      _marketMin = null;
      _marketMax = null;
    });

    final int cropId = _selectedCrop!['id'];
    final result = await ApiService.getCropRateDetail(cropId);
    if (!mounted) return;

    setState(() {
      _isLoadingLimits = false;
      if (result['success'] == true && result['today'] != null) {
        final today = result['today'];
        final String g = _selectedGrade.toLowerCase();
        
        _marketAvg = today['avg_rate_grade_$g'] != null ? double.tryParse(today['avg_rate_grade_$g'].toString()) : null;
        _marketMin = today['min_allowed_rate_$g'] != null ? double.tryParse(today['min_allowed_rate_$g'].toString()) : null;
        _marketMax = today['max_allowed_rate_$g'] != null ? double.tryParse(today['max_allowed_rate_$g'].toString()) : null;
      }
    });
  }

  void _setLocation(LatLng location) {
    setState(() {
      _pickupLatitude = location.latitude;
      _pickupLongitude = location.longitude;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable device location services.')),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are required.')),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _setLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get GPS location: $e')),
      );
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
          initialLatitude: _pickupLatitude,
          initialLongitude: _pickupLongitude,
          title: 'Pick Pickup Location',
        ),
      ),
    );

    if (!mounted || picked == null || picked['latitude'] == null || picked['longitude'] == null) return;
    _setLocation(LatLng(picked['latitude']!, picked['longitude']!));
  }

  Future<void> _pickImage() async {
    if (_imagePaths.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 images allowed.')),
      );
      return;
    }
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _imagePaths.add(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    DateTime initial = DateTime.now();
    if (field == 'harvest') initial = _harvestDate ?? DateTime.now();
    if (field == 'from') initial = _availableFromDate ?? DateTime.now();
    if (field == 'to') initial = _availableToDate ?? DateTime.now().add(const Duration(days: 7));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        if (field == 'harvest') _harvestDate = picked;
        if (field == 'from') _availableFromDate = picked;
        if (field == 'to') _availableToDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Format dates correctly for Laravel
    final harvestDateStr = "${_harvestDate!.year}-${_harvestDate!.month.toString().padLeft(2, '0')}-${_harvestDate!.day.toString().padLeft(2, '0')}";
    final fromDateStr = "${_availableFromDate!.year}-${_availableFromDate!.month.toString().padLeft(2, '0')}-${_availableFromDate!.day.toString().padLeft(2, '0')}";
    final toDateStr = "${_availableToDate!.year}-${_availableToDate!.month.toString().padLeft(2, '0')}-${_availableToDate!.day.toString().padLeft(2, '0')}";

    final data = <String, dynamic>{
      'crop_id': _selectedCrop!['id'],
      'grade': _selectedGrade,
      'available_quantity': _qtyController.text.trim(),
      'unit': _selectedUnit,
      'minimum_order_quantity': _minOrderController.text.trim(),
      'maximum_order_quantity': _maxOrderController.text.trim(),
      'price_per_unit': _priceController.text.trim(),
      'harvest_date': harvestDateStr,
      'harvest_condition': _selectedCondition,
      'available_from_date': fromDateStr,
      'available_to_date': toDateStr,
      'notes': _notesController.text.trim(),
    };

    if (_minBidController.text.trim().isNotEmpty) {
      data['min_bid_price_per_unit'] = _minBidController.text.trim();
    }
    if (_storageController.text.trim().isNotEmpty) {
      data['storage_method'] = _storageController.text.trim();
    }
    if (_pickupLatitude != null && _pickupLongitude != null) {
      data['pickup_latitude'] = _pickupLatitude;
      data['pickup_longitude'] = _pickupLongitude;
    }
    data['delivery_available'] = _deliveryAvailable ? '1' : '0';
    if (_deliveryAvailable) {
      if (_deliveryFeeController.text.trim().isNotEmpty) {
        data['delivery_fee_per_km'] = _deliveryFeeController.text.trim();
      }
      if (_maxDeliveryDistController.text.trim().isNotEmpty) {
        data['max_delivery_distance'] = _maxDeliveryDistController.text.trim();
      }
    }

    final Map<String, dynamic> result;
    if (widget.existingListing != null) {
      final keepImages = _imagePaths.where((p) => !p.startsWith('/') && !p.contains('\\')).toList();
      final newImages = _imagePaths.where((p) => p.startsWith('/') || p.contains('\\')).toList();

      result = await ApiService.updateHarvestListing(
        int.tryParse(widget.existingListing!['id']?.toString() ?? '') ?? 0,
        data,
        images: newImages,
        keepImages: keepImages,
      );
    } else {
      result = await ApiService.createHarvestListing(data, images: _imagePaths);
    }

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingListing != null
              ? 'Harvest Listing updated successfully!'
              : 'Harvest Listing created successfully!'),
        ),
      );
      Navigator.pop(context, true); // Return true to request parent refresh
    } else {
      final msg = result['message'] ?? 'Failed to submit listing.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng mapCenter = _pickupLatitude != null && _pickupLongitude != null
        ? LatLng(_pickupLatitude!, _pickupLongitude!)
        : const LatLng(7.8731, 80.7718);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text('Publish Harvest Listing'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Crop Selection Panel
                    _buildSelectionCard(
                      title: 'Select Crop *',
                      icon: Icons.eco_rounded,
                      child: GestureDetector(
                        onTap: _pickCrop,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              _selectedCrop == null
                                  ? const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 36)
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: _selectedCrop!['image_path'] != null
                                            ? DecorationImage(
                                                image: NetworkImage(ApiService.fileUrl(_selectedCrop!['image_path']) ?? ''),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _selectedCrop!['image_path'] == null
                                          ? const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen)
                                          : null,
                                    ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedCrop != null ? _selectedCrop!['cropname'] : 'Tap to Choose Crop',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedCrop != null ? const Color(0xFF0F172A) : Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedCrop != null ? 'Crop ID: ${_selectedCrop!['id']}' : 'Market average pricing dynamically links here',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Yield and Product Details Card
                    _buildSelectionCard(
                      title: 'Yield Details',
                      icon: Icons.production_quantity_limits_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdownField(
                            label: 'Yield Quality Grade *',
                            value: _selectedGrade,
                            items: ['A', 'B', 'C'],
                            icon: Icons.grade_rounded,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGrade = val);
                                _fetchMarketLimits();
                              }
                            },
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Available Quantity *',
                                  controller: _qtyController,
                                  icon: Icons.scale_rounded,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Unit *',
                                  value: _selectedUnit,
                                  items: ['kg', 'g', 'ton', 'piece', 'bunch', 'dozen', 'liter'],
                                  icon: Icons.calendar_view_week_rounded,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedUnit = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Min Order Qty *',
                                  controller: _minOrderController,
                                  icon: Icons.shopping_basket_rounded,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Max Order Qty *',
                                  controller: _maxOrderController,
                                  icon: Icons.local_shipping_rounded,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pricing Details Card
                    _buildSelectionCard(
                      title: 'Pricing Engine Settings',
                      icon: Icons.monetization_on_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Interactive Market average alert card
                          if (_isLoadingLimits)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: LinearProgressIndicator(color: AppTheme.deepLeafGreen, backgroundColor: Color(0xFFF1F1F1)),
                            )
                          else if (_selectedCrop != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _marketAvg != null ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _marketAvg != null ? AppTheme.deepLeafGreen.withOpacity(0.2) : const Color(0xFFFFB74D).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    _marketAvg != null ? Icons.verified_rounded : Icons.info_rounded,
                                    color: _marketAvg != null ? AppTheme.deepLeafGreen : const Color(0xFFE65100),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _marketAvg != null ? 'Daily Market Pricing Match' : 'Open Price Threshold',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _marketAvg != null ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _marketAvg != null
                                              ? 'Allowed Range: LKR ${_marketMin!.toStringAsFixed(2)} – LKR ${_marketMax!.toStringAsFixed(2)}\n(Calculated −5% to +10% of today\'s average buyer rate LKR ${_marketAvg!.toStringAsFixed(2)})'
                                              : 'No buyer pricing submissions for ${_selectedCrop!['cropname']} (Grade $_selectedGrade) today. You are free to enter any positive price.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.4,
                                            color: _marketAvg != null ? const Color(0xFF2E7D32) : const Color(0xFFBF360C),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _buildInputField(
                            label: 'Selling Price Per Unit (LKR) *',
                            controller: _priceController,
                            icon: Icons.currency_rupee_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final val = double.tryParse(v);
                              if (val == null || val <= 0) return 'Enter a valid price';
                              if (_marketMin != null && _marketMax != null) {
                                if (val < _marketMin! || val > _marketMax!) {
                                  return 'Must be within market LKR ${_marketMin!.toStringAsFixed(2)} – LKR ${_marketMax!.toStringAsFixed(2)}';
                                }
                              }
                              return null;
                            },
                          ),
                          _buildInputField(
                            label: 'Minimum Bid Price Per Unit (Optional)',
                            controller: _minBidController,
                            icon: Icons.gavel_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location Pinned Card (Maps Integrated)
                    _buildSelectionCard(
                      title: 'Collection & Pinned Map Location',
                      icon: Icons.location_on_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.my_location_rounded, color: AppTheme.deepLeafGreen, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Pin Collection Site',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _openLocationPicker,
                                icon: const Icon(Icons.search_rounded, size: 14, color: AppTheme.deepLeafGreen),
                                label: const Text('Pick Map', style: TextStyle(color: AppTheme.deepLeafGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              TextButton.icon(
                                onPressed: _isLocating ? null : _useCurrentLocation,
                                icon: _isLocating
                                    ? const SizedBox(height: 10, width: 10, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.gps_fixed_rounded, size: 14, color: AppTheme.deepLeafGreen),
                                label: const Text('GPS', style: TextStyle(color: AppTheme.deepLeafGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: mapCenter,
                                  zoom: _pickupLatitude != null && _pickupLongitude != null ? 15 : 7,
                                ),
                                markers: _pickupLatitude != null && _pickupLongitude != null
                                    ? {
                                        Marker(
                                          markerId: const MarkerId('pickup_loc'),
                                          position: LatLng(_pickupLatitude!, _pickupLongitude!),
                                        )
                                      }
                                    : {},
                                onMapCreated: (controller) {
                                  _mapController = controller;
                                  if (_pickupLatitude != null && _pickupLongitude != null) {
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(LatLng(_pickupLatitude!, _pickupLongitude!), 15),
                                    );
                                  }
                                },
                                onTap: _setLocation,
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Logistics details card
                    _buildSelectionCard(
                      title: 'Harvest & Delivery Details',
                      icon: Icons.local_shipping_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDatePickerCard(
                                  label: 'Harvest Date',
                                  value: _harvestDate,
                                  onTap: () => _selectDate(context, 'harvest'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Harvest Condition *',
                                  value: _selectedCondition,
                                  items: ['Fresh', '1 Day Old', '2 Days Old', '3 Days Old', 'Dried', 'Processed'],
                                  icon: Icons.analytics_rounded,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCondition = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          _buildInputField(
                            label: 'Storage Method (e.g. Cold storage, dry room)',
                            controller: _storageController,
                            icon: Icons.warehouse_rounded,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDatePickerCard(
                                  label: 'Available From',
                                  value: _availableFromDate,
                                  onTap: () => _selectDate(context, 'from'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDatePickerCard(
                                  label: 'Available To',
                                  value: _availableToDate,
                                  onTap: () => _selectDate(context, 'to'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Delivery Available',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            subtitle: Text('Toggle if you provide shipping options', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            activeColor: AppTheme.deepLeafGreen,
                            value: _deliveryAvailable,
                            onChanged: (val) {
                              setState(() => _deliveryAvailable = val);
                            },
                          ),
                          if (_deliveryAvailable) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Fee Per KM (LKR) *',
                                    controller: _deliveryFeeController,
                                    icon: Icons.monetization_on_rounded,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (v) => _deliveryAvailable && (v == null || v.isEmpty) ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Max Distance (KM) *',
                                    controller: _maxDeliveryDistController,
                                    icon: Icons.explore_rounded,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (v) => _deliveryAvailable && (v == null || v.isEmpty) ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Image Upload Panel
                    _buildSelectionCard(
                      title: 'Harvest Photo Previews (Max 4)',
                      icon: Icons.camera_alt_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                            label: const Text('Add Harvest Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.deepLeafGreen.withOpacity(0.08),
                              foregroundColor: AppTheme.deepLeafGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          if (_imagePaths.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _imagePaths.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_imagePaths[index]),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _imagePaths.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
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
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notes details card
                    _buildSelectionCard(
                      title: 'Additional Notes',
                      icon: Icons.note_rounded,
                      child: TextField(
                        controller: _notesController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Enter any additional details, packaging specifications, etc.',
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deepLeafGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Publish Yield to Marketplace',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSelectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.deepLeafGreen, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.deepLeafGreen, size: 18),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            borderSide: const BorderSide(color: AppTheme.deepLeafGreen, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.deepLeafGreen, size: 18),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            borderSide: const BorderSide(color: AppTheme.deepLeafGreen, width: 1.5),
          ),
        ),
        items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePickerCard({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final dateStr = value != null ? "${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}" : 'Select';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range_rounded, color: AppTheme.deepLeafGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
