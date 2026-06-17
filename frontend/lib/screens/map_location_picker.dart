import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
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
  static const String _googleApiKey = 'AIzaSyAv6nCtuhwyaN7-qRCvecCh75lNQECRI9M';

  GoogleMapController? _mapController;
  late LatLng _selected;
  bool _hasPinned = false;
  bool _isLocating = false;
  bool _isSearching = false;
  String _error = '';

  final _searchController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounceTimer;
  String _reverseGeocodedAddress = '';
  bool _isReverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selected = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _hasPinned = true;
      _reverseGeocode(_selected);
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
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _setPin(LatLng loc) {
    setState(() {
      _selected = loc;
      _hasPinned = true;
      _latController.text = loc.latitude.toStringAsFixed(6);
      _lngController.text = loc.longitude.toStringAsFixed(6);
      _error = '';
      _suggestions = []; // Clear autocomplete suggestions on pin
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15));
    _reverseGeocode(loc);
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length >= 3) {
        _fetchSuggestions(query.trim());
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() {
      _isLoadingSuggestions = true;
      _error = '';
    });

    // 1. Try Google Places Autocomplete API with location biasing (prioritizing current map view region)
    try {
      final googleUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_googleApiKey&components=country:lk&location=${_selected.latitude},${_selected.longitude}&radius=50000',
      );
      final response = await http.get(googleUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        if (status == 'OK' && data['predictions'] is List) {
          final List predictions = data['predictions'];
          setState(() {
            _suggestions = predictions.map<Map<String, dynamic>>((item) {
              return {
                'display_name': item['description'] ?? '',
                'place_id': item['place_id'] ?? '',
                'source': 'google',
              };
            }).toList();
            _isLoadingSuggestions = false;
          });
          return; // Success, return early
        }
      }
    } catch (_) {
      // Fall through to OpenStreetMap on any network/API issues
    }

    // 2. Fallback to OpenStreetMap Nominatim API
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5&countrycodes=lk',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'AswennaMarketplaceApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _suggestions = data.map<Map<String, dynamic>>((item) {
              return {
                'display_name': item['display_name'] ?? '',
                'latitude': double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0,
                'longitude': double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0,
                'source': 'osm',
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      // Both failed
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final displayName = suggestion['display_name'] ?? '';
    setState(() {
      _suggestions = [];
      _searchController.text = displayName;
    });

    if (suggestion['source'] == 'google') {
      final placeId = suggestion['place_id'];
      setState(() {
        _isSearching = true;
        _error = '';
      });

      // 1. Fetch details from Google Places Place Details API
      try {
        final detailsUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_googleApiKey',
        );
        final response = await http.get(detailsUrl);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['result'] != null) {
            final loc = data['result']['geometry']['location'];
            final lat = double.tryParse(loc['lat']?.toString() ?? '') ?? 0.0;
            final lng = double.tryParse(loc['lng']?.toString() ?? '') ?? 0.0;
            if (lat != 0.0 && lng != 0.0) {
              _setPin(LatLng(lat, lng));
              setState(() {
                _isSearching = false;
              });
              return; // Success
            }
          }
        }
      } catch (_) {
        // Fall through to geocoding geolocator lookup
      }

      // 2. Local geocoding fallback for description text
      try {
        final locations = await locationFromAddress(displayName);
        if (locations.isNotEmpty) {
          _setPin(LatLng(locations.first.latitude, locations.first.longitude));
          setState(() {
            _isSearching = false;
          });
          return;
        }
      } catch (_) {}

      setState(() {
        _isSearching = false;
        _error = 'Failed to fetch coordinates for "$displayName".';
      });
    } else {
      // Direct coordinate selections (from OSM or Google Geocoding multiple matches list)
      final lat = suggestion['latitude'] as double;
      final lon = suggestion['longitude'] as double;
      _setPin(LatLng(lat, lon));
    }
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    _debounceTimer?.cancel();
    setState(() {
      _isSearching = true;
      _error = '';
      _suggestions = [];
    });

    // 1. Try Google Geocoding API directly (very robust for unique homes, streets, and houses)
    try {
      final geocodeUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$_googleApiKey&bounds=5.9,79.5|9.9,81.9',
      );
      final response = await http.get(geocodeUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] is List && data['results'].isNotEmpty) {
          final results = data['results'] as List;
          if (results.length == 1) {
            final loc = results.first['geometry']['location'];
            final lat = double.tryParse(loc['lat']?.toString() ?? '') ?? 0.0;
            final lng = double.tryParse(loc['lng']?.toString() ?? '') ?? 0.0;
            if (lat != 0.0 && lng != 0.0) {
              _setPin(LatLng(lat, lng));
              setState(() {
                _isSearching = false;
              });
              return; // Single match found & pinned successfully
            }
          } else {
            // Multiple matches found (e.g. general streets, cities, or businesses)
            // Show them as clickable suggestions to let the user select the exact location
            setState(() {
              _suggestions = results.map<Map<String, dynamic>>((item) {
                final loc = item['geometry']['location'];
                return {
                  'display_name': item['formatted_address'] ?? '',
                  'latitude': double.tryParse(loc['lat']?.toString() ?? '0') ?? 0.0,
                  'longitude': double.tryParse(loc['lng']?.toString() ?? '0') ?? 0.0,
                  'source': 'osm', // source osm bypasses details call and uses coordinates directly
                };
              }).toList();
              _isSearching = false;
            });
            return;
          }
        }
      }
    } catch (_) {
      // Fall through to system geocoder
    }

    // 2. System geocoding fallback
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        _setPin(LatLng(locations.first.latitude, locations.first.longitude));
      } else {
        setState(() => _error = 'No results found for "$query".');
      }
    } catch (e) {
      setState(() => _error = 'Search failed. Try entering coordinates.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _reverseGeocode(LatLng coordinate) async {
    setState(() {
      _isReverseGeocoding = true;
    });
    try {
      final placemarks = await placemarkFromCoordinates(
        coordinate.latitude,
        coordinate.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final addressParts = [
          if (p.name != null && p.name!.isNotEmpty && p.name != p.street) p.name,
          if (p.street != null && p.street!.isNotEmpty) p.street,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) p.subAdministrativeArea,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea,
        ];
        setState(() {
          _reverseGeocodedAddress = addressParts.where((part) => part != null).take(3).join(', ');
        });
      } else {
        setState(() {
          _reverseGeocodedAddress = 'Sri Lanka';
        });
      }
    } catch (e) {
      setState(() {
        _reverseGeocodedAddress = 'Coordinates pinned successfully';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isReverseGeocoding = false;
        });
      }
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
      _reverseGeocode(_selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Google Map background
          Positioned.fill(
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
              zoomControlsEnabled: false, // Clean UI without standard controls
            ),
          ),

          // Floating header search bar card
          Positioned(
            top: statusBarHeight + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkGreen, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search place or address...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() {
                                        _suggestions = [];
                                      });
                                    },
                                    child: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                                  )
                                : null,
                          ),
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) => _searchPlace(),
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_isSearching || _isLoadingSuggestions)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppTheme.deepLeafGreen)),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.search_rounded, color: AppTheme.deepLeafGreen),
                          onPressed: _searchPlace,
                        ),
                    ],
                  ),
                ),
                
                // Floating suggestions list overlay
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFF1F5F9),
                            radius: 16,
                            child: Icon(Icons.location_on_rounded, color: AppTheme.deepLeafGreen, size: 16),
                          ),
                          title: Text(
                            suggestion['display_name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Floating my location action button
          Positioned(
            bottom: _hasPinned ? 260 : 180,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location_fab',
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.deepLeafGreen,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: _isLocating ? null : _useCurrentLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppTheme.deepLeafGreen)),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),

          // Pinned Details sheet at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _error,
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pinned Farm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (_isReverseGeocoding)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasPinned
                        ? (_reverseGeocodedAddress.isEmpty ? 'Loading location details...' : _reverseGeocodedAddress)
                        : 'Tap the map to pin your farm location or search for it.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: _hasPinned ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                      fontWeight: _hasPinned ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Coordinates section
                  Row(
                    children: [
                      Expanded(
                        child: _buildCoordinateInput('Latitude', _latController),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCoordinateInput('Longitude', _lngController),
                      ),
                    ],
                  ),
                  if (_hasPinned) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop({
                          'latitude': _selected.latitude,
                          'longitude': _selected.longitude,
                        }),
                        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                        label: const Text(
                          'Confirm Farm Location',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateInput(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      onChanged: _onManualInput,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.freshGreen),
        ),
      ),
    );
  }
}
