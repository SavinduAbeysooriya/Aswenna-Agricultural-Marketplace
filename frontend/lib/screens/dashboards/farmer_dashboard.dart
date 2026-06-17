import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/screens/map_location_picker.dart';
import 'package:aswenna/screens/crop_picker_screen.dart';
import 'package:aswenna/screens/cultivation_logs/cultivation_logs_screen.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/chatbot/chatbot_screen.dart';
import 'package:aswenna/screens/harvest_listings/harvest_listing_form.dart';
import 'package:aswenna/screens/harvest_listings/harvest_listing_detail_screen.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _currentIndex = 0;
  bool _isLoadingProfile = true;
  String _profileError = '';
  Map<String, dynamic>? _profile;
  List<dynamic> _lands = [];
  bool _isLoadingLands = false;
  Map<String, dynamic>? _wallet;
  bool _isLoadingWallet = false;
  List<dynamic> _walletTransactions = [];

  Map<String, dynamic> get _user =>
      Map<String, dynamic>.from(_profile?['user'] ?? {});

  Map<String, dynamic> get _farmerData =>
      Map<String, dynamic>.from(_profile?['farmer_verification'] ?? {});

  bool get _isProfileIncomplete {
    if (_profile == null) return false;
    final phone = _text(_user['phone_number']);
    final hasDummyPhone = phone.startsWith('REG-') || phone.startsWith('G-');
    final hasNoLocation = _locationLabel == 'Location not set';
    return hasDummyPhone || hasNoLocation;
  }

  Future<void> _openProfileEditor() async {
    final updatedProfile = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => FarmerProfileEditScreen(profile: _profile),
      ),
    );
    if (updatedProfile != null && mounted) {
      _replaceProfile(updatedProfile);
    }
  }

  // Harvest Listings State
  List<dynamic> _harvestListings = [];
  bool _isLoadingHarvests = false;
  List<dynamic> _farmerBids = [];
  bool _isLoadingBids = false;
  int _yieldSubTab = 0; // 0 for Listings, 1 for Bids

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLands();
    _loadHarvestListings();
    _loadFarmerBids();
    _loadWalletDetails();
  }

  Future<void> _loadLands() async {
    setState(() => _isLoadingLands = true);
    final result = await ApiService.getFarmerLands();
    if (!mounted) return;
    setState(() {
      _lands = result['success'] == true ? List<dynamic>.from(result['lands'] ?? []) : [];
      _isLoadingLands = false;
    });
  }

  Future<void> _loadHarvestListings() async {
    setState(() => _isLoadingHarvests = true);
    final result = await ApiService.getFarmerHarvestListings();
    if (!mounted) return;
    setState(() {
      _harvestListings = result['success'] == true ? List<dynamic>.from(result['listings'] ?? []) : [];
      _isLoadingHarvests = false;
    });
  }

  Future<void> _loadFarmerBids() async {
    setState(() => _isLoadingBids = true);
    final result = await ApiService.getFarmerBids();
    if (!mounted) return;
    setState(() {
      _farmerBids = result['success'] == true ? List<dynamic>.from(result['bids'] ?? []) : [];
      _isLoadingBids = false;
    });
  }

  Future<void> _loadWalletDetails() async {
    setState(() => _isLoadingWallet = true);
    final result = await ApiService.getWalletDetails();
    if (!mounted) return;
    setState(() {
      _wallet = result['success'] == true ? Map<String, dynamic>.from(result['wallet'] ?? {}) : null;
      _walletTransactions = result['success'] == true ? List<dynamic>.from(result['transactions'] ?? []) : [];
      _isLoadingWallet = false;
    });
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = '';
    });

    final result = await ApiService.getFarmerProfile();
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _profile = Map<String, dynamic>.from(result['profile'] ?? {});
        _isLoadingProfile = false;
      });
    } else {
      setState(() {
        _profileError = result['message'] ?? 'Failed to load farmer profile.';
        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: AppTheme.pureWhite,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            InkWell(
              customBorder: const CircleBorder(),
              onTap: _openProfile,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.deepLeafGreen.withValues(alpha: 0.3), width: 1.5),
                ),
                child: CircleAvatar(
                  backgroundColor: AppTheme.lightMint,
                  backgroundImage: _profileImageUrl == null
                      ? null
                      : NetworkImage(_profileImageUrl!),
                  child: _profileImageUrl == null
                      ? const Icon(Icons.person, color: AppTheme.deepLeafGreen)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hello, $_firstName !',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: AppTheme.deepLeafGreen),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _locationLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Notifications',
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF1E293B),
                size: 22,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.deepLeafGreen,
        onRefresh: () async {
          await _loadProfile();
          await _loadLands();
          await _loadHarvestListings();
          await _loadFarmerBids();
          await _loadWalletDetails();
        },
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            _buildLandsTab(),
            _buildYieldsTab(),
            _buildWalletTab(),
            const CultivationLogsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.deepLeafGreen, AppTheme.darkGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepLeafGreen.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          tooltip: 'AI Agent',
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  String get _firstName {
    final name = _text(_user['full_name'], fallback: 'Farmer');
    return name.split(' ').first;
  }

  String get _locationLabel {
    final district = _text(_user['district']);
    final province = _text(_user['province']);
    if (district != '-') return district;
    if (province != '-') return province;
    return 'Location not set';
  }

  String? get _profileImageUrl {
    final path = _text(_user['profile_picture_path']);
    if (path == '-') return null;
    return ApiService.fileUrl(path);
  }

  Widget _buildProfileIncompleteBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFBEB), // Amber 50
            Color(0xFFFEF3C7), // Amber 100
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFDE68A), // Amber 200
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withOpacity(0.06), // Amber shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15), // Amber icon bg
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFB45309), // Amber 700
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Incomplete',
                      style: TextStyle(
                        color: Color(0xFF78350F), // Amber 900
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please complete your phone number and location details to unlock all trading and land management features.',
                      style: TextStyle(
                        color: const Color(0xFF92400E).withOpacity(0.9), // Amber 800
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton.icon(
              onPressed: _openProfileEditor,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD97706), // Amber 600
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Text(
                'Complete Now',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              label: const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final String availableBalance = double.tryParse(_wallet?['available_balance']?.toString() ?? '0')
            ?.toStringAsFixed(2) ?? '0.00';
    final String totalEarned = double.tryParse(_wallet?['total_earned']?.toString() ?? '0')
            ?.toStringAsFixed(2) ?? '0.00';
    final String pendingBalance = double.tryParse(_wallet?['pending_balance']?.toString() ?? '0')
            ?.toStringAsFixed(2) ?? '0.00';

    return _scrollTab(
      children: [
        if (_isLoadingProfile || _isLoadingWallet) const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LinearProgressIndicator(minHeight: 3, color: AppTheme.deepLeafGreen),
        ),
        if (_profileError.isNotEmpty) _buildErrorBanner(),
        if (_isProfileIncomplete) _buildProfileIncompleteBanner(),
        
        // --- Wallet & Earnings Hero Widget ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.darkGreen, AppTheme.deepLeafGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepLeafGreen.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'AVAILABLE BALANCE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => setState(() => _currentIndex = 3),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Wallet',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'LKR $availableBalance',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL NET EARNED',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'LKR $totalEarned',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 28, color: Colors.white24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PENDING ESCROW',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'LKR $pendingBalance',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Activity Summary Grid ---
        const Text(
          'Activity Summary',
          style: TextStyle(
            color: AppTheme.darkGreen,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildHomeSummaryCard(
                'Registered\nLands',
                '${_lands.length}',
                Icons.terrain_rounded,
                AppTheme.accentGold,
                () => setState(() => _currentIndex = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHomeSummaryCard(
                'Active Crop\nYields',
                '${_harvestListings.length}',
                Icons.eco_rounded,
                AppTheme.deepLeafGreen,
                () => setState(() => _currentIndex = 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHomeSummaryCard(
                'Incoming\nBids',
                '${_farmerBids.length}',
                Icons.gavel_rounded,
                const Color(0xFF0284C7),
                () {
                  setState(() {
                    _currentIndex = 2;
                    _yieldSubTab = 1;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- Recent Crop Listings Section ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Recent Yields',
              style: TextStyle(
                color: AppTheme.darkGreen,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_harvestListings.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _currentIndex = 2),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_harvestListings.isEmpty)
          _buildEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No active yields yet',
            subtitle: 'Create your first crop yield listing when harvest is ready.',
          )
        else
          ..._harvestListings.take(3).map((listing) => _buildRecentListingCard(listing)),
      ],
    );
  }

  Widget _buildHomeSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepLeafGreen.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Icon(Icons.arrow_outward_rounded, size: 12, color: Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentListingCard(dynamic listing) {
    final String cropName = listing['cropname']?.toString() ?? 'Crop';
    final String grade = listing['grade']?.toString() ?? 'A';
    final String price = listing['price_per_unit']?.toString() ?? '0.00';
    final String qty = listing['available_quantity']?.toString() ?? '0';
    final String unit = listing['unit']?.toString() ?? 'kg';
    final String status = listing['status']?.toString() ?? 'active';

    Color statusColor = AppTheme.deepLeafGreen;
    if (status == 'draft') statusColor = Colors.grey;
    if (status == 'pending_approval') statusColor = AppTheme.accentGold;
    if (status == 'rejected') statusColor = Colors.red;

    final String? imageUrl = listing['image_1'] ?? listing['crop_image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          final id = int.tryParse(listing['id']?.toString() ?? '');
          if (id == null) return;
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HarvestListingDetailScreen(
                listingId: id,
                role: 'farmer',
              ),
            ),
          );
          if (refresh == true) {
            _loadHarvestListings();
            _loadFarmerBids();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(ApiService.fileUrl(imageUrl) ?? ''),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cropName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Grade $grade',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Color(0xFF0369A1),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$qty $unit  •  LKR $price/$unit',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandsTab() {
    return _scrollTab(
      children: [
        _buildSectionHeader('Land Portfolio', 'Add Land', () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddLandScreen()),
          );
          if (added == true) {
            _loadLands();
            _loadProfile();
          }
        }),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.landscape_rounded, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              'Total Registered: ${_text(_farmerData['total_lands'], fallback: '0')} Lands',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingLands)
          const Center(child: CircularProgressIndicator())
        else if (_lands.isEmpty)
          _buildEmptyState(
            icon: Icons.add_location_alt_outlined,
            title: 'No lands registered yet',
            subtitle: 'Tap "Add Land" to register your first land parcel.',
          )
        else
          for (final land in _lands) _buildLandCard(Map<String, dynamic>.from(land)),
      ],
    );
  }

  Widget _buildLandCard(Map<String, dynamic> land) {
    final status = land['status']?.toString() ?? 'pending';
    final statusColor = status == 'verified'
        ? const Color(0xFF10B981)
        : status == 'rejected'
            ? Colors.red
            : AppTheme.accentGold;
    final statusIcon = status == 'verified'
        ? Icons.verified_rounded
        : status == 'rejected'
            ? Icons.cancel_rounded
            : Icons.hourglass_top_rounded;

    Future<void> _openCropPicker() async {
      final landId = int.tryParse(land['id']?.toString() ?? '');
      if (landId == null) return;

      final current = <int>{};
      final crops = land['crops'];
      if (crops is List) {
        for (final item in crops) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final cropId = int.tryParse(map['crop_id']?.toString() ?? '');
            if (cropId != null) current.add(cropId);
          }
        }
      }

      final selected = await Navigator.of(context).push<Set<int>>(
        MaterialPageRoute(
          builder: (_) => CropPickerScreen(
            initialSelectedIds: current,
            title: 'Select Land Crops',
          ),
        ),
      );

      if (!mounted || selected == null) return;

      final keepImages = <String>[];
      final landImages = land['land_images'];
      if (landImages is List) {
        for (final item in landImages) {
          final path = item?.toString().trim() ?? '';
          if (path.isNotEmpty) keepImages.add(path);
        }
      }

      final keepDocs = <Map<String, dynamic>>[];
      final landDocs = land['land_documents'];
      if (landDocs is List) {
        for (final item in landDocs) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final path = (map['path'] ?? '').toString().trim();
            if (path.isEmpty) continue;
            keepDocs.add({
              'title': (map['title'] ?? '').toString(),
              'path': path,
            });
          }
        }
      }

      final payload = <String, dynamic>{
        'size': land['size'],
        'ownership_type': land['ownership_type'],
        'registration_number': land['registration_number'],
        'latitude': land['latitude'],
        'longitude': land['longitude'],
        'notes': land['notes'],
      };

      final result = await ApiService.updateFarmerLand(
        landId,
        payload,
        keepImagePaths: keepImages,
        keepDocuments: keepDocs,
        cropIds: selected.toList(),
      );

      if (!mounted) return;
      if (result['success'] == true) {
        _loadLands();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Land crops updated. Status set to Pending for approval.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update land crops.')),
        );
      }
    }

    final crops = land['crops'] as List?;
    final cropCount = crops?.length ?? 0;

    return InkWell(
      onTap: () async {
        final landId = int.tryParse(land['id']?.toString() ?? '');
        if (landId == null) return;
        final updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => EditLandScreen(landId: landId, land: land),
          ),
        );
        if (updated == true) {
          _loadLands();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Land updated. Status set to Pending for approval.'),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepLeafGreen.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.lightMint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.terrain_rounded, color: AppTheme.deepLeafGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${land['size']} Perches · ${_ownershipLabel(land['ownership_type'])}',
                            style: const TextStyle(
                              color: AppTheme.darkGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (cropCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.lightMint,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$cropCount Crops',
                                style: const TextStyle(
                                  color: AppTheme.deepLeafGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (land['registration_number'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Reg: ${land['registration_number']}',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (land['latitude'] != null && land['longitude'] != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              '${double.tryParse(land['latitude'].toString())?.toStringAsFixed(5)}, '
                              '${double.tryParse(land['longitude'].toString())?.toStringAsFixed(5)}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'Crops',
                        onPressed: _openCropPicker,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        icon: const Icon(Icons.grass_outlined, size: 18, color: Color(0xFF475569)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'Edit',
                        onPressed: () async {
                          final landId = int.tryParse(land['id']?.toString() ?? '');
                          if (landId == null) return;
                          final updated = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => EditLandScreen(landId: landId, land: land),
                            ),
                          );
                          if (updated == true) {
                            _loadLands();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Land updated. Status set to Pending for approval.'),
                              ),
                            );
                          }
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (land['notes'] != null && land['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  land['notes'].toString(),
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _ownershipLabel(dynamic type) {
    const labels = {
      'owned': 'Owned',
      'license': 'Licensed',
      'lease': 'Leased',
      'government': 'Government',
      'other': 'Other',
    };
    return labels[type?.toString()] ?? (type?.toString() ?? '-');
  }

  Widget _buildYieldsTab() {
    return _scrollTab(
      children: [
        _buildSectionHeader('Yield Listings', 'New Listing', () async {
          final success = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const HarvestListingForm()),
          );
          if (success == true) {
            _loadHarvestListings();
          }
        }),
        Row(
          children: [
            _buildYieldSubTabChip(0, 'My Listings'),
            const SizedBox(width: 8),
            _buildYieldSubTabChip(1, 'Incoming Bids'),
          ],
        ),
        const SizedBox(height: 16),
        if (_yieldSubTab == 0) ...[
          if (_isLoadingHarvests)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen)),
            )
          else if (_harvestListings.isEmpty)
            _buildEmptyState(
              icon: Icons.eco_outlined,
              title: 'No yield listings',
              subtitle: 'Your active harvest listings and bids will appear here.',
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _harvestListings.length,
              itemBuilder: (context, index) {
                final listing = _harvestListings[index];
                final String cropName = listing['cropname']?.toString() ?? 'Crop';
                final String grade = listing['grade']?.toString() ?? 'A';
                final String price = listing['price_per_unit']?.toString() ?? '0.00';
                final String qty = listing['available_quantity']?.toString() ?? '0';
                final String unit = listing['unit']?.toString() ?? 'kg';
                final String status = listing['status']?.toString() ?? 'active';
                
                // Status Styling
                Color statusColor = AppTheme.deepLeafGreen;
                if (status == 'draft') statusColor = Colors.grey;
                if (status == 'pending_approval') statusColor = AppTheme.accentGold;
                if (status == 'rejected') statusColor = Colors.red;

                final String? imageUrl = listing['image_1'] ?? listing['crop_image'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () async {
                      final id = int.tryParse(listing['id']?.toString() ?? '');
                      if (id == null) return;
                      final refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HarvestListingDetailScreen(
                            listingId: id,
                            role: 'farmer',
                          ),
                        ),
                      );
                      if (refresh == true) {
                        _loadHarvestListings();
                        _loadFarmerBids();
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.deepLeafGreen.withValues(alpha: 0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              image: imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(ApiService.fileUrl(imageUrl) ?? ''),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: imageUrl == null
                                ? Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppTheme.lightMint, AppTheme.lightMint.withOpacity(0.5)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 28),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cropName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Grade $grade',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF0369A1),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Quantity: $qty $unit',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'LKR $price / $unit',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.deepLeafGreen,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
                                      ),
                                      child: Text(
                                        status.toUpperCase().replaceAll('_', ' '),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ] else ...[
          if (_isLoadingBids)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen)),
            )
          else if (_farmerBids.isEmpty)
            _buildEmptyState(
              icon: Icons.gavel_rounded,
              title: 'No bids received',
              subtitle: 'Bidding offers from buyers on your listings will appear here.',
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _farmerBids.length,
              itemBuilder: (context, index) {
                final bid = _farmerBids[index];
                final String cropName = bid['cropname']?.toString() ?? 'Crop';
                final String buyerName = bid['buyer_name']?.toString() ?? 'Buyer';
                final String bidPrice = bid['bid_amount_per_unit']?.toString() ?? '0.00';
                final String qty = bid['bid_quantity_unit']?.toString() ?? '0';
                final String unit = bid['unit']?.toString() ?? 'kg';
                final String status = bid['status']?.toString() ?? 'pending';

                Color statusColor = AppTheme.deepLeafGreen;
                if (status == 'pending') statusColor = AppTheme.accentGold;
                if (status == 'rejected') statusColor = Colors.red;

                final String? imageUrl = bid['crop_image'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () async {
                      final listingId = int.tryParse(bid['harvest_listing_id']?.toString() ?? '');
                      if (listingId == null) return;
                      final refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HarvestListingDetailScreen(
                            listingId: listingId,
                            role: 'farmer',
                          ),
                        ),
                      );
                      if (refresh == true) {
                        _loadHarvestListings();
                        _loadFarmerBids();
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.deepLeafGreen.withValues(alpha: 0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              image: imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(ApiService.fileUrl(imageUrl) ?? ''),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: imageUrl == null
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(Icons.gavel_rounded, color: AppTheme.accentGold, size: 28),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cropName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: statusColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Bidder: ',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      buyerName,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bid Qty: $qty $unit',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Bid Rate: LKR $bidPrice / $unit',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.deepLeafGreen,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildYieldSubTabChip(int index, String label) {
    final isSelected = _yieldSubTab == index;
    final accentColor = AppTheme.deepLeafGreen;
    return InkWell(
      onTap: () {
        setState(() => _yieldSubTab = index);
        if (index == 1) {
          _loadFarmerBids();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletTab() {
    final String availableBalance = double.tryParse(_wallet?['available_balance']?.toString() ?? '0')
            ?.toStringAsFixed(2) ?? '0.00';
    final String pendingBalance = double.tryParse(_wallet?['pending_balance']?.toString() ?? '0')
            ?.toStringAsFixed(2) ?? '0.00';

    return _scrollTab(
      children: [
        _buildSectionTitle('Wallet'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Available',
                'LKR $availableBalance',
                Icons.savings_rounded,
                AppTheme.deepLeafGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Pending Escrow',
                'LKR $pendingBalance',
                Icons.pending_actions_rounded,
                AppTheme.accentGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Recent Transactions',
          style: TextStyle(
            color: AppTheme.darkGreen,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (_walletTransactions.isEmpty)
          _buildEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No wallet activity',
            subtitle: 'Completed sales and withdrawals will appear here.',
          )
        else
          Column(
            children: _walletTransactions.map((tx) => _buildTransactionCard(tx)).toList(),
          ),
      ],
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
    final double amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final String description = tx['description']?.toString() ?? 'Transaction';
    final String status = tx['status']?.toString() ?? 'completed';
    final String dateStr = tx['created_at']?.toString() ?? '';

    final isIncome = amount > 0;
    final displayAmount = (isIncome ? '+' : '') + ' LKR ' + amount.abs().toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncome ? AppTheme.deepLeafGreen.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
              color: isIncome ? AppTheme.deepLeafGreen : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      dateStr.split('T').first,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'completed' ? const Color(0xFFE6F4EA) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: status == 'completed' ? const Color(0xFF137333) : const Color(0xFFB06000),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            displayAmount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isIncome ? AppTheme.deepLeafGreen : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scrollTab({required List<Widget> children}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: children,
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.deepLeafGreen, AppTheme.darkGreen, Color(0xFF0F3E10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24,
            bottom: -36,
            child: Icon(
              Icons.eco_rounded,
              color: Colors.white.withValues(alpha: 0.09),
              size: 160,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'WEATHER FORECAST',
                    style: TextStyle(
                      color: Color(0xFFF1F8E9),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                '28°C · Sunny Intervals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Perfect day for harvesting and updating land logs.',
                style: TextStyle(
                  color: const Color(0xFFF1F8E9).withOpacity(0.9),
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final accentColor = AppTheme.deepLeafGreen;
    final displayColor = color == AppTheme.accentGold ? const Color(0xFFF59E0B) : accentColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: displayColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<_InfoRow> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.deepLeafGreen),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.darkGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final row in rows) _buildProfileRow(row.label, row.value),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.darkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _profileError,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionLabel,
    VoidCallback onAction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle(title),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: AppTheme.deepLeafGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.darkGreen,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
          _buildBottomNavItem(1, Icons.landscape_rounded, Icons.landscape_outlined, 'Lands'),
          _buildBottomNavItem(2, Icons.inventory_2_rounded, Icons.inventory_2_outlined, 'Yields'),
          _buildBottomNavItem(3, Icons.wallet_rounded, Icons.wallet_outlined, 'Wallet'),
          _buildBottomNavItem(4, Icons.note_alt_rounded, Icons.note_alt_outlined, 'Logs'),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final isSelected = _currentIndex == index;
    final accentColor = AppTheme.deepLeafGreen;
    
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(24),
      child: isSelected
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                selectedIcon,
                color: Colors.white,
                size: 22,
              ),
            )
          : Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                unselectedIcon,
                color: const Color(0xFF94A3B8),
                size: 22,
              ),
            ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FarmerProfileScreen(
          profile: _profile,
          isLoading: _isLoadingProfile,
          errorMessage: _profileError,
          onRefresh: _loadProfile,
          onLogout: _logout,
          onProfileUpdated: _replaceProfile,
          onViewTransactions: () {
            setState(() {
              _currentIndex = 3; // Switch to Wallet tab
            });
          },
        ),
      ),
    );
  }

  void _replaceProfile(Map<String, dynamic> profile) {
    setState(() {
      _profile = profile;
      _profileError = '';
      _isLoadingProfile = false;
    });
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  String _text(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class FarmerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final String errorMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;
  final void Function(Map<String, dynamic> profile) onProfileUpdated;
  final VoidCallback? onViewTransactions;

  const FarmerProfileScreen({
    super.key,
    required this.profile,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onLogout,
    required this.onProfileUpdated,
    this.onViewTransactions,
  });

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  late Map<String, dynamic>? _profile;
  late bool _isLoading;
  late String _errorMessage;

  Map<String, dynamic>? _wallet;
  List<dynamic> _lands = [];
  bool _isLoadingWallet = false;
  bool _isLoadingLands = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _isLoading = widget.isLoading;
    _errorMessage = widget.errorMessage;
    _loadWalletAndLandsDetails();
  }

  Map<String, dynamic> get _user =>
      Map<String, dynamic>.from(_profile?['user'] ?? {});

  Map<String, dynamic> get _farmerData =>
      Map<String, dynamic>.from(_profile?['farmer_verification'] ?? {});

  List<dynamic> get _documents =>
      List<dynamic>.from(_profile?['documents'] ?? const []);

  List<_VerificationDocumentItem> get _verificationDocuments {
    final items = <_VerificationDocumentItem>[
      _VerificationDocumentItem(
        title: 'Farming License',
        number: _text(_farmerData['farming_license_number']),
        path: _text(
          _farmerData['farming_license_url'] ??
              _farmerData['farming_license_path'],
        ),
      ),
      _VerificationDocumentItem(
        title: 'Organic Certificate',
        number: _text(_farmerData['organic_certificate_number']),
        path: _text(
          _farmerData['organic_certificate_url'] ??
              _farmerData['organic_certificate_path'],
        ),
        expiry: _text(_farmerData['organic_certificate_expiry']),
      ),
      _VerificationDocumentItem(
        title: 'GAP Certificate',
        number: _text(_farmerData['gap_certificate_number']),
        path: _text(
          _farmerData['gap_certificate_url'] ??
              _farmerData['gap_certificate_path'],
        ),
        expiry: _text(_farmerData['gap_certificate_expiry']),
      ),
    ];

    final otherCertificates = _farmerData['other_certificates'];
    if (otherCertificates is List) {
      for (final certificate in otherCertificates) {
        final item = Map<String, dynamic>.from(certificate);
        items.add(
          _VerificationDocumentItem(
            title: _text(item['title'], fallback: 'Other Certificate'),
            path: _text(item['url'] ?? item['path']),
          ),
        );
      }
    }

    return items;
  }

  Future<void> _loadWalletAndLandsDetails() async {
    if (mounted) {
      setState(() {
        _isLoadingWallet = true;
        _isLoadingLands = true;
      });
    }
    try {
      final walletResult = await ApiService.getWalletDetails();
      final landsResult = await ApiService.getFarmerLands();
      if (!mounted) return;
      setState(() {
        _wallet = walletResult['success'] == true ? Map<String, dynamic>.from(walletResult['wallet'] ?? {}) : null;
        _lands = landsResult['success'] == true ? List<dynamic>.from(landsResult['lands'] ?? []) : [];
        _isLoadingWallet = false;
        _isLoadingLands = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
          _isLoadingLands = false;
        });
      }
    }
  }

  String? get _profileImageUrl {
    final path = _text(_user['profile_picture_path']);
    if (path == '-') return null;
    return ApiService.fileUrl(path);
  }

  LatLng? get _profileLatLng {
    final lat = double.tryParse(_text(_user['latitude']));
    final lng = double.tryParse(_text(_user['longitude']));
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Profile',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.darkGreen),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.deepLeafGreen,
        onRefresh: _refreshProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 3),
            if (_errorMessage.isNotEmpty) _buildErrorBanner(_errorMessage),
            
            // Premium Header Row
            Row(
              children: [
                const Text(
                  'My profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _openEditor,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.freshGreen.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.deepLeafGreen,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Avatar & Details Column
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.lightMint,
                    backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                    child: _profileImageUrl == null
                        ? Text(
                            _initials(_text(_user['full_name'], fallback: 'Farmer')),
                            style: const TextStyle(
                              color: AppTheme.deepLeafGreen,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _text(_user['full_name'], fallback: 'Farmer'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_text(_user['email'])} | ${_text(_user['phone_number'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildVerificationBadge(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Details Card
            _buildAccountDetailsCard(),
            const SizedBox(height: 20),

            // Custom styled menu list tiles
            _buildMenuTile(
              icon: Icons.home_work_rounded,
              iconColor: const Color(0xFF2E7D32),
              iconBgColor: const Color(0xFFE8F5E9),
              title: 'Farm Address',
              subtitle: 'Manage physical farming address details',
              onTap: _showAddressBottomSheet,
            ),
            _buildMenuTile(
              icon: Icons.map_rounded,
              iconColor: const Color(0xFF1565C0),
              iconBgColor: const Color(0xFFE3F2FD),
              title: 'GPS Coordinates & Map',
              subtitle: 'View coordinates and pinned farm location',
              onTap: _showGPSLocationBottomSheet,
            ),
            _buildMenuTile(
              icon: Icons.assignment_turned_in_rounded,
              iconColor: const Color(0xFF7B1FA2),
              iconBgColor: const Color(0xFFF3E5F5),
              title: 'Verification Documents',
              subtitle: 'Farming license, GAP & Organic certificates',
              onTap: _showDocumentsBottomSheet,
            ),
            _buildMenuTile(
              icon: Icons.security_rounded,
              iconColor: const Color(0xFFF57F17),
              iconBgColor: const Color(0xFFFFF8E1),
              title: 'Account Security',
              subtitle: 'Manage account access details',
              onTap: _showSecurityBottomSheet,
            ),
            const SizedBox(height: 12),
            _buildLogoutTile(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await ApiService.getFarmerProfile();
    if (!mounted) return;

    if (result['success'] == true) {
      final profile = Map<String, dynamic>.from(result['profile'] ?? {});
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
      widget.onProfileUpdated(profile);
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load farmer profile.';
        _isLoading = false;
      });
    }

    await widget.onRefresh();
    await _loadWalletAndLandsDetails();
  }

  Future<void> _openEditor() async {
    final updatedProfile = await Navigator.of(context)
        .push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (context) => FarmerProfileEditScreen(profile: _profile),
          ),
        );

    if (updatedProfile == null || !mounted) return;

    setState(() {
      _profile = updatedProfile;
      _errorMessage = '';
    });
    widget.onProfileUpdated(updatedProfile);
  }

  Widget _buildVerificationBadge() {
    final isVerified = _user['is_verified'] == true || _user['is_verified'] == 1 || _user['is_verified'] == '1';
    final color = isVerified ? AppTheme.freshGreen : const Color(0xFFF59E0B);
    final bgColor = isVerified ? AppTheme.freshGreen.withValues(alpha: 0.1) : const Color(0xFFFEF3C7);
    final label = isVerified ? 'Verified Farmer' : 'Pending Verification';
    final icon = isVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsCard() {
    final phone = _text(_user['phone_number']);
    final phone2 = _text(_user['phone_number_2']);
    final nationalId = _text(_user['national_id']);
    final email = _text(_user['email']);
    final fullName = _text(_user['full_name'], fallback: 'Farmer');
    final walletBalance = double.tryParse(_wallet?['available_balance']?.toString() ?? '0') ?? 0.0;
    final walletDisplay = 'LKR ${walletBalance.toStringAsFixed(2)}';
    final landsCount = _lands.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Account details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (widget.onViewTransactions != null) {
                    Navigator.of(context).pop();
                    widget.onViewTransactions!();
                  }
                },
                child: const Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.deepLeafGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$fullName ($phone)',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.content_copy_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          if (email != '-' || phone2 != '-' || nationalId != '-') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
              ),
              child: Column(
                children: [
                  if (email != '-')
                    _buildDetailRow(Icons.email_outlined, 'Email', email),
                  if (phone2 != '-') ...[
                    if (email != '-') const SizedBox(height: 8),
                    _buildDetailRow(Icons.phone_iphone_outlined, 'Second Phone', phone2),
                  ],
                  if (nationalId != '-') ...[
                    if (email != '-' || phone2 != '-') const SizedBox(height: 8),
                    _buildDetailRow(Icons.credit_card_outlined, 'National ID', nationalId),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account balance',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _isLoadingWallet
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : Text(
                            walletDisplay,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                  ],
                ),
              ),
              Container(
                height: 32,
                width: 1,
                color: const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registered lands',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _isLoadingLands
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : Text(
                            '$landsCount ${landsCount == 1 ? 'Land' : 'Lands'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
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
            color: Colors.black.withValues(alpha: 0.01),
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
              ...children,
            ],
          ),
        );
      },
    );
  }

  void _showAddressBottomSheet() {
    _showModalSheet(
      title: 'Farm Address',
      children: [
        _buildSheetRow('Address', _text(_user['address'])),
        _buildSheetRow('City', _text(_user['city'])),
        _buildSheetRow('District', _text(_user['district'])),
        _buildSheetRow('Province', _text(_user['province'])),
      ],
    );
  }

  Widget _buildSheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
        ],
      ),
    );
  }

  void _showGPSLocationBottomSheet() {
    final position = _profileLatLng;
    _showModalSheet(
      title: 'GPS Coordinates & Map',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 220,
            child: position == null
                ? Container(
                    color: const Color(0xFFF8FAFC),
                    alignment: Alignment.center,
                    child: const Text(
                      'No pinned location yet.',
                      style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: position,
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('farm_location_sheet'),
                        position: position,
                      ),
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GPS Coordinates',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 4),
                Text(
                  position == null
                      ? 'Not Set'
                      : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            if (position != null)
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: '${position.latitude}, ${position.longitude}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coordinates copied to clipboard!')),
                  );
                },
                icon: const Icon(Icons.content_copy_rounded, color: Color(0xFF94A3B8), size: 18),
              ),
          ],
        ),
      ],
    );
  }

  void _showDocumentsBottomSheet() {
    final verificationDocuments = _verificationDocuments
        .where((document) => document.hasAnyData)
        .toList();

    _showModalSheet(
      title: 'Verification Documents',
      children: [
        if (verificationDocuments.isNotEmpty) ...[
          for (final doc in verificationDocuments) _buildDocSheetRow(doc),
          const SizedBox(height: 10),
        ],
        if (_documents.isNotEmpty) ...[
          const Text(
            'General Uploads',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          for (final item in _documents) _buildDocSheetRowGeneral(Map<String, dynamic>.from(item)),
        ],
        if (verificationDocuments.isEmpty && _documents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No verification documents uploaded yet.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildDocSheetRow(_VerificationDocumentItem doc) {
    final canOpen = doc.path != '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_rounded, color: AppTheme.deepLeafGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (doc.number != '-') doc.number,
                    if (doc.expiry != '-') 'Expires ${doc.expiry}',
                    if (!canOpen) 'No file uploaded',
                  ].join(' - '),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (canOpen)
            IconButton(
              onPressed: () => _openDocument(doc.path),
              icon: const Icon(Icons.visibility_rounded, color: AppTheme.deepLeafGreen, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildDocSheetRowGeneral(Map<String, dynamic> document) {
    final status = _text(document['verification_status'], fallback: 'pending');
    final type = _text(document['document_type']);
    final isVerified = status.toLowerCase() == 'verified';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.insert_drive_file_rounded, color: AppTheme.deepLeafGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isVerified ? const Color(0xFF15803D) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openDocument(
              document['front_image_url'] ?? document['front_image_path'],
            ),
            icon: const Icon(Icons.visibility_rounded, color: AppTheme.deepLeafGreen, size: 20),
          ),
        ],
      ),
    );
  }

  void _showSecurityBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;
    String? localError;
    String? localSuccess;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: formKey,
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
                            const Text(
                              'Account Security',
                              style: TextStyle(
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
                        const SizedBox(height: 16),
                        if (localError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFEE2E2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    localError!,
                                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (localSuccess != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, color: AppTheme.deepLeafGreen, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    localSuccess!,
                                    style: const TextStyle(color: AppTheme.darkGreen, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        const Text(
                          'Change Password',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 12),
                        // Current Password
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: obscureCurrent,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Current password is required.';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.deepLeafGreen, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF64748B)),
                              onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.freshGreen, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // New Password
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'New password is required.';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }
                            if (value == currentPasswordController.text) {
                              return 'New password must be different.';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppTheme.deepLeafGreen, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF64748B)),
                              onPressed: () => setModalState(() => obscureNew = !obscureNew),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.freshGreen, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Confirm Password
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password.';
                            }
                            if (value != newPasswordController.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.gpp_good_outlined, color: AppTheme.deepLeafGreen, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF64748B)),
                              onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.freshGreen, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setModalState(() {
                                      isLoading = true;
                                      localError = null;
                                      localSuccess = null;
                                    });
                                    final res = await ApiService.changePassword(
                                      currentPasswordController.text,
                                      newPasswordController.text,
                                      confirmPasswordController.text,
                                    );
                                    setModalState(() {
                                      isLoading = false;
                                      if (res['success'] == true) {
                                        localSuccess = 'Password changed successfully!';
                                        currentPasswordController.clear();
                                        newPasswordController.clear();
                                        confirmPasswordController.clear();
                                      } else {
                                        localError = res['message'] ?? 'Failed to change password.';
                                      }
                                    });
                                  },
                            icon: isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                            label: Text(
                              isLoading ? 'Updating Password...' : 'Update Password',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.darkGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogoutTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.03),
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
          decoration: const BoxDecoration(
            color: Color(0xFFFEE2E2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF991B1B),
          ),
        ),
        subtitle: const Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Sign out securely from Aswenna',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFFFCA5A5),
          size: 16,
        ),
        onTap: _showLogoutConfirmationDialog,
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 10),
              Text(
                'Log Out?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out from your Aswenna farmer account?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Yes, Log Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openDocument(dynamic pathOrUrl) async {
    final url = ApiService.fileUrl(pathOrUrl);
    if (url == null) return;

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this document.')),
      );
    }
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _text(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'F';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class FarmerProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const FarmerProfileEditScreen({super.key, required this.profile});

  @override
  State<FarmerProfileEditScreen> createState() =>
      _FarmerProfileEditScreenState();
}

class _FarmerProfileEditScreenState extends State<FarmerProfileEditScreen> {
  static const LatLng _defaultLocation = LatLng(7.8731, 80.7718);

  static const List<String> _provincesList = [
    'Central',
    'Eastern',
    'North Central',
    'Northern',
    'North Western',
    'Sabaragamuwa',
    'Southern',
    'Uva',
    'Western',
  ];

  static const Map<String, List<String>> _districtsMap = {
    'Central': ['Kandy', 'Matale', 'Nuwara Eliya'],
    'Eastern': ['Ampara', 'Batticaloa', 'Trincomalee'],
    'North Central': ['Anuradhapura', 'Polonnaruwa'],
    'Northern': ['Jaffna', 'Kilinochchi', 'Mannar', 'Mullaitivu', 'Vavuniya'],
    'North Western': ['Kurunegala', 'Puttalam'],
    'Sabaragamuwa': ['Kegalle', 'Ratnapura'],
    'Southern': ['Galle', 'Hambantota', 'Matara'],
    'Uva': ['Badulla', 'Moneragala'],
    'Western': ['Colombo', 'Gampaha', 'Kalutara'],
  };

  static const Map<String, List<String>> _citiesMap = {
    'Colombo': ['Colombo', 'Dehiwala-Mount Lavinia', 'Moratuwa', 'Sri Jayawardenepura Kotte', 'Kaduwela', 'Kolonnawa', 'Avissawella', 'Hanwella', 'Homagama', 'Maharagama', 'Kesbewa'],
    'Gampaha': ['Gampaha', 'Negombo', 'Katunayake', 'Kelaniya', 'Ja-Ela', 'Wattala', 'Kadawatha', 'Kiribathgoda', 'Nittambuwa', 'Minuwangoda', 'Veyangoda', 'Mirigama'],
    'Kalutara': ['Kalutara', 'Panadura', 'Horana', 'Matugama', 'Alutgama', 'Beruwala', 'Bandaragama'],
    'Kandy': ['Kandy', 'Gampola', 'Nawalapitiya', 'Peradeniya', 'Katugastota', 'Kundasale', 'Wattegama', 'Kadugannawa'],
    'Matale': ['Matale', 'Dambulla', 'Sigiriya', 'Galewela', 'Ukuwela', 'Yatawatta'],
    'Nuwara Eliya': ['Nuwara Eliya', 'Hatton', 'Talawakele', 'Ginigathena', 'Hanguranketa', 'Walapane'],
    'Galle': ['Galle', 'Hikkaduwa', 'Karapitiya', 'Ambalangoda', 'Elpitiya', 'Bentota', 'Baddegama'],
    'Hambantota': ['Hambantota', 'Tangalle', 'Beliatta', 'Ambalantota', 'Tissamaharama', 'Middeniya'],
    'Matara': ['Matara', 'Weligama', 'Akuressa', 'Deniyaya', 'Kamburupitiya', 'Dikwella'],
    'Jaffna': ['Jaffna', 'Chavakachcheri', 'Point Pedro', 'Valvettithurai', 'Nallur'],
    'Kilinochchi': ['Kilinochchi', 'Pallai', 'Pooneryn'],
    'Mannar': ['Mannar', 'Nanattan', 'Madhu'],
    'Mullaitivu': ['Mullaitivu', 'Oddusuddan', 'Puthukkudiyiruppu'],
    'Vavuniya': ['Vavuniya', 'Nedunkeni', 'Cheddikulam'],
    'Batticaloa': ['Batticaloa', 'Kattankudy', 'Eravur', 'Valachchenai', 'Kaluwanchikudy'],
    'Ampara': ['Ampara', 'Kalmunai', 'Samanthurai', 'Sainthamaruthu', 'Pothuvil', 'Akkaraipattu'],
    'Trincomalee': ['Trincomalee', 'Mutur', 'Kinniya', 'Kantale'],
    'Kurunegala': ['Kurunegala', 'Kuliyapitiya', 'Ibbagamuwa', 'Wariyapola', 'Mawathagama', 'Pannala', 'Polgahawela', 'Alawwa', 'Narammala'],
    'Puttalam': ['Puttalam', 'Chilaw', 'Marawila', 'Dankotuwa', 'Nattandiya', 'Anamaduwa', 'Kalpitiya'],
    'Anuradhapura': ['Anuradhapura', 'Medawachchya', 'Mihintale', 'Kebithigollewa', 'Galenbindunuwewa', 'Eppawala', 'Tambuttegama'],
    'Polonnaruwa': ['Polonnaruwa', 'Kaduruwela', 'Hingurakgoda', 'Medirigiriya', 'Welikanda'],
    'Badulla': ['Badulla', 'Bandarawela', 'Hali-Ela', 'Diyatalawa', 'Ella', 'Welimada', 'Mahiyanganaya', 'Passara'],
    'Moneragala': ['Moneragala', 'Wellawaya', 'Buttala', 'Bibile', 'Kataragama'],
    'Kegalle': ['Kegalle', 'Mawanella', 'Rambukkana', 'Ruwanwella', 'Dehiowita', 'Deraniyagala', 'Warakapola'],
    'Ratnapura': ['Ratnapura', 'Balangoda', 'Embilipitiya', 'Pelmadulla', 'Kahawatta', 'Kuruwita'],
  };

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();
  final _licenseController = TextEditingController();
  final _organicNumberController = TextEditingController();
  final _organicExpiryController = TextEditingController();
  final _gapNumberController = TextEditingController();
  final _gapExpiryController = TextEditingController();
  final _totalLandsController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng _selectedLocation = _defaultLocation;
  String? _licenseFilePath;
  String? _organicFilePath;
  String? _gapFilePath;
  String? _profilePicturePath;
  final List<_FarmerCertificateEdit> _otherCertificateEdits = [];
  bool _hasPinnedLocation = false;
  bool _isSaving = false;
  bool _isLocating = false;
  String _errorMessage = '';
  String _selectedDocType = 'National ID';
  String? _frontImagePath;
  String? _backImagePath;

  List<dynamic> get _documents =>
      List<dynamic>.from(widget.profile?['documents'] ?? const []);

  bool get _isVerified =>
      _user['is_verified'] == true || _user['is_verified'] == 1 || _user['is_verified'] == '1';

  dynamic get _verificationDoc =>
      _documents.isNotEmpty ? _documents.first : null;

  String? get _docStatus =>
      _verificationDoc != null ? _verificationDoc['verification_status'] : null;

  Map<String, dynamic> get _user =>
      Map<String, dynamic>.from(widget.profile?['user'] ?? {});

  Map<String, dynamic> get _farmerData =>
      Map<String, dynamic>.from(widget.profile?['farmer_verification'] ?? {});

  @override
  void initState() {
    super.initState();
    _hydrateForm();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _licenseController.dispose();
    _organicNumberController.dispose();
    _organicExpiryController.dispose();
    _gapNumberController.dispose();
    _gapExpiryController.dispose();
    _totalLandsController.dispose();
    _latController.dispose();
    _lngController.dispose();
    for (final certificate in _otherCertificateEdits) {
      certificate.dispose();
    }
    super.dispose();
  }

  void _hydrateForm() {
    _fullNameController.text = _value(_user['full_name']);
    _emailController.text = _value(_user['email']);
    _phoneController.text = _value(_user['phone_number']);
    _phone2Controller.text = _value(_user['phone_number_2']);
    _nationalIdController.text = _value(_user['national_id']);
    _addressController.text = _value(_user['address']);
    _cityController.text = _value(_user['city']);
    _districtController.text = _value(_user['district']);
    _provinceController.text = _value(_user['province']);
    _licenseController.text = _value(_farmerData['farming_license_number']);
    _organicNumberController.text = _value(
      _farmerData['organic_certificate_number'],
    );
    _organicExpiryController.text = _value(
      _farmerData['organic_certificate_expiry'],
    );
    _gapNumberController.text = _value(_farmerData['gap_certificate_number']);
    _gapExpiryController.text = _value(_farmerData['gap_certificate_expiry']);
    _totalLandsController.text = _value(
      _farmerData['total_lands'],
      fallback: '0',
    );
    final otherCertificates = _farmerData['other_certificates'];
    if (otherCertificates is List) {
      for (final certificate in otherCertificates) {
        final item = Map<String, dynamic>.from(certificate);
        _otherCertificateEdits.add(
          _FarmerCertificateEdit(
            title: _value(item['title']),
            existingPath: _value(item['path'], fallback: ''),
            existingUrl: _value(item['url'], fallback: ''),
          ),
        );
      }
    }

    final lat = double.tryParse(_value(_user['latitude']));
    final lng = double.tryParse(_value(_user['longitude']));
    if (lat != null && lng != null) {
      _selectedLocation = LatLng(lat, lng);
      _hasPinnedLocation = true;
      _latController.text = lat.toStringAsFixed(6);
      _lngController.text = lng.toStringAsFixed(6);
    } else {
      _latController.text = _selectedLocation.latitude.toStringAsFixed(6);
      _lngController.text = _selectedLocation.longitude.toStringAsFixed(6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Update Farmer Profile',
          style: TextStyle(
            color: AppTheme.darkGreen,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            if (_errorMessage.isNotEmpty) _buildErrorBanner(_errorMessage),
            const SizedBox(height: 10),
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.freshGreen.withValues(alpha: 0.5), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: AppTheme.lightMint,
                      backgroundImage: _profilePicturePath != null
                          ? FileImage(File(_profilePicturePath!)) as ImageProvider
                          : (_user['profile_picture_path'] != null && _value(_user['profile_picture_path']) != '-')
                              ? NetworkImage(ApiService.fileUrl(_value(_user['profile_picture_path']))!) as ImageProvider
                              : null,
                      child: (_profilePicturePath == null && (_user['profile_picture_path'] == null || _value(_user['profile_picture_path']) == '-'))
                          ? Text(
                              _initials(_value(_user['full_name'], fallback: 'Farmer')),
                              style: const TextStyle(
                                color: AppTheme.deepLeafGreen,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: _pickProfilePicture,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.deepLeafGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildEditorCard(
              title: 'Personal Details',
              icon: Icons.badge_outlined,
              children: [
                _buildTextField(
                  _fullNameController,
                  'Full Name',
                  Icons.person_outline,
                  required: true,
                ),
                _buildTextField(
                  _emailController,
                  'Email',
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  _phoneController,
                  'Phone Number',
                  Icons.phone_outlined,
                  required: true,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  _phone2Controller,
                  'Second Phone',
                  Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  _nationalIdController,
                  'National ID',
                  Icons.credit_card_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEditorCard(
              title: 'Farm Address',
              icon: Icons.location_on_outlined,
              children: [
                _buildTextField(
                  _addressController,
                  'Address',
                  Icons.home_outlined,
                  maxLines: 2,
                ),
                _buildDropdownField(
                  label: 'Province',
                  icon: Icons.public_rounded,
                  value: _provinceController.text,
                  items: _provincesList,
                  onChanged: (val) {
                    setState(() {
                      _provinceController.text = val ?? '';
                      _districtController.text = '';
                      _cityController.text = '';
                    });
                  },
                ),
                _buildDropdownField(
                  label: 'District',
                  icon: Icons.map,
                  value: _districtController.text,
                  items: _districtsMap[_provinceController.text] ?? const [],
                  onChanged: (val) {
                    setState(() {
                      _districtController.text = val ?? '';
                      _cityController.text = '';
                    });
                  },
                ),
                _buildDropdownField(
                  label: 'City',
                  icon: Icons.location_city,
                  value: _cityController.text,
                  items: _citiesMap[_districtController.text] ?? const [],
                  onChanged: (val) {
                    setState(() {
                      _cityController.text = val ?? '';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMapPickerCard(),
            const SizedBox(height: 16),
            _buildEditorCard(
              title: 'Certifications',
              icon: Icons.verified_user_outlined,
              children: [
                _buildTextField(
                  _licenseController,
                  'Farming License Number',
                  Icons.confirmation_number_outlined,
                ),
                _buildTextField(
                  _organicNumberController,
                  'Organic Certificate Number',
                  Icons.eco_outlined,
                ),
                _buildTextField(
                  _organicExpiryController,
                  'Organic Certificate Expiry',
                  Icons.event_outlined,
                  hintText: 'YYYY-MM-DD',
                  readOnly: true,
                  onTap: () => _selectDate(context, _organicExpiryController),
                ),
                _buildTextField(
                  _gapNumberController,
                  'GAP Certificate Number',
                  Icons.verified_outlined,
                ),
                _buildTextField(
                  _gapExpiryController,
                  'GAP Certificate Expiry',
                  Icons.event_available_outlined,
                  hintText: 'YYYY-MM-DD',
                  readOnly: true,
                  onTap: () => _selectDate(context, _gapExpiryController),
                ),
                _buildTextField(
                  _totalLandsController,
                  'Total Lands',
                  Icons.landscape_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVerificationUploadsCard(),
            const SizedBox(height: 16),
            _buildIdentityVerificationCard(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving Changes...' : 'Save Profile Details',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationUploadsCard() {
    return _buildEditorCard(
      title: 'Verification Uploads',
      icon: Icons.upload_file_outlined,
      children: [
        _buildDocumentUploadTile(
          title: 'Farming License File',
          existingPath: _farmerData['farming_license_path'],
          existingUrl: _farmerData['farming_license_url'],
          selectedPath: _licenseFilePath,
          onPick: () => _pickDocument((path) => _licenseFilePath = path),
          onClear: () => setState(() => _licenseFilePath = null),
        ),
        _buildDocumentUploadTile(
          title: 'Organic Certificate File',
          existingPath: _farmerData['organic_certificate_path'],
          existingUrl: _farmerData['organic_certificate_url'],
          selectedPath: _organicFilePath,
          onPick: () => _pickDocument((path) => _organicFilePath = path),
          onClear: () => setState(() => _organicFilePath = null),
        ),
        _buildDocumentUploadTile(
          title: 'GAP Certificate File',
          existingPath: _farmerData['gap_certificate_path'],
          existingUrl: _farmerData['gap_certificate_url'],
          selectedPath: _gapFilePath,
          onPick: () => _pickDocument((path) => _gapFilePath = path),
          onClear: () => setState(() => _gapFilePath = null),
        ),
        const SizedBox(height: 6),
        for (var index = 0; index < _otherCertificateEdits.length; index++)
          _buildOtherCertificateEditor(index),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addOtherCertificate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Other Certificate'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickVerificationDoc(bool isFront) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: false,
      withData: false,
    );

    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;

    setState(() {
      if (isFront) {
        _frontImagePath = path;
      } else {
        _backImagePath = path;
      }
    });
  }

  Widget _buildIdentityVerificationCard() {
    final verificationDoc = _verificationDoc;
    final docStatus = _docStatus;
    final isVerified = _isVerified;

    Color statusColor = const Color(0xFF757575);
    if (isVerified) {
      statusColor = AppTheme.deepLeafGreen;
    } else if (docStatus == 'pending') {
      statusColor = const Color(0xFFF59E0B);
    } else if (docStatus == 'rejected') {
      statusColor = Colors.red;
    }

    return _buildEditorCard(
      title: 'Identity Verification Documents',
      icon: Icons.assignment_ind_outlined,
      children: [
        if (verificationDoc != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Document Type', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
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
                    const Text('Status', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        (verificationDoc['verification_status'] ?? '').toString().toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (docStatus == 'rejected' && verificationDoc['rejection_reason'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
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
        if (!isVerified && (verificationDoc == null || docStatus == 'rejected')) ...[
          _buildDropdownField(
            label: 'Select Document to Upload',
            value: _selectedDocType,
            items: const ['National ID', 'Driving License'],
            icon: Icons.assignment_ind_rounded,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedDocType = val);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _pickVerificationDoc(true),
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.deepLeafGreen),
                  label: Text(_frontImagePath == null ? 'Front Image' : 'Front Selected', style: const TextStyle(color: AppTheme.darkGreen, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _pickVerificationDoc(false),
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.deepLeafGreen),
                  label: Text(_backImagePath == null ? 'Back (Optional)' : 'Back Selected', style: const TextStyle(color: AppTheme.darkGreen, fontSize: 12)),
                ),
              ),
            ],
          ),
        ] else if (!isVerified && docStatus == 'pending') ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Your verification documents are under review. You will be notified once the admin completes the review.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOtherCertificateEditor(int index) {
    final certificate = _otherCertificateEdits[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  certificate.titleController,
                  'Certificate Title',
                  Icons.label_outline,
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () => _removeOtherCertificate(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          _buildDocumentUploadTile(
            title: 'Certificate File',
            existingPath: certificate.existingPath,
            existingUrl: certificate.existingUrl,
            selectedPath: certificate.filePath,
            onPick: () => _pickDocument((path) => certificate.filePath = path),
            onClear: () => setState(() => certificate.filePath = null),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadTile({
    required String title,
    required dynamic existingPath,
    required dynamic existingUrl,
    required String? selectedPath,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final existing = _value(existingUrl, fallback: _value(existingPath));
    final hasExisting = existing.isNotEmpty;
    final hasSelected = selectedPath != null && selectedPath.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(
            hasSelected ? Icons.check_circle_rounded : Icons.description_outlined,
            color: hasSelected ? AppTheme.freshGreen : AppTheme.deepLeafGreen,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasSelected
                      ? _fileName(selectedPath)
                      : hasExisting
                      ? _fileName(existing)
                      : 'No file selected',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Choose file',
            onPressed: onPick,
            icon: const Icon(Icons.attach_file_rounded, color: AppTheme.deepLeafGreen),
          ),
          if (hasSelected)
            IconButton(
              tooltip: 'Clear selection',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, color: Colors.red),
            )
          else
            IconButton(
              tooltip: 'View existing',
              onPressed: hasExisting ? () => _openDocument(existing) : null,
              icon: const Icon(Icons.visibility_outlined, color: AppTheme.deepLeafGreen),
            ),
        ],
      ),
    );
  }

  Widget _buildMapPickerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: AppTheme.deepLeafGreen),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Google Map Location',
                  style: TextStyle(
                    color: AppTheme.darkGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openLocationPicker,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Pick/Search'),
              ),
              TextButton.icon(
                onPressed: _isLocating ? null : _useCurrentLocation,
                icon: _isLocating
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: const Text('Current'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 240,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation,
                  zoom: _hasPinnedLocation ? 15 : 7,
                ),
                onMapCreated: (controller) => _mapController = controller,
                onTap: _setLocation,
                markers: {
                  Marker(
                    markerId: const MarkerId('selected_farm_location'),
                    position: _selectedLocation,
                    draggable: true,
                    onDragEnd: _setLocation,
                  ),
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
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
                  onChanged: _onManualLatLng,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
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
                  onChanged: _onManualLatLng,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _hasPinnedLocation
                ? 'Pinned: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}'
                : 'Tap the map, use Pick/Search, or enter coordinates to pin your farm location.',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.deepLeafGreen),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.darkGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        initialDate = parsed;
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.deepLeafGreen,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.deepLeafGreen,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final year = picked.year;
        final month = picked.month.toString().padLeft(2, '0');
        final day = picked.day.toString().padLeft(2, '0');
        controller.text = '$year-$month-$day';
      });
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    String? hintText,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required.';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.deepLeafGreen, size: 20),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.freshGreen, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool required = false,
  }) {
    final List<String> safeItems = List<String>.from(items);
    if (value.isNotEmpty && !safeItems.contains(value)) {
      safeItems.insert(0, value);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : (safeItems.contains(value) ? value : null),
        dropdownColor: Colors.white,
        items: safeItems
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: required
            ? (val) {
                if (val == null || val.trim().isEmpty) {
                  return '$label is required.';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: AppTheme.deepLeafGreen, size: 20),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.freshGreen, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDocument(void Function(String path) onSelected) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
      withData: false,
    );

    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;

    setState(() => onSelected(path));
  }

  void _addOtherCertificate() {
    setState(() {
      _otherCertificateEdits.add(_FarmerCertificateEdit());
    });
  }

  void _removeOtherCertificate(int index) {
    setState(() {
      final certificate = _otherCertificateEdits.removeAt(index);
      certificate.dispose();
    });
  }

  Future<void> _pickProfilePicture() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );

    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;

    setState(() {
      _profilePicturePath = path;
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'F';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _openDocument(dynamic pathOrUrl) async {
    final url = ApiService.fileUrl(pathOrUrl);
    if (url == null) return;

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this document.')),
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = '';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Please enable location services on this device.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permission is required to fetch your farm location.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _setLocation(LatLng(position.latitude, position.longitude));
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to fetch current location: $error';
      });
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
          initialLatitude: _hasPinnedLocation ? _selectedLocation?.latitude : null,
          initialLongitude: _hasPinnedLocation ? _selectedLocation?.longitude : null,
          title: 'Pick Farm Location',
        ),
      ),
    );

    if (!mounted || picked == null || picked['latitude'] == null || picked['longitude'] == null) return;
    _setLocation(LatLng(picked['latitude']!, picked['longitude']!));
  }

  void _setLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _hasPinnedLocation = true;
      _latController.text = location.latitude.toStringAsFixed(6);
      _lngController.text = location.longitude.toStringAsFixed(6);
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
  }

  void _onManualLatLng(String _) {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) return;
    _setLocation(LatLng(lat, lng));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    final data = {
      'full_name': _fullNameController.text.trim(),
      'email': _emptyToNull(_emailController.text),
      'phone_number': _phoneController.text.trim(),
      'phone_number_2': _emptyToNull(_phone2Controller.text),
      'national_id': _emptyToNull(_nationalIdController.text),
      'address': _emptyToNull(_addressController.text),
      'city': _emptyToNull(_cityController.text),
      'district': _emptyToNull(_districtController.text),
      'province': _emptyToNull(_provinceController.text),
      'latitude': _hasPinnedLocation ? _selectedLocation.latitude : null,
      'longitude': _hasPinnedLocation ? _selectedLocation.longitude : null,
      'farming_license_number': _emptyToNull(_licenseController.text),
      'organic_certificate_number': _emptyToNull(_organicNumberController.text),
      'organic_certificate_expiry': _emptyToNull(_organicExpiryController.text),
      'gap_certificate_number': _emptyToNull(_gapNumberController.text),
      'gap_certificate_expiry': _emptyToNull(_gapExpiryController.text),
      'total_lands': int.tryParse(_totalLandsController.text.trim()) ?? 0,
    };

    final otherCertificates = _otherCertificateEdits
        .map(
          (certificate) => {
            'title': _emptyToNull(certificate.titleController.text),
            'existing_path': _emptyToNull(certificate.existingPath),
            'file_path': certificate.filePath,
          },
        )
        .where(
          (certificate) =>
              certificate['title'] != null ||
              certificate['existing_path'] != null ||
              certificate['file_path'] != null,
        )
        .toList();

    String docType = 'national_id';
    if (_selectedDocType == 'Driving License') {
      docType = 'driving_license';
    }

    final result = await ApiService.updateFarmerProfile(
      {
        ...data,
        if (_frontImagePath != null) 'document_type': docType,
      },
      files: {
        'farming_license_file': _licenseFilePath,
        'organic_certificate_file': _organicFilePath,
        'gap_certificate_file': _gapFilePath,
        'profile_picture': _profilePicturePath,
        'front_image': _frontImagePath,
        'back_image': _backImagePath,
      },
      otherCertificates: otherCertificates,
    );
    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(Map<String, dynamic>.from(result['profile']));
    } else {
      setState(() {
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
          _errorMessage = result['message'] ?? 'Failed to update profile.';
        }
      });
    }
  }

  String _value(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String _fileName(String? path) {
    if (path == null || path.isEmpty) return 'Selected file';
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }
}

class AddLandScreen extends StatefulWidget {
  const AddLandScreen({super.key});

  @override
  State<AddLandScreen> createState() => _AddLandScreenState();
}

class _AddLandScreenState extends State<AddLandScreen> {
  static const LatLng _defaultLocation = LatLng(7.8731, 80.7718);

  final _formKey = GlobalKey<FormState>();
  final _sizeController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _notesController = TextEditingController();

  String _ownershipType = 'owned';
  LatLng _selectedLocation = _defaultLocation;
  bool _hasPinnedLocation = false;
  bool _isSaving = false;
  bool _isLocating = false;
  String _errorMessage = '';
  GoogleMapController? _mapController;
  bool _mapApiKeyMissing = false;
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final List<String> _landImagePaths = [];
  final List<_LandDocumentEdit> _landDocuments = [];

  @override
  void initState() {
    super.initState();
    // Show manual lat/lng fallback if map key is still placeholder
    _mapApiKeyMissing = false;
    _latController.text = _selectedLocation.latitude.toStringAsFixed(6);
    _lngController.text = _selectedLocation.longitude.toStringAsFixed(6);
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _regNumberController.dispose();
    _notesController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _mapController?.dispose();
    for (final doc in _landDocuments) doc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(title: const Text('Register New Land')),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            if (_errorMessage.isNotEmpty) _buildErrorBanner(),
            _buildCard(
              title: 'Land Details',
              icon: Icons.terrain_rounded,
              children: [
                _buildTextField(
                  _sizeController,
                  'Size (Perches)',
                  Icons.straighten_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  required: true,
                  hint: 'e.g. 40',
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ownership Type',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final type in ['owned', 'license', 'lease', 'government', 'other'])
                      ChoiceChip(
                        label: Text(_ownershipLabel(type)),
                        selected: _ownershipType == type,
                        selectedColor: AppTheme.lightMint,
                        labelStyle: TextStyle(
                          color: _ownershipType == type ? AppTheme.deepLeafGreen : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _ownershipType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _regNumberController,
                  'Registration Number (optional)',
                  Icons.confirmation_number_outlined,
                ),
                _buildTextField(
                  _notesController,
                  'Notes (optional)',
                  Icons.notes_rounded,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMapPickerCard(),
            const SizedBox(height: 16),
            _buildUploadsCard(),
            const SizedBox(height: 16),
            _buildStatusInfoCard(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add_location_alt_rounded),
              label: Text(_isSaving ? 'Registering...' : 'Register Land'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepLeafGreen,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadsCard() {
    return _buildCard(
      title: 'Land Images & Documents',
      icon: Icons.upload_file_outlined,
      children: [
        // Land Images
        Row(
          children: [
            const Icon(Icons.photo_library_outlined, color: AppTheme.deepLeafGreen, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Land Images', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            TextButton.icon(
              onPressed: _pickLandImages,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_landImagePaths.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _landImagePaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_landImagePaths[i]),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _landImagePaths.removeAt(i)),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('No images selected', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ),
        const Divider(height: 20),
        // Land Documents
        Row(
          children: [
            const Icon(Icons.description_outlined, color: AppTheme.deepLeafGreen, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Land Documents', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _landDocuments.add(_LandDocumentEdit())),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        for (var i = 0; i < _landDocuments.length; i++) _buildDocumentRow(i),
        if (_landDocuments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('No documents added', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildDocumentRow(int index) {
    final doc = _landDocuments[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: doc.titleController,
                  decoration: const InputDecoration(
                    labelText: 'Document Title',
                    isDense: true,
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _landDocuments.removeAt(index).dispose();
                }),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                doc.filePath != null ? Icons.check_circle : Icons.attach_file_rounded,
                color: doc.filePath != null ? AppTheme.freshGreen : AppTheme.deepLeafGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  doc.filePath != null
                      ? doc.filePath!.split('/').last.split('\\').last
                      : 'No file selected',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => _pickDocumentFile(index),
                child: const Text('Choose'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickLandImages() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: false,
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.path != null) _landImagePaths.add(f.path!);
      }
    });
  }

  Future<void> _pickDocumentFile(int index) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _landDocuments[index].filePath = path);
  }

  Widget _buildStatusInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: AppTheme.accentGold, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: Pending Review',
                  style: TextStyle(
                    color: AppTheme.darkGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your land will be reviewed by the Aswenna team before it is verified.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPickerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: AppTheme.deepLeafGreen),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Land Location',
                  style: TextStyle(
                    color: AppTheme.darkGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openLandLocationPicker,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Pick/Search'),
              ),
              TextButton.icon(
                onPressed: _isLocating ? null : _useCurrentLocation,
                icon: _isLocating
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: const Text('Current'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_mapApiKeyMissing)
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, color: Color(0xFF94A3B8), size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    'Google Maps API Key Required',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Add your API key to strings.xml to enable the map.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildLatLngInput(),
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 240,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: _hasPinnedLocation ? 15 : 7,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  onTap: _setLocation,
                  markers: {
                    Marker(
                      markerId: const MarkerId('land_location'),
                      position: _selectedLocation,
                      draggable: true,
                      onDragEnd: _setLocation,
                    ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
          const SizedBox(height: 10),
          _buildLatLngInput(),
          const SizedBox(height: 8),
          Text(
            _hasPinnedLocation
                ? 'Pinned: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}'
                : 'Tap the map, use Pick/Search, or enter coordinates to pin the land location.',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLatLngInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _latController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Latitude',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            onChanged: _onManualLatLng,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _lngController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Longitude',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            onChanged: _onManualLatLng,
          ),
        ),
      ],
    );
  }

  void _onManualLatLng(String _) {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) return;
    _setLocation(LatLng(lat, lng));
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.deepLeafGreen),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.darkGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label is required.' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.deepLeafGreen),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = '';
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
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openLandLocationPicker() async {
    final picked = await Navigator.of(context).push<Map<String, double>>(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _hasPinnedLocation ? _selectedLocation?.latitude : null,
          initialLongitude: _hasPinnedLocation ? _selectedLocation?.longitude : null,
          title: 'Pick Land Location',
        ),
      ),
    );

    if (!mounted || picked == null || picked['latitude'] == null || picked['longitude'] == null) return;
    _setLocation(LatLng(picked['latitude']!, picked['longitude']!));
  }

  void _setLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _hasPinnedLocation = true;
      _latController.text = location.latitude.toStringAsFixed(6);
      _lngController.text = location.longitude.toStringAsFixed(6);
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
  }

  String _ownershipLabel(String type) {
    const labels = {
      'owned': 'Owned',
      'license': 'Licensed',
      'lease': 'Leased',
      'government': 'Government',
      'other': 'Other',
    };
    return labels[type] ?? type;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    // Build documents JSON for titles
    final docsJson = _landDocuments
        .where((d) => d.titleController.text.trim().isNotEmpty || d.filePath != null)
        .map((d) => {'title': d.titleController.text.trim(), 'path': ''})
        .toList();

    final result = await ApiService.addFarmerLand(
      {
        'size': _sizeController.text.trim(),
        'ownership_type': _ownershipType,
        if (_regNumberController.text.trim().isNotEmpty)
          'registration_number': _regNumberController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
        if (_hasPinnedLocation) 'latitude': _selectedLocation.latitude,
        if (_hasPinnedLocation) 'longitude': _selectedLocation.longitude,
      },
      imagePaths: _landImagePaths,
      documentPaths: _landDocuments.map((d) => d.filePath ?? '').toList(),
      documentTitles: _landDocuments.map((d) => d.titleController.text.trim()).toList(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Land registered successfully! Status: Pending'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = result['message'] ?? 'Failed to register land.');
    }
  }
}

class _LandDocumentEdit {
  final TextEditingController titleController;
  String? filePath;

  _LandDocumentEdit() : titleController = TextEditingController();

  void dispose() => titleController.dispose();
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _VerificationDocumentItem {
  final String title;
  final String number;
  final String path;
  final String expiry;

  const _VerificationDocumentItem({
    required this.title,
    this.number = '-',
    this.path = '-',
    this.expiry = '-',
  });

  bool get hasAnyData => number != '-' || path != '-' || expiry != '-';
}

class _FarmerCertificateEdit {
  final TextEditingController titleController;
  final String existingPath;
  final String existingUrl;
  String? filePath;

  _FarmerCertificateEdit({
    String title = '',
    this.existingPath = '',
    this.existingUrl = '',
  }) : titleController = TextEditingController(text: title);

  void dispose() {
    titleController.dispose();
  }
}

class EditLandScreen extends StatefulWidget {
  final int landId;
  final Map<String, dynamic> land;

  const EditLandScreen({
    super.key,
    required this.landId,
    required this.land,
  });

  @override
  State<EditLandScreen> createState() => _EditLandScreenState();
}

class _EditLandScreenState extends State<EditLandScreen> {
  static const LatLng _defaultLocation = LatLng(7.8731, 80.7718);

  final _formKey = GlobalKey<FormState>();
  final _sizeController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final List<String> _existingImagePaths = [];
  final List<String> _newImagePaths = [];
  final List<Map<String, dynamic>> _existingDocuments = [];
  final List<_LandDocumentEdit> _newDocuments = [];

  String _ownershipType = 'owned';
  LatLng _selectedLocation = _defaultLocation;
  bool _hasPinnedLocation = false;
  bool _isSaving = false;
  bool _isLocating = false;
  String _errorMessage = '';
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();

    _sizeController.text = (widget.land['size'] ?? '').toString();
    _regNumberController.text =
        (widget.land['registration_number'] ?? '').toString();
    _notesController.text = (widget.land['notes'] ?? '').toString();

    final ownership = (widget.land['ownership_type'] ?? '').toString();
    if (['owned', 'license', 'lease', 'government', 'other'].contains(ownership)) {
      _ownershipType = ownership;
    }

    final lat = double.tryParse((widget.land['latitude'] ?? '').toString());
    final lng = double.tryParse((widget.land['longitude'] ?? '').toString());
    if (lat != null && lng != null) {
      _selectedLocation = LatLng(lat, lng);
      _hasPinnedLocation = true;
    }

    final landImages = widget.land['land_images'];
    if (landImages is List) {
      for (final item in landImages) {
        final path = item?.toString().trim() ?? '';
        if (path.isNotEmpty) _existingImagePaths.add(path);
      }
    }

    final landDocs = widget.land['land_documents'];
    if (landDocs is List) {
      for (final item in landDocs) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final path = (map['path'] ?? '').toString().trim();
          if (path.isEmpty) continue;
          _existingDocuments.add({
            'title': (map['title'] ?? '').toString(),
            'path': path,
          });
        }
      }
    }

    _latController.text = _selectedLocation.latitude.toStringAsFixed(6);
    _lngController.text = _selectedLocation.longitude.toStringAsFixed(6);
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _regNumberController.dispose();
    _notesController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _mapController?.dispose();
    for (final doc in _newDocuments) {
      doc.dispose();
    }
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = '';
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
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _errorMessage = 'Location permission denied.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _setLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() => _errorMessage = 'Failed to fetch location: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openLandLocationPicker() async {
    final picked = await Navigator.of(context).push<Map<String, double>>(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _hasPinnedLocation ? _selectedLocation?.latitude : null,
          initialLongitude: _hasPinnedLocation ? _selectedLocation?.longitude : null,
          title: 'Pick Land Location',
        ),
      ),
    );

    if (!mounted || picked == null || picked['latitude'] == null || picked['longitude'] == null) return;
    _setLocation(LatLng(picked['latitude']!, picked['longitude']!));
  }

  void _setLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _hasPinnedLocation = true;
      _latController.text = location.latitude.toStringAsFixed(6);
      _lngController.text = location.longitude.toStringAsFixed(6);
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
  }

  void _onManualLatLng(String _) {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) return;
    _setLocation(LatLng(lat, lng));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    final data = <String, dynamic>{
      'size': _sizeController.text.trim(),
      'ownership_type': _ownershipType,
      'registration_number': _regNumberController.text.trim().isEmpty
          ? null
          : _regNumberController.text.trim(),
      'latitude': _hasPinnedLocation ? _selectedLocation.latitude : null,
      'longitude': _hasPinnedLocation ? _selectedLocation.longitude : null,
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    final result = await ApiService.updateFarmerLand(
      widget.landId,
      data,
      keepImagePaths: _existingImagePaths,
      keepDocuments: _existingDocuments,
      imagePaths: _newImagePaths,
      documentPaths: _newDocuments.map((d) => d.filePath ?? '').toList(),
      documentTitles: _newDocuments.map((d) => d.titleController.text.trim()).toList(),
    );
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (result['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _errorMessage = result['message'] ?? 'Failed to update land.';
    });
  }

  Widget _buildNewDocumentRow(int index) {
    final doc = _newDocuments[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: doc.titleController,
                  decoration: const InputDecoration(
                    labelText: 'Document Title',
                    isDense: true,
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _newDocuments.removeAt(index).dispose();
                }),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                doc.filePath != null ? Icons.check_circle : Icons.attach_file_rounded,
                color: doc.filePath != null ? AppTheme.freshGreen : AppTheme.deepLeafGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  doc.filePath != null ? doc.filePath!.split('/').last.split('\\').last : 'No file selected',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
                    allowMultiple: false,
                    withData: false,
                  );
                  final path = result?.files.single.path;
                  if (path == null) return;
                  setState(() => _newDocuments[index].filePath = path);
                },
                child: const Text('Choose'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _ownershipLabel(String type) {
    const labels = {
      'owned': 'Owned',
      'license': 'Licensed',
      'lease': 'Leased',
      'government': 'Government',
      'other': 'Other',
    };
    return labels[type] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(title: const Text('Edit Land')),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'Note: Any updates to land details will set the status back to Pending for approval.',
                style: TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.3),
              ),
            ),
            const SizedBox(height: 14),
            if (_errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepLeafGreen.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terrain_rounded, color: AppTheme.deepLeafGreen),
                      SizedBox(width: 10),
                      Text(
                        'Land Details',
                        style: TextStyle(
                          color: AppTheme.darkGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _sizeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Size is required.' : null,
                    decoration: const InputDecoration(
                      labelText: 'Size (Perches)',
                      isDense: true,
                      prefixIcon: Icon(Icons.straighten_rounded, color: AppTheme.deepLeafGreen),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ownership Type',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final type in ['owned', 'license', 'lease', 'government', 'other'])
                        ChoiceChip(
                          label: Text(_ownershipLabel(type)),
                          selected: _ownershipType == type,
                          selectedColor: AppTheme.lightMint,
                          labelStyle: TextStyle(
                            color: _ownershipType == type
                                ? AppTheme.deepLeafGreen
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _ownershipType = type),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _regNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Registration Number (optional)',
                      isDense: true,
                      prefixIcon: Icon(Icons.numbers_rounded, color: AppTheme.deepLeafGreen),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      isDense: true,
                      prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.deepLeafGreen),
                    ),
                  ),

                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.image_outlined, color: AppTheme.deepLeafGreen, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Land Images',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.pickFiles(
                            type: FileType.image,
                            allowMultiple: true,
                            withData: false,
                          );
                          if (result == null) return;
                          setState(() {
                            for (final f in result.files) {
                              if (f.path != null) _newImagePaths.add(f.path!);
                            }
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_existingImagePaths.isNotEmpty || _newImagePaths.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < _existingImagePaths.length; i++)
                          Stack(
                            children: [
                              Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: const Color(0xFFF1F5F9),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(Icons.image_outlined, color: Color(0xFF64748B)),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setState(() => _existingImagePaths.removeAt(i)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        for (var i = 0; i < _newImagePaths.length; i++)
                          Stack(
                            children: [
                              Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: const Color(0xFFF1F5F9),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(Icons.image_outlined, color: Color(0xFF64748B)),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setState(() => _newImagePaths.removeAt(i)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'No images selected',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, color: AppTheme.deepLeafGreen, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Land Documents',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _newDocuments.add(_LandDocumentEdit())),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  for (var i = 0; i < _existingDocuments.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: (_existingDocuments[i]['title'] ?? '').toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Document Title',
                                    isDense: true,
                                    prefixIcon: Icon(Icons.label_outline),
                                  ),
                                  onChanged: (v) =>
                                      _existingDocuments[i]['title'] = v.trim(),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _existingDocuments.removeAt(i)),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.attach_file_rounded, color: AppTheme.deepLeafGreen, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  (_existingDocuments[i]['path'] ?? '').toString().split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  for (var i = 0; i < _newDocuments.length; i++)
                    _buildNewDocumentRow(i),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepLeafGreen.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.map_outlined, color: AppTheme.deepLeafGreen),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Land Location',
                          style: TextStyle(
                            color: AppTheme.darkGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openLandLocationPicker,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Pick/Search'),
                      ),
                      TextButton.icon(
                        onPressed: _isLocating ? null : _useCurrentLocation,
                        icon: _isLocating
                            ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: const Text('Current'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 240,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation,
                          zoom: _hasPinnedLocation ? 15 : 7,
                        ),
                        onMapCreated: (c) => _mapController = c,
                        onTap: _setLocation,
                        markers: {
                          Marker(
                            markerId: const MarkerId('land_location'),
                            position: _selectedLocation,
                            draggable: true,
                            onDragEnd: _setLocation,
                          ),
                        },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          onChanged: _onManualLatLng,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          onChanged: _onManualLatLng,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasPinnedLocation
                        ? 'Pinned: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}'
                        : 'Tap the map, use Pick/Search, or enter coordinates.',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepLeafGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
