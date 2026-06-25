import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/screens/dashboards/delivery_profile_screen.dart';

/// Safely converts any API value (String/int/double/null) to double.
double _toDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

/// Nullable version — returns null if the value is null or unparseable.
double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard>
    with TickerProviderStateMixin {
  int _currentTab = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.8, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _NearbyOrdersTab(pulseAnimation: _pulseAnimation),
      const _ActiveDeliveriesTab(),
      const _EarningsTab(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      body: tabs[_currentTab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepLeafGreen.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.explore_rounded, 'Nearby'),
                _buildNavItem(1, Icons.delivery_dining_rounded, 'Active'),
                _buildNavItem(2, Icons.account_balance_wallet_rounded, 'Earnings'),
                _buildNavItemAction(
                  Icons.logout_rounded,
                  'Logout',
                  Colors.red,
                  _logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.lightMint : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isActive ? AppTheme.deepLeafGreen : const Color(0xFF94A3B8),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? AppTheme.deepLeafGreen
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.normal, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: Nearby Open Orders
// ─────────────────────────────────────────────────────────────────────────────
class _NearbyOrdersTab extends StatefulWidget {
  final Animation<double> pulseAnimation;
  const _NearbyOrdersTab({required this.pulseAnimation});

  @override
  State<_NearbyOrdersTab> createState() => _NearbyOrdersTabState();
}

class _NearbyOrdersTabState extends State<_NearbyOrdersTab> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  bool _isCreatingTest = false;
  String? _error;
  Position? _currentPosition;
  bool _isSharingLocation = false;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _initLocationAndLoad();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocationAndLoad() async {
    await _fetchLocation();
    await _loadNearbyOrders();
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {}
  }

  Future<void> _toggleLocationSharing() async {
    if (_isSharingLocation) {
      _locationTimer?.cancel();
      setState(() => _isSharingLocation = false);
      return;
    }

    setState(() => _isSharingLocation = true);
    await _pushLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _fetchLocation();
      await _pushLocation();
    });
  }

  Future<void> _pushLocation() async {
    if (_currentPosition == null) return;
    await ApiService.updateDeliveryLocation(
        _currentPosition!.latitude, _currentPosition!.longitude);
  }

  Future<void> _loadNearbyOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await ApiService.getNearbyDeliveryOrders();
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _orders = result['delivery_requests'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load orders.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptOrder(Map<String, dynamic> req) async {
    final requestId = req['delivery_request_id'];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ApiService.acceptDeliveryRequest(requestId);
    if (mounted) Navigator.pop(context);

    if (result['success'] == true) {
      _showSnack('✅ Delivery accepted! Head to the first pickup point.', AppTheme.deepLeafGreen);
      _loadNearbyOrders();
    } else {
      _showSnack('❌ ${result['message'] ?? 'Could not accept order.'}', Colors.red);
    }
  }

  Future<void> _rejectOrder(Map<String, dynamic> req) async {
    final requestId = req['delivery_request_id'];
    await ApiService.rejectDeliveryRequest(requestId, reason: 'Not available');
    _loadNearbyOrders();
  }

  Future<void> _createTestOrder() async {
    setState(() => _isCreatingTest = true);
    final result = await ApiService.debugCreateTestDeliveryRequest();
    setState(() => _isCreatingTest = false);
    if (result['success'] == true) {
      _showSnack(
        '🧪 ${result['message'] ?? 'Test order created!'} '
        '(${result['retailer']} → ${result['customer']}, '
        'LKR ${(result['partner_payout'] ?? 0).toStringAsFixed(0)} payout)',
        AppTheme.deepLeafGreen,
      );
      _loadNearbyOrders();
    } else {
      _showSnack('❌ ${result['message'] ?? 'Failed to create test order.'}', Colors.red);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.darkGreen, AppTheme.deepLeafGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sports_motorsports_rounded,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Delivery Console',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20)),
                          Text('Find and accept nearby deliveries',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppTheme.lightMint, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadNearbyOrders,
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.account_circle_outlined,
                          color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DeliveryProfileScreen()),
                        ).then((_) => _initLocationAndLoad());
                      },
                    ),
                    // 🧪 Test button in header
                    _isCreatingTest
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                        : Tooltip(
                            message: 'Create test order',
                            child: IconButton(
                              onPressed: _createTestOrder,
                              icon: const Icon(
                                Icons.science_rounded,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _toggleLocationSharing,
                  child: AnimatedBuilder(
                    animation: widget.pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _isSharingLocation ? widget.pulseAnimation.value : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isSharingLocation
                              ? Colors.green.shade400
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSharingLocation
                                  ? Icons.location_on_rounded
                                  : Icons.location_off_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isSharingLocation
                                  ? 'Live Location: ON'
                                  : 'Tap to go ONLINE',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.deepLeafGreen))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.red, size: 60),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(
                                    color: Color(0xFF64748B))),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: _loadNearbyOrders,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_rounded,
                                    color: AppTheme.deepLeafGreen
                                        .withOpacity(0.3),
                                    size: 80),
                                const SizedBox(height: 16),
                                const Text('No open orders nearby',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF64748B))),
                                const SizedBox(height: 6),
                                const Text(
                                    'New orders appear here automatically',
                                    style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12)),
                                const SizedBox(height: 28),
                                // 🧪 Testing button in empty state
                                _isCreatingTest
                                    ? const CircularProgressIndicator(
                                        color: AppTheme.deepLeafGreen)
                                    : ElevatedButton.icon(
                                        onPressed: _createTestOrder,
                                        icon: const Icon(
                                            Icons.science_rounded, size: 18),
                                        label: const Text(
                                            '🧪 Create Test Order',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF6366F1),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                        ),
                                      ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Testing only — creates a fake nearby order',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFCBD5E1)),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadNearbyOrders,
                            color: AppTheme.deepLeafGreen,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              padding: const EdgeInsets.all(16),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) =>
                                  _DeliveryRequestCard(
                                request: _orders[index],
                                onAccept: () =>
                                    _acceptOrder(_orders[index]),
                                onReject: () =>
                                    _rejectOrder(_orders[index]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _DeliveryRequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final payout = _toDouble(request['partner_payout']);
    final deliveryFee = _toDouble(request['delivery_fee']);
    final distanceKm = _toDoubleOrNull(request['estimated_distance_km']);
    final pickupPoints = request['pickup_points'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          // Top earnings bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.deepLeafGreen, AppTheme.freshGreen],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUR PAYOUT',
                        style: TextStyle(
                            color: AppTheme.lightMint,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    Text(
                      'LKR ${payout.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22),
                    ),
                    Text(
                      'Delivery Fee: LKR ${deliveryFee.toStringAsFixed(2)} (5% platform fee deducted)',
                      style: const TextStyle(
                          color: AppTheme.lightMint, fontSize: 10),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.sports_motorsports_rounded,
                        color: Colors.white70, size: 32),
                    if (distanceKm != null)
                      Text(
                        '~${distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                            color: AppTheme.lightMint,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup stops
                Row(
                  children: [
                    const Icon(Icons.store_rounded,
                        color: AppTheme.deepLeafGreen, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${pickupPoints.length} Pickup Stop${pickupPoints.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.darkGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...pickupPoints.map((pp) => Padding(
                      padding: const EdgeInsets.only(left: 22, bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.freshGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pp['retailer_name'] ?? pp['shop_name'] ?? 'Shop',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
                Container(height: 1, color: AppTheme.softGray),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request['delivery_address'] ?? 'Customer Location',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF0F172A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Skip',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deepLeafGreen,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Accept Delivery',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: Active Deliveries with Live Map & Status Updates
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveDeliveriesTab extends StatefulWidget {
  const _ActiveDeliveriesTab();

  @override
  State<_ActiveDeliveriesTab> createState() => _ActiveDeliveriesTabState();
}

class _ActiveDeliveriesTabState extends State<_ActiveDeliveriesTab> {
  List<dynamic> _deliveries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await ApiService.getMyDeliveries();
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _deliveries = result['deliveries'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            color: AppTheme.pureWhite,
            child: Row(
              children: [
                const Icon(Icons.delivery_dining_rounded,
                    color: AppTheme.deepLeafGreen, size: 28),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Deliveries',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: AppTheme.darkGreen)),
                    Text('Update status for each delivery',
                        style: TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppTheme.deepLeafGreen),
                  onPressed: _load,
                ),
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined,
                      color: AppTheme.deepLeafGreen),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DeliveryProfileScreen()),
                    ).then((_) => _load());
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.deepLeafGreen))
                : _error != null
                    ? Center(child: Text(_error!))
                    : _deliveries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    color: AppTheme.deepLeafGreen
                                        .withOpacity(0.3),
                                    size: 80),
                                const SizedBox(height: 16),
                                const Text('No active deliveries',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF64748B))),
                                const SizedBox(height: 6),
                                const Text('Accept an order from the Nearby tab',
                                    style: TextStyle(
                                        color: Color(0xFF94A3B8))),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppTheme.deepLeafGreen,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              itemCount: _deliveries.length,
                              itemBuilder: (context, index) =>
                                  _ActiveDeliveryCard(
                                delivery: _deliveries[index],
                                onRefresh: _load,
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ActiveDeliveryCard extends StatefulWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback onRefresh;
  const _ActiveDeliveryCard(
      {required this.delivery, required this.onRefresh});

  @override
  State<_ActiveDeliveryCard> createState() => _ActiveDeliveryCardState();
}

class _ActiveDeliveryCardState extends State<_ActiveDeliveryCard> {
  bool _isUpdating = false;
  GoogleMapController? _mapController;

  final List<Map<String, dynamic>> _statusSteps = [
    {'status': 'heading_to_pickup', 'label': 'Head to Pickup', 'icon': Icons.directions_run_rounded},
    {'status': 'arrived_pickup', 'label': 'Arrived at Shop', 'icon': Icons.storefront_rounded},
    {'status': 'picked_up', 'label': 'Picked Up', 'icon': Icons.shopping_bag_rounded},
    {'status': 'on_the_way', 'label': 'On the Way', 'icon': Icons.sports_motorsports_rounded},
    {'status': 'arrived_destination', 'label': 'At Destination', 'icon': Icons.location_on_rounded},
    {'status': 'delivered', 'label': 'Mark Delivered', 'icon': Icons.check_circle_rounded},
  ];

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);

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

    setState(() => _isUpdating = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Status updated: ${status.toUpperCase().replaceAll('_', ' ')}'),
          backgroundColor: AppTheme.deepLeafGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ ${result['message'] ?? 'Update failed.'}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;
    final payout = _toDouble(delivery['partner_payout']);
    final pickupPoints = delivery['pickup_points'] as List? ?? [];
    final customerName = delivery['customer_name'] ?? 'Customer';
    final deliveryAddress = delivery['delivery_address'] ?? '';
    final orderStatus = delivery['order_status'] ?? '';
    final latestTracking = delivery['latest_tracking'] as Map<String, dynamic>?;
    final currentTrackingStatus = latestTracking?['status'] ?? 'assigned';

    double? mapLat = _toDoubleOrNull(delivery['delivery_latitude']);
    double? mapLng = _toDoubleOrNull(delivery['delivery_longitude']);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.darkGreen, AppTheme.deepLeafGreen],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery['order_number'] ?? 'Order',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Text(
                        'Customer: $customerName',
                        style: const TextStyle(
                            color: AppTheme.lightMint, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LKR ${payout.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // Mini Google Map
          if (mapLat != null && mapLng != null)
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: SizedBox(
                height: 160,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(mapLat, mapLng),
                    zoom: 13,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId('destination'),
                      position: LatLng(mapLat, mapLng),
                      infoWindow: InfoWindow(title: 'Deliver to $customerName'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed),
                    ),
                    ...pickupPoints
                        .where((pp) =>
                            pp['pickup_lat'] != null &&
                            pp['pickup_lng'] != null)
                        .map((pp) => Marker(
                              markerId: MarkerId(
                                  'pickup_${pp['retailer_id'] ?? pp['shop_name']}'),
                              position: LatLng(
                                  _toDouble(pp['pickup_lat']),
                                  _toDouble(pp['pickup_lng'])),
                              infoWindow: InfoWindow(
                                  title: pp['retailer_name'] ??
                                      pp['shop_name'] ??
                                      'Shop'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueGreen),
                            )),
                  },
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup stops
                const Text('PICKUP STOPS',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                ...pickupPoints.map((pp) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppTheme.freshGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${pp['retailer_name'] ?? pp['shop_name'] ?? 'Shop'}${pp['shop_address'] != null ? ' – ${pp['shop_address']}' : ''}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        color: Colors.red, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        deliveryAddress,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Current status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.lightMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppTheme.deepLeafGreen),
                      const SizedBox(width: 6),
                      Text(
                        currentTrackingStatus.toUpperCase().replaceAll('_', ' '),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepLeafGreen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Status update buttons
                const Text('UPDATE STATUS:',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statusSteps.map((step) {
                    final isDelivered = step['status'] == 'delivered';
                    return _isUpdating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.deepLeafGreen))
                        : GestureDetector(
                            onTap: () => _updateStatus(step['status']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDelivered
                                    ? AppTheme.deepLeafGreen
                                    : AppTheme.softGray,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: isDelivered
                                        ? AppTheme.deepLeafGreen
                                        : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    step['icon'],
                                    size: 14,
                                    color: isDelivered
                                        ? Colors.white
                                        : AppTheme.deepLeafGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    step['label'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDelivered
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: Earnings & Wallet
// ─────────────────────────────────────────────────────────────────────────────
class _EarningsTab extends StatefulWidget {
  const _EarningsTab();

  @override
  State<_EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<_EarningsTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _wallet;
  Map<String, dynamic>? _summary;
  List<dynamic> _transactions = [];
  List<dynamic> _completedOrders = [];
  int _completedDeliveries = 0;
  int _selectedTab = 0; // 0=overview, 1=transactions, 2=deliveries

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getDeliveryEarnings();
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _wallet              = result['wallet'];
          _transactions        = result['transactions'] ?? [];
          _completedOrders     = result['completed_orders'] ?? [];
          _completedDeliveries = result['completed_deliveries'] ?? 0;
          _summary             = result['summary'];
          _isLoading           = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance      = _toDouble(_summary?['available_balance'] ?? _wallet?['available_balance']);
    final totalEarned  = _toDouble(_summary?['total_net_earned']  ?? _wallet?['total_earned']);
    final totalGross   = _toDouble(_summary?['total_gross_earned']);
    final totalComm    = _toDouble(_summary?['total_commission_paid']);
    final withdrawn    = _toDouble(_summary?['total_withdrawn']   ?? _wallet?['total_withdrawn']);

    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.deepLeafGreen,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero Wallet Card ────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1B3A2D), AppTheme.darkGreen, AppTheme.deepLeafGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_rounded,
                                  color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              const Text('WALLET BALANCE',
                                  style: TextStyle(
                                      color: AppTheme.lightMint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2)),
                              const Spacer(),
                              GestureDetector(
                                onTap: _load,
                                child: const Icon(Icons.refresh_rounded,
                                    color: Colors.white70, size: 20),
                              ),
                              const SizedBox(width: 14),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const DeliveryProfileScreen()),
                                  ).then((_) => _load());
                                },
                                child: const Icon(Icons.account_circle_outlined,
                                    color: Colors.white70, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'LKR ${balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 36,
                                letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_completedDeliveries deliveries completed',
                            style: const TextStyle(color: AppTheme.lightMint, fontSize: 12),
                          ),
                          const SizedBox(height: 20),
                          // 3 stat chips
                          Row(
                            children: [
                              Expanded(child: _heroChip('GROSS EARNED', 'LKR ${totalGross.toStringAsFixed(0)}')),
                              const SizedBox(width: 8),
                              Expanded(child: _heroChip('COMMISSION', '– LKR ${totalComm.toStringAsFixed(0)}')),
                              const SizedBox(width: 8),
                              Expanded(child: _heroChip('NET EARNED', 'LKR ${totalEarned.toStringAsFixed(0)}')),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Commission Info Banner ──────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: const Color(0xFFFFF8E1),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                                children: [
                                  TextSpan(
                                      text: '5% platform commission ',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(
                                      text: 'is deducted from each delivery fee. Your wallet shows net payout after commission.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Sub-tab switcher ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                      child: Row(
                        children: [
                          _subTabBtn('Overview', 0),
                          const SizedBox(width: 8),
                          _subTabBtn('Transactions', 1),
                          const SizedBox(width: 8),
                          _subTabBtn('Orders', 2),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Tab content ─────────────────────────────────────
                    if (_selectedTab == 0) _buildOverview(balance, totalGross, totalComm, totalEarned, withdrawn),
                    if (_selectedTab == 1) _buildTransactions(),
                    if (_selectedTab == 2) _buildCompletedOrders(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Overview tab ──────────────────────────────────────────────────────────
  Widget _buildOverview(double balance, double gross, double comm, double net, double withdrawn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards grid
          Row(
            children: [
              Expanded(child: _summaryCard('Available Balance', 'LKR ${balance.toStringAsFixed(2)}',
                  Icons.account_balance_wallet_rounded, AppTheme.deepLeafGreen)),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard('Total Withdrawn', 'LKR ${withdrawn.toStringAsFixed(2)}',
                  Icons.send_rounded, const Color(0xFF6366F1))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _summaryCard('Gross Earnings', 'LKR ${gross.toStringAsFixed(2)}',
                  Icons.trending_up_rounded, const Color(0xFF0891B2))),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard('Commission Paid', 'LKR ${comm.toStringAsFixed(2)}',
                  Icons.percent_rounded, const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 12),
          // Net payout breakdown card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EARNINGS BREAKDOWN',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 16),
                _breakdownRow('Gross Delivery Fees', 'LKR ${gross.toStringAsFixed(2)}', const Color(0xFF0891B2)),
                _breakdownRow('Platform Commission (5%)', '– LKR ${comm.toStringAsFixed(2)}', const Color(0xFFF59E0B)),
                const Divider(height: 24),
                _breakdownRow('Net Earnings', 'LKR ${net.toStringAsFixed(2)}', AppTheme.deepLeafGreen, bold: true),
                _breakdownRow('Withdrawn', '– LKR ${withdrawn.toStringAsFixed(2)}', const Color(0xFF6366F1)),
                const Divider(height: 24),
                _breakdownRow('Available Balance', 'LKR ${balance.toStringAsFixed(2)}', AppTheme.darkGreen, bold: true, large: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: balance >= 100 ? () => _showWithdrawSheet(balance) : null,
              icon: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 18),
              label: const Text(
                'REQUEST WITHDRAWAL',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepLeafGreen,
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          if (balance < 100) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Minimum withdrawal amount is LKR 100.00',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showWithdrawSheet(double availableBalance) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: availableBalance.toStringAsFixed(2));
    final bankNameController = TextEditingController();
    final bankBranchController = TextEditingController();
    final holderController = TextEditingController();
    final numberController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.deepLeafGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_rounded, color: AppTheme.deepLeafGreen, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Request Payout',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  'Max available: LKR ${availableBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Amount Field
                      const Text(
                        'WITHDRAWAL AMOUNT (LKR)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: 'LKR ',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter amount';
                          final amt = double.tryParse(val.trim());
                          if (amt == null) return 'Enter a valid number';
                          if (amt < 100) return 'Minimum withdrawal is LKR 100.00';
                          if (amt > availableBalance) return 'Insufficient balance';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Bank Name Field
                      const Text(
                        'BANK NAME',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: bankNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'e.g. Commercial Bank of Ceylon',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter bank name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Bank Branch Field
                      const Text(
                        'BANK BRANCH',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: bankBranchController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'e.g. Colombo Fort',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter branch name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Account Holder Name Field
                      const Text(
                        'ACCOUNT HOLDER NAME',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: holderController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Name as in bank account',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter account holder name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Account Number Field
                      const Text(
                        'ACCOUNT NUMBER',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter account number',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter account number' : null,
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    setSheetState(() => isSubmitting = true);
                                    
                                    final amt = double.parse(amountController.text.trim());
                                    final result = await ApiService.requestWithdrawal(
                                      amount: amt,
                                      bankName: bankNameController.text.trim(),
                                      bankBranch: bankBranchController.text.trim(),
                                      bankAccountHolderName: holderController.text.trim(),
                                      bankAccountNumber: numberController.text.trim(),
                                    );

                                    if (mounted) {
                                      Navigator.pop(context); // close bottom sheet
                                      
                                      if (result['success'] == true) {
                                        // Refresh the main earnings tab
                                        _load();
                                        
                                        // Show success pop up
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            title: const Text('✅ Payout Requested', style: TextStyle(fontWeight: FontWeight.w800)),
                                            content: const Text(
                                              'Your withdrawal request has been submitted and is pending review by administrators.',
                                              style: TextStyle(color: Color(0xFF475569)),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('OK', style: TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('❌ ${result['message'] ?? 'Failed to submit withdrawal request.'}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text(
                                  'SUBMIT REQUEST',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Transactions tab ──────────────────────────────────────────────────────
  Widget _buildTransactions() {
    if (_transactions.isEmpty) {
      return _emptyState(Icons.receipt_long_rounded, 'No transactions yet',
          'Complete a delivery to see your earnings here');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _transactions.map<Widget>((tx) {
          final amount   = _toDouble(tx['amount']);
          final desc     = tx['description'] ?? '';
          final type     = tx['transaction_type'] ?? 'other';
          final status   = tx['status'] ?? 'completed';
          final isCredit = amount > 0;
          final isComm   = type == 'commission';

          Color chipColor = isCredit ? AppTheme.deepLeafGreen : const Color(0xFFF59E0B);
          if (!isCredit && !isComm) chipColor = Colors.red;

          String timeStr = '';
          try {
            final dt = DateTime.parse(tx['created_at'] ?? '').toLocal();
            timeStr = '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (_) {}

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isComm ? Icons.percent_rounded
                        : isCredit ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: chipColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isComm ? '5% Platform Commission' : isCredit ? 'Delivery Payout' : 'Debit',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: chipColor),
                      ),
                      const SizedBox(height: 2),
                      Text(desc,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'completed' ? AppTheme.lightMint : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'completed' ? AppTheme.deepLeafGreen : Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isCredit ? '+' : ''}LKR ${amount.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: chipColor),
                    ),
                    const SizedBox(height: 4),
                    Text(timeStr, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Completed Orders tab ──────────────────────────────────────────────────
  Widget _buildCompletedOrders() {
    if (_completedOrders.isEmpty) {
      return _emptyState(Icons.local_shipping_rounded, 'No completed deliveries',
          'Accept and complete a delivery to see it here');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _completedOrders.map<Widget>((order) {
          final fee    = _toDouble(order['delivery_fee']);
          final comm   = _toDouble(order['commission']);
          final payout = _toDouble(order['payout']);
          final commPct = order['commission_pct'] ?? 5;

          String dateStr = '';
          try {
            final dt = DateTime.parse(order['delivered_at'] ?? '').toLocal();
            dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (_) {}

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.darkGreen, AppTheme.deepLeafGreen]),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order['order_number'] ?? 'Order',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(order['customer_name'] ?? '',
                              style: const TextStyle(color: AppTheme.lightMint, fontSize: 11)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('PAYOUT', style: TextStyle(color: AppTheme.lightMint, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text('LKR ${payout.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Detail rows
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _orderDetailRow('Delivery Fee', 'LKR ${fee.toStringAsFixed(2)}', const Color(0xFF0F172A)),
                      const SizedBox(height: 6),
                      _orderDetailRow('Platform Commission ($commPct%)', '– LKR ${comm.toStringAsFixed(2)}', const Color(0xFFF59E0B)),
                      const Divider(height: 16),
                      _orderDetailRow('Your Net Payout', 'LKR ${payout.toStringAsFixed(2)}', AppTheme.deepLeafGreen),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text('Delivered: $dateStr',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _subTabBtn(String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.deepLeafGreen : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [BoxShadow(color: AppTheme.deepLeafGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF64748B))),
      ),
    );
  }

  Widget _heroChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.lightMint, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, Color color, {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: large ? 14 : 12,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: bold ? const Color(0xFF0F172A) : const Color(0xFF64748B))),
          Text(value,
              style: TextStyle(
                  fontSize: large ? 15 : 13,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _orderDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 64, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

