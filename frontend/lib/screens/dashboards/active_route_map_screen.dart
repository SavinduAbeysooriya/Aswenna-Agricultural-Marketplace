import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';

class ActiveRouteMapScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;

  const ActiveRouteMapScreen({super.key, required this.delivery});

  @override
  State<ActiveRouteMapScreen> createState() => _ActiveRouteMapScreenState();
}

class _ActiveRouteMapScreenState extends State<ActiveRouteMapScreen> {
  static const String _googleApiKey = 'AIzaSyAv6nCtuhwyaN7-qRCvecCh75lNQECRI9M';

  static const String _customMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f1f5f9"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "on"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#475569"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f1f5f9"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#cbd5e1"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f8fafc"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#64748b"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e2e8f0"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#64748b"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#475569"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#cbd5e1"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#334155"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#64748b"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#cbd5e1"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f1f5f9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ccfbf1"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#0d9488"
      }
    ]
  }
]
  ''';

  GoogleMapController? _mapController;
  LatLng? _riderLocation;
  StreamSubscription<Position>? _positionStreamSub;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  bool _isLoadingRoute = true;
  String _routeInfo = 'Calculating route...';
  double _distanceToNext = 0.0;
  bool _isDemoMode = false;
  Timer? _demoTimer;
  double _demoProgress = 0.0;
  bool _isNavigating = false;
  double _riderBearing = 0.0;
  bool _hasZoomedInitially = false;

  // Cache targets
  LatLng? _destinationLatLng;
  final List<LatLng> _pickupsLatLng = [];
  final List<String> _stopNames = [];
  int _currentStopIndex = 0;
  String _vehicleType = 'motorcycle';
  String _currentStatus = 'assigned';
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _parseCoordinates();
    _loadVehicleType();
    _initLiveLocation();
    final latestTracking = widget.delivery['latest_tracking'] as Map<String, dynamic>?;
    _currentStatus = latestTracking?['status'] ?? 'assigned';
  }

  Future<void> _loadVehicleType() async {
    try {
      final response = await ApiService.getDeliveryPartnerProfile();
      if (response['success'] == true && response['profile'] != null) {
        final profile = response['profile'];
        final verificationData = profile['verification_data'];
        if (verificationData != null && verificationData['vehicle_type'] != null) {
          if (mounted) {
            setState(() {
              _vehicleType = verificationData['vehicle_type'].toString();
            });
            _buildMarkersAndRoute();
          }
        }
      }
    } catch (_) {}
  }

  final List<Map<String, dynamic>> _statusSteps = [
    {'status': 'heading_to_pickup', 'label': 'Head to Pickup', 'icon': Icons.directions_run_rounded},
    {'status': 'arrived_pickup', 'label': 'Arrived at Shop', 'icon': Icons.storefront_rounded},
    {'status': 'picked_up', 'label': 'Picked Up', 'icon': Icons.shopping_bag_rounded},
    {'status': 'on_the_way', 'label': 'On the Way', 'icon': Icons.sports_motorsports_rounded},
    {'status': 'arrived_destination', 'label': 'At Destination', 'icon': Icons.location_on_rounded},
    {'status': 'delivered', 'label': 'Mark Delivered', 'icon': Icons.check_circle_rounded},
  ];

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdatingStatus = true);

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (_) {}

    final orderId = widget.delivery['order_id'] as int;
    final result = await ApiService.updateDeliveryStatus(
      orderId,
      status: status,
      latitude: position?.latitude ?? 6.9271,
      longitude: position?.longitude ?? 79.8612,
    );

    setState(() => _isUpdatingStatus = false);

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _currentStatus = status;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Status updated: ${status.toUpperCase().replaceAll('_', ' ')}'),
          backgroundColor: AppTheme.deepLeafGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ ${result['message'] ?? 'Update failed.'}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _demoTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _parseCoordinates() {
    final delivery = widget.delivery;
    double? destLat = double.tryParse(delivery['delivery_latitude']?.toString() ?? '');
    double? destLng = double.tryParse(delivery['delivery_longitude']?.toString() ?? '');

    if (destLat != null && destLng != null) {
      _destinationLatLng = LatLng(destLat, destLng);
    }

    final pickupPoints = delivery['pickup_points'] as List? ?? [];
    for (var pp in pickupPoints) {
      double? pLat = double.tryParse(pp['pickup_lat']?.toString() ?? '');
      double? pLng = double.tryParse(pp['pickup_lng']?.toString() ?? '');
      if (pLat != null && pLng != null) {
        _pickupsLatLng.add(LatLng(pLat, pLng));
        _stopNames.add(pp['retailer_name'] ?? pp['shop_name'] ?? 'Pickup Shop');
      }
    }
    _stopNames.add(delivery['customer_name'] ?? 'Customer Destination');
  }

  Future<void> _initLiveLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS/Location services are disabled. Please enable GPS on your status bar to use live navigation.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 6),
            ),
          );
        }
        _fallbackToDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied. Real-time GPS location tracking is disabled.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          _fallbackToDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied. Please allow them in your app settings.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        _fallbackToDefaultLocation();
        return;
      }

      // 1. Get instant last known position to initialize map layout immediately
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        setState(() {
          _riderLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
        });
        _buildMarkersAndRoute();
      }

      // 2. Fetch fresh high accuracy current GPS position with 10-second timeout
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // If high accuracy fails or timeouts, try low accuracy or fallback
        if (lastKnown != null) {
          position = lastKnown;
        } else {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          );
        }
      }
      
      setState(() {
        _riderLocation = LatLng(position.latitude, position.longitude);
      });

      _buildMarkersAndRoute();

      // Start listening to live location updates
      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      ).listen((Position pos) {
        if (!_isDemoMode) {
          setState(() {
            _riderLocation = LatLng(pos.latitude, pos.longitude);
            if (pos.heading >= 0.0) {
              _riderBearing = pos.heading;
            }
          });
          _updateLiveRoute();
        }
      });

    } catch (e) {
      _fallbackToDefaultLocation();
    }
  }

  void _fallbackToDefaultLocation() {
    LatLng fallback = const LatLng(6.9271, 79.8612); // Colombo default
    if (_pickupsLatLng.isNotEmpty) {
      fallback = _pickupsLatLng.first;
    } else if (_destinationLatLng != null) {
      fallback = _destinationLatLng!;
    }
    
    setState(() {
      _riderLocation = fallback;
    });
    _buildMarkersAndRoute();
  }

  void _toggleDemoMode() {
    setState(() {
      _isDemoMode = !_isDemoMode;
      _demoProgress = 0.0;
    });

    if (_isDemoMode) {
      _startDemoSimulation();
    } else {
      _demoTimer?.cancel();
      _initLiveLocation();
    }
  }

  void _startDemoSimulation() {
    _demoTimer?.cancel();
    if (_riderLocation == null || (_pickupsLatLng.isEmpty && _destinationLatLng == null)) return;

    // Simulation route goes from current rider location -> pickups -> destination
    final List<LatLng> pathPoints = [_riderLocation!];
    pathPoints.addAll(_pickupsLatLng);
    if (_destinationLatLng != null) {
      pathPoints.add(_destinationLatLng!);
    }

    _demoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || !_isDemoMode) {
        timer.cancel();
        return;
      }

      setState(() {
        _demoProgress += 0.08;
        if (_demoProgress >= 1.0) {
          _demoProgress = 0.0;
          _currentStopIndex = 0;
        }

        // Interpolate position along the path
        double totalSections = (pathPoints.length - 1).toDouble();
        double currentSectionDouble = _demoProgress * totalSections;
        int sectionIndex = currentSectionDouble.floor();
        double sectionT = currentSectionDouble - sectionIndex;

        if (sectionIndex < pathPoints.length - 1) {
          _currentStopIndex = sectionIndex;
          LatLng start = pathPoints[sectionIndex];
          LatLng end = pathPoints[sectionIndex + 1];
          
          double lat = start.latitude + (end.latitude - start.latitude) * sectionT;
          double lng = start.longitude + (end.longitude - start.longitude) * sectionT;
          _riderLocation = LatLng(lat, lng);
        }
      });

      _updateLiveRoute();
    });
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * (math.pi / 180.0);
    double lon1 = start.longitude * (math.pi / 180.0);
    double lat2 = end.latitude * (math.pi / 180.0);
    double lon2 = end.longitude * (math.pi / 180.0);

    double dLon = lon2 - lon1;

    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double brng = math.atan2(y, x);
    return (brng * (180.0 / math.pi) + 360.0) % 360.0;
  }

  void _zoomToFitAll() {
    if (_mapController == null || _riderLocation == null) return;
    final List<LatLng> points = [_riderLocation!];
    points.addAll(_pickupsLatLng);
    if (_destinationLatLng != null) {
      points.add(_destinationLatLng!);
    }
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60, // Padding
      ),
    );
  }

  void _updateLiveRoute() {
    _buildMarkersAndRoute();
    if (_mapController != null && _riderLocation != null) {
      if (_isNavigating) {
        double bearing = _riderBearing;
        if (bearing == 0.0) {
          final List<LatLng> waypoints = [];
          waypoints.addAll(_pickupsLatLng);
          if (_destinationLatLng != null) {
            waypoints.add(_destinationLatLng!);
          }
          if (waypoints.isNotEmpty && _currentStopIndex < waypoints.length) {
            bearing = _calculateBearing(_riderLocation!, waypoints[_currentStopIndex]);
          }
        }
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _riderLocation!,
              zoom: 18.0,
              tilt: 50.0,
              bearing: bearing,
            ),
          ),
        );
      } else {
        if (!_hasZoomedInitially) {
          _hasZoomedInitially = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            _zoomToFitAll();
          });
        } else {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _riderLocation!,
                zoom: 14.5,
                tilt: 0.0,
                bearing: 0.0,
              ),
            ),
          );
        }
      }
    }
  }

  Future<BitmapDescriptor> _getVehicleMarker(double bearing) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 110.0;
    
    canvas.save();
    canvas.translate(size / 2, size / 2);

    double rotationCorrection = 0.0;
    IconData iconData;
    
    // Select icon and correction depending on vehicle type
    if (_vehicleType == 'motorcycle') {
      iconData = Icons.two_wheeler_rounded;
      rotationCorrection = -math.pi / 2; // material two_wheeler faces right, rotate to up
    } else if (_vehicleType == 'threewheeler') {
      iconData = Icons.electric_rickshaw_rounded;
      rotationCorrection = -math.pi / 2;
    } else if (_vehicleType == 'van') {
      iconData = Icons.airport_shuttle_rounded;
      rotationCorrection = -math.pi / 2;
    } else if (_vehicleType == 'small_truck' || _vehicleType == 'medium_truck' || _vehicleType == 'large_truck') {
      iconData = Icons.local_shipping_rounded;
      rotationCorrection = -math.pi / 2;
    } else {
      iconData = Icons.navigation_rounded; // Default chevron points up
    }

    canvas.rotate((bearing * (math.pi / 180.0)) + rotationCorrection);
    
    // Draw green circle background
    final Paint circlePaint = Paint()
      ..color = AppTheme.deepLeafGreen
      ..style = PaintingStyle.fill;
      
    // Outer white border ring
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
      
    // Shadow glow ring
    final Paint shadowPaint = Paint()
      ..color = AppTheme.deepLeafGreen.withOpacity(0.3)
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset.zero, size / 2.0, shadowPaint);
    canvas.drawCircle(Offset.zero, size / 2.5, circlePaint);
    canvas.drawCircle(Offset.zero, size / 2.5, borderPaint);
    
    // Draw icon inside the circle
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.45,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
    
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  Future<void> _buildMarkersAndRoute() async {
    if (_riderLocation == null) return;

    final Set<Marker> tempMarkers = {};
    final BitmapDescriptor vehicleIcon = await _getVehicleMarker(_riderBearing);

    // 1. Rider Marker (Vehicle Chevron)
    tempMarkers.add(
      Marker(
        markerId: const MarkerId('rider'),
        position: _riderLocation!,
        icon: vehicleIcon,
        anchor: const Offset(0.5, 0.5),
        flat: true, // Flat on map for navigation rotations
        zIndex: 100.0, // Ensure vehicle is drawn on top of all other markers
        infoWindow: const InfoWindow(title: 'You (Rider)'),
      ),
    );

    // 2. Pickups
    for (int i = 0; i < _pickupsLatLng.length; i++) {
      tempMarkers.add(
        Marker(
          markerId: MarkerId('pickup_$i'),
          position: _pickupsLatLng[i],
          infoWindow: InfoWindow(title: 'Pickup Stop: ${_stopNames[i]}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // 3. Destination
    if (_destinationLatLng != null) {
      tempMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLatLng!,
          infoWindow: InfoWindow(title: 'Deliver to: ${widget.delivery['customer_name'] ?? 'Customer'}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(tempMarkers);
    });

    // 4. Draw Polylines Route
    await _fetchRoutePolylines();
  }

  Future<void> _fetchRoutePolylines() async {
    if (_riderLocation == null) return;

    final List<LatLng> waypoints = [];
    waypoints.add(_riderLocation!);
    waypoints.addAll(_pickupsLatLng);
    if (_destinationLatLng != null) {
      waypoints.add(_destinationLatLng!);
    }

    if (waypoints.length < 2) return;

    // Calculate distance to next immediate target stop
    LatLng nextTarget = waypoints[(_currentStopIndex + 1).clamp(0, waypoints.length - 1)];
    double distanceMeters = Geolocator.distanceBetween(
      _riderLocation!.latitude,
      _riderLocation!.longitude,
      nextTarget.latitude,
      nextTarget.longitude,
    );

    setState(() {
      _distanceToNext = distanceMeters / 1000.0;
      final targetName = _stopNames.isNotEmpty && _currentStopIndex < _stopNames.length
          ? _stopNames[_currentStopIndex]
          : 'Destination';
      _routeInfo = 'Next Stop: $targetName';
    });

    // Attempt to query Google Directions API for high-fidelity road routing
    try {
      final origin = waypoints.first;
      final destination = waypoints.last;
      
      String waypointsParam = '';
      if (waypoints.length > 2) {
        waypointsParam = '&waypoints=' + waypoints.sublist(1, waypoints.length - 1)
            .map((wp) => '${wp.latitude},${wp.longitude}').join('|');
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '$waypointsParam'
        '&key=$_googleApiKey'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          final points = json['routes'][0]['overview_polyline']['points'] as String;
          final decodedPoints = _decodePolyline(points);

          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('road_route'),
                points: decodedPoints,
                color: AppTheme.deepLeafGreen,
                width: 5,
                jointType: JointType.round,
              ),
            );
            _isLoadingRoute = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback 1: Try OSRM Public Routing API to get actual street route lines
    try {
      final coordinatesString = waypoints.map((wp) => '${wp.longitude},${wp.latitude}').join(';');
      final osrmUrl = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordinatesString?overview=full&geometries=polyline'
      );
      final response = await http.get(osrmUrl);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['code'] == 'Ok' && json['routes'] is List && json['routes'].isNotEmpty) {
          final points = json['routes'][0]['geometry'] as String;
          final decodedPoints = _decodePolyline(points);

          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('road_route'),
                points: decodedPoints,
                color: AppTheme.deepLeafGreen,
                width: 5,
                jointType: JointType.round,
              ),
            );
            _isLoadingRoute = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback 2: Direct straight-line path routing
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('fallback_route'),
          points: waypoints,
          color: Colors.blue.shade600,
          width: 4,
          patterns: [PatternItem.dash(12), PatternItem.gap(8)],
        ),
      );
      _isLoadingRoute = false;
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  Future<void> _launchExternalNavigation() async {
    if (_riderLocation == null) return;
    
    final origin = '${_riderLocation!.latitude},${_riderLocation!.longitude}';
    
    // Final destination
    final destination = _destinationLatLng != null
        ? '${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}'
        : '6.9271,79.8612';

    // Get remaining pickup stops based on the current stop index
    List<LatLng> remainingPickups = [];
    if (_pickupsLatLng.isNotEmpty && _currentStopIndex < _pickupsLatLng.length) {
      remainingPickups = _pickupsLatLng.sublist(_currentStopIndex);
    }

    String waypointsParam = '';
    if (remainingPickups.isNotEmpty) {
      waypointsParam = '&waypoints=' + remainingPickups
          .map((wp) => '${wp.latitude},${wp.longitude}').join('|');
    }

    final googleMapsDirUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '$waypointsParam'
        '&travelmode=driving'
    );

    if (await canLaunchUrl(googleMapsDirUrl)) {
      await launchUrl(googleMapsDirUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external Google Maps routing.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute = _riderLocation != null;

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          hasRoute
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _riderLocation!,
                    zoom: 14.5,
                  ),
                  onMapCreated: (c) {
                    _mapController = c;
                    _mapController!.setMapStyle(_customMapStyle);
                    // Trigger initial bounds fit once map is fully laid out
                    Future.delayed(const Duration(milliseconds: 600), () {
                      _zoomToFitAll();
                    });
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                )
              : const Center(
                  child: CircularProgressIndicator(color: AppTheme.deepLeafGreen),
                ),

          // Recenter / Fit Route Floating Button (PickMe/Uber style)
          hasRoute && !_isNavigating
              ? Positioned(
                  bottom: 180,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: _zoomToFitAll,
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.deepLeafGreen,
                    elevation: 6,
                    child: const Icon(Icons.center_focus_strong_rounded, size: 20),
                  ),
                )
              : const SizedBox.shrink(),

          // Header Bar Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.darkGreen, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route Navigation',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(0, 1))
                            ]
                          ),
                        ),
                        Text(
                          'Active Tour Tracking',
                          style: TextStyle(
                            color: AppTheme.lightMint,
                            fontSize: 12,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(0, 1))
                            ]
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Simulation Toggle Button
                  GestureDetector(
                    onTap: _toggleDemoMode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isDemoMode ? AppTheme.accentGold : Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isDemoMode ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isDemoMode ? 'SIMULATING' : 'SIMULATE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
                    // Bottom Navigation Card Panel
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 16,
            right: 16,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.38,
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.lightMint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: AppTheme.deepLeafGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _routeInfo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.darkGreen,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isLoadingRoute
                                    ? 'Loading high precision route...'
                                    : 'Remaining distance: ~${_distanceToNext.toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isNavigating = !_isNavigating;
                              });
                              _updateLiveRoute();
                            },
                            icon: Icon(
                              _isNavigating ? Icons.cancel_rounded : Icons.navigation_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            label: Text(
                              _isNavigating ? 'Stop In-App Navigation' : 'Start Navigation',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isNavigating ? Colors.red.shade600 : AppTheme.deepLeafGreen,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 2,
                              shadowColor: (_isNavigating ? Colors.red.shade600 : AppTheme.deepLeafGreen).withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton.icon(
                        onPressed: _launchExternalNavigation,
                        icon: const Icon(Icons.open_in_new_rounded, size: 12, color: AppTheme.deepLeafGreen),
                        label: const Text(
                          'Open Google Maps Externally',
                          style: TextStyle(
                            color: AppTheme.deepLeafGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: AppTheme.deepLeafGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'CURRENT STATUS: ${_currentStatus.toUpperCase().replaceAll('_', ' ')}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepLeafGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _isUpdatingStatus
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(color: AppTheme.deepLeafGreen, strokeWidth: 3),
                            ),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _statusSteps.map((step) {
                              final isCurrent = _currentStatus == step['status'];
                              final isDelivered = step['status'] == 'delivered';
                              return GestureDetector(
                                onTap: () => _updateStatus(step['status']),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppTheme.deepLeafGreen
                                        : (isDelivered ? AppTheme.softGray : AppTheme.softGray),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: isCurrent
                                            ? AppTheme.deepLeafGreen
                                            : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        step['icon'],
                                        size: 11,
                                        color: isCurrent
                                            ? Colors.white
                                            : AppTheme.deepLeafGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        step['label'],
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrent
                                              ? Colors.white
                                              : AppTheme.darkGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
