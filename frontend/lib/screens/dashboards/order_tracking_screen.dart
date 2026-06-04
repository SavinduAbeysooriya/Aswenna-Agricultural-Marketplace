import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';

double _td(dynamic v, [double fb = 0.0]) {
  if (v == null) return fb;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fb;
}
double? _tdn(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _order;
  List<dynamic> _history = [];
  Map<String, dynamic>? _latestTracking;
  List<dynamic> _pickupPoints = [];
  Timer? _refreshTimer;
  GoogleMapController? _mapController;

  final List<Map<String, dynamic>> _statusTimeline = [
    {'key': 'pending', 'label': 'Order Placed', 'icon': Icons.receipt_long_rounded},
    {'key': 'confirmed', 'label': 'Confirmed', 'icon': Icons.check_circle_rounded},
    {'key': 'delivery_partner_assigned', 'label': 'Partner Assigned', 'icon': Icons.sports_motorsports_rounded},
    {'key': 'heading_to_pickup', 'label': 'Heading to Shop', 'icon': Icons.directions_run_rounded},
    {'key': 'picked_up', 'label': 'Picked Up', 'icon': Icons.shopping_bag_rounded},
    {'key': 'on_the_way', 'label': 'On the Way', 'icon': Icons.local_shipping_rounded},
    {'key': 'delivered', 'label': 'Delivered!', 'icon': Icons.celebration_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadTracking();
    // Auto-refresh every 15 seconds for live tracking
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadTracking(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadTracking({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    final result = await ApiService.trackOrder(widget.orderId);
    if (mounted) {
      if (result['success'] == true) {
        final newOrder = result['order'] as Map<String, dynamic>?;
        final newHistory = result['tracking_history'] as List? ?? [];
        final newLatest = result['latest_tracking'] as Map<String, dynamic>?;
        final newPickups = result['pickup_points'] as List? ?? [];

        setState(() {
          _order = newOrder;
          _history = newHistory;
          _latestTracking = newLatest;
          _pickupPoints = newPickups;
          _isLoading = false;
          _error = null;
        });

        // Pan map to partner location if available
        if (_mapController != null && newOrder != null) {
          final pLat = _tdn(newOrder['partner_lat']);
          final pLng = _tdn(newOrder['partner_lng']);
          if (pLat != null && pLng != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(LatLng(pLat, pLng)),
            );
          }
        }
      } else {
        if (!silent) {
          setState(() {
            _error = result['message'] ?? 'Failed to load tracking info.';
            _isLoading = false;
          });
        }
      }
    }
  }

  String _getOrderStatus() {
    final status = _order?['order_status'] ?? 'pending';
    final trackingStatus = _latestTracking?['status'];
    return trackingStatus ?? status;
  }

  int _getProgressIndex(String status) {
    final statusOrder = [
      'pending',
      'confirmed',
      'delivery_partner_assigned',
      'heading_to_pickup',
      'picked_up',
      'on_the_way',
      'delivered'
    ];
    return statusOrder.indexOf(status);
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final order = _order;
    if (order == null) return markers;

    // Customer destination
    final dLat = _tdn(order['delivery_latitude']);
    final dLng = _tdn(order['delivery_longitude']);
    if (dLat != null && dLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(dLat, dLng),
        infoWindow:
            const InfoWindow(title: 'Your Location', snippet: 'Delivery destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    // Delivery partner live location
    final pLat = _tdn(order['partner_lat']);
    final pLng = _tdn(order['partner_lng']);
    if (pLat != null && pLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('partner'),
        position: LatLng(pLat, pLng),
        infoWindow: InfoWindow(
            title: order['partner_name'] ?? 'Delivery Partner',
            snippet: 'Delivery partner is here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    // Pickup points (retailer shops)
    for (final pp in _pickupPoints) {
      final ppLat = _tdn(pp['lat']);
      final ppLng = _tdn(pp['lng']);
      if (ppLat != null && ppLng != null) {
        markers.add(Marker(
          markerId: MarkerId('pickup_${pp['retailer_id']}'),
          position: LatLng(ppLat, ppLng),
          infoWindow:
              InfoWindow(title: pp['shop_name'] ?? 'Shop', snippet: 'Pickup point'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
        ));
      }
    }

    return markers;
  }

  LatLng _getMapCenter() {
    final order = _order;
    if (order == null) return const LatLng(6.9271, 79.8612);

    // Prefer partner location for centering
    final pLat = _tdn(order['partner_lat']);
    final pLng = _tdn(order['partner_lng']);
    if (pLat != null && pLng != null) return LatLng(pLat, pLng);

    final dLat = _tdn(order['delivery_latitude']);
    final dLng = _tdn(order['delivery_longitude']);
    if (dLat != null && dLng != null) return LatLng(dLat, dLng);

    return const LatLng(6.9271, 79.8612);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.softGray,
        appBar: AppBar(title: Text('Track ${widget.orderNumber}')),
        body: const Center(
            child: CircularProgressIndicator(color: AppTheme.deepLeafGreen)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.softGray,
        appBar: AppBar(title: Text('Track ${widget.orderNumber}')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadTracking, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final currentStatus = _getOrderStatus();
    final progressIndex = _getProgressIndex(currentStatus);
    final isDelivered = currentStatus == 'delivered';
    final partnerName = order['partner_name'];
    final partnerPhone = order['partner_phone'];
    final hasPartner = partnerName != null;

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      body: RefreshIndicator(
        onRefresh: _loadTracking,
        color: AppTheme.deepLeafGreen,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // App bar
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppTheme.deepLeafGreen,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _loadTracking,
                ),
              ],
              title: Text(
                widget.orderNumber,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildMap(),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status card
                    _buildStatusCard(currentStatus, isDelivered),
                    const SizedBox(height: 16),

                    // Partner info (if assigned)
                    if (hasPartner) ...[
                      _buildPartnerCard(partnerName!, partnerPhone),
                      const SizedBox(height: 16),
                    ],

                    // Pickup route summary
                    _buildRouteCard(),
                    const SizedBox(height: 16),

                    // Timeline progress
                    _buildTimeline(progressIndex),
                    const SizedBox(height: 16),

                    // Live tracking history
                    if (_history.isNotEmpty) ...[
                      _buildTrackingHistory(),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _getMapCenter(),
        zoom: 13,
      ),
      onMapCreated: (c) => _mapController = c,
      markers: _buildMarkers(),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
    );
  }

  Widget _buildStatusCard(String currentStatus, bool isDelivered) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDelivered
              ? [const Color(0xFF1B5E20), AppTheme.deepLeafGreen]
              : [AppTheme.darkGreen, AppTheme.deepLeafGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivered
                  ? Icons.celebration_rounded
                  : Icons.local_shipping_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ORDER STATUS',
                    style: TextStyle(
                        color: AppTheme.lightMint,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  currentStatus.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18),
                ),
                if (_latestTracking?['tracking_note'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _latestTracking!['tracking_note'],
                    style: const TextStyle(
                        color: AppTheme.lightMint, fontSize: 12),
                  ),
                ]
              ],
            ),
          ),
          if (!isDelivered)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.autorenew_rounded, color: Colors.white, size: 16),
                  SizedBox(height: 2),
                  Text('LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(String partnerName, String? phone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.lightMint,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.freshGreen, width: 2),
            ),
            child: const Icon(Icons.sports_motorsports_rounded,
                color: AppTheme.deepLeafGreen, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YOUR DELIVERY PARTNER',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(
                  partnerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.darkGreen),
                ),
                if (phone != null)
                  Text(phone,
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.lightMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppTheme.deepLeafGreen, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    final deliveryAddress = _order?['delivery_address'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DELIVERY ROUTE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),

          // Pickup stops
          ...(_pickupPoints.asMap().entries.map((e) {
            final index = e.key;
            final pp = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppTheme.freshGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (index < _pickupPoints.length - 1 || true)
                        Container(
                            width: 2, height: 20, color: AppTheme.softGray),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pp['shop_name'] ?? 'Shop',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF0F172A)),
                        ),
                        if (pp['shop_address'] != null)
                          Text(pp['shop_address'],
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  const Icon(Icons.storefront_rounded,
                      color: AppTheme.freshGreen, size: 18),
                ],
              ),
            );
          })),

          // Final destination
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Colors.red, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUR LOCATION',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8))),
                    Text(
                      deliveryAddress,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0F172A)),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(int progressIndex) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DELIVERY PROGRESS',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8))),
          const SizedBox(height: 16),
          ..._statusTimeline.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            final isDone = idx <= progressIndex;
            final isCurrent = idx == progressIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDone ? AppTheme.deepLeafGreen : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppTheme.deepLeafGreen.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          step['icon'],
                          color: isDone ? Colors.white : const Color(0xFFCBD5E1),
                          size: 18,
                        ),
                      ),
                      if (idx < _statusTimeline.length - 1)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 2,
                          height: 24,
                          color: isDone ? AppTheme.freshGreen : const Color(0xFFE2E8F0),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['label'],
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                            color: isDone ? AppTheme.darkGreen : const Color(0xFF94A3B8),
                          ),
                        ),
                        if (isCurrent)
                          Text(
                            _latestTracking?['tracking_note'] ?? 'In progress...',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF64748B)),
                          ),
                      ],
                    ),
                  ),
                  if (isDone && !isCurrent)
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.freshGreen, size: 18),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.lightMint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('NOW',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepLeafGreen)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrackingHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TRACKING HISTORY',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          ..._history.reversed.take(6).map((h) {
            final status = h['status'] ?? '';
            final note = h['tracking_note'] ?? '';
            final trackedAt = h['tracked_at'] ?? '';
            String timeStr = '';
            try {
              final dt = DateTime.parse(trackedAt).toLocal();
              timeStr =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            } catch (_) {}

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.lightMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_history_rounded,
                        color: AppTheme.deepLeafGreen, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.toUpperCase().replaceAll('_', ' '),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: AppTheme.darkGreen),
                        ),
                        if (note.isNotEmpty)
                          Text(note,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Text(timeStr,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
