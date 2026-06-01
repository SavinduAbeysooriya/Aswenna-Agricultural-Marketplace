import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';

class MapLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String title;

  const MapLocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.title = 'Pick Location',
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  static const LatLng _sriLanka = LatLng(7.8731, 80.7718);

  GoogleMapController? _mapController;
  late LatLng _selected;
  bool _hasPinned = false;
  bool _isLocating = false;
  bool _isSearching = false;
  String _error = '';

  final _searchController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selected = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _hasPinned = true;
    } else {
      _selected = _sriLanka;
      _hasPinned = false;
    }
    if (_hasPinned) {
      _latController.text = _selected.latitude.toStringAsFixed(6);
      _lngController.text = _selected.longitude.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _setPin(LatLng loc) {
    setState(() {
      _selected = loc;
      _hasPinned = true;
      _latController.text = loc.latitude.toStringAsFixed(6);
      _lngController.text = loc.longitude.toStringAsFixed(6);
      _error = '';
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15));
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _error = '';
    });
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        _setPin(LatLng(locations.first.latitude, locations.first.longitude));
      } else {
        setState(() => _error = 'No results found for "$query".');
      }
    } catch (e) {
      setState(() => _error = 'Search failed. Try entering coordinates manually.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _error = '';
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _error = 'Please enable location services.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _setPin(LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      setState(() => _error = 'Failed to get location: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onManualInput(String _) {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat != null && lng != null) {
      setState(() {
        _selected = LatLng(lat, lng);
        _hasPinned = true;
        _error = '';
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selected, 15));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _hasPinned ? () => Navigator.of(context).pop({
              'latitude': _selected.latitude,
              'longitude': _selected.longitude,
            }) : null,
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: AppTheme.deepLeafGreen,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppTheme.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search place or address...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.deepLeafGreen),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.softGray,
                    ),
                    onSubmitted: (_) => _searchPlace(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Search',
                  onPressed: _searchPlace,
                  icon: const Icon(Icons.search_rounded, color: AppTheme.deepLeafGreen),
                ),
                IconButton(
                  tooltip: 'Use current location',
                  onPressed: _isLocating ? null : _useCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, color: AppTheme.deepLeafGreen),
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selected,
                zoom: _hasPinned ? 15 : 7,
              ),
              onMapCreated: (c) => _mapController = c,
              onTap: _setPin,
              markers: {
                Marker(
                  markerId: const MarkerId('pin'),
                  position: _selected,
                  draggable: true,
                  onDragEnd: _setPin,
                ),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          // Manual lat/lng + status
          Container(
            color: AppTheme.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                          isDense: true,
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: _onManualInput,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _lngController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                          isDense: true,
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: _onManualInput,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _hasPinned
                      ? '📍 ${_selected.latitude.toStringAsFixed(6)}, ${_selected.longitude.toStringAsFixed(6)}'
                      : 'Tap the map, drag the pin, search, or enter coordinates.',
                  style: TextStyle(
                    color: _hasPinned ? AppTheme.deepLeafGreen : const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: _hasPinned ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (_hasPinned) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop({
                        'latitude': _selected.latitude,
                        'longitude': _selected.longitude,
                      }),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Confirm Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepLeafGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
