import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/services/api_service.dart';

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

  Map<String, dynamic> get _user =>
      Map<String, dynamic>.from(_profile?['user'] ?? {});

  Map<String, dynamic> get _farmerData =>
      Map<String, dynamic>.from(_profile?['farmer_verification'] ?? {});

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
        title: Row(
          children: [
            InkWell(
              customBorder: const CircleBorder(),
              onTap: _openProfile,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hello, $_firstName',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                  Text(
                    '$_locationLabel - Farmer',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(
              Icons.account_circle_outlined,
              color: AppTheme.deepLeafGreen,
            ),
            onPressed: _openProfile,
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.deepLeafGreen,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.deepLeafGreen,
        onRefresh: _loadProfile,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            _buildLandsTab(),
            _buildYieldsTab(),
            _buildWalletTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
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
    if (path.startsWith('http')) return path;
    return null;
  }

  Widget _buildHomeTab() {
    return _scrollTab(
      children: [
        if (_isLoadingProfile) const LinearProgressIndicator(minHeight: 3),
        if (_profileError.isNotEmpty) _buildErrorBanner(),
        _buildWeatherCard(),
        const SizedBox(height: 24),
        const Text(
          'Earnings Summary',
          style: TextStyle(
            color: AppTheme.darkGreen,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Revenue',
                'LKR 0.00',
                Icons.account_balance_wallet_rounded,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Registered Lands',
                '${_text(_farmerData['total_lands'], fallback: '0')} Lands',
                Icons.landscape_rounded,
                AppTheme.accentGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Your Active Yields', 'Add Yield', () {
          setState(() => _currentIndex = 2);
        }),
        const SizedBox(height: 8),
        _buildEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'No active yields yet',
          subtitle:
              'Create your first crop yield listing when harvest is ready.',
        ),
      ],
    );
  }

  Widget _buildLandsTab() {
    return _scrollTab(
      children: [
        _buildSectionTitle('Land Portfolio'),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'Farm Location',
          icon: Icons.map_rounded,
          rows: [
            _InfoRow('Address', _text(_user['address'])),
            _InfoRow('City', _text(_user['city'])),
            _InfoRow('District', _text(_user['district'])),
            _InfoRow('Province', _text(_user['province'])),
            _InfoRow('Latitude', _text(_user['latitude'])),
            _InfoRow('Longitude', _text(_user['longitude'])),
            _InfoRow('Total Lands', _text(_farmerData['total_lands'])),
          ],
        ),
        const SizedBox(height: 16),
        _buildEmptyState(
          icon: Icons.add_location_alt_outlined,
          title: 'Land records are empty',
          subtitle:
              'Land and crop records will appear here after registration.',
        ),
      ],
    );
  }

  Widget _buildYieldsTab() {
    return _scrollTab(
      children: [
        _buildSectionHeader('Yield Listings', 'New Listing', () {}),
        const SizedBox(height: 12),
        _buildEmptyState(
          icon: Icons.eco_outlined,
          title: 'No yield listings',
          subtitle: 'Your active harvest listings and bids will appear here.',
        ),
      ],
    );
  }

  Widget _buildWalletTab() {
    return _scrollTab(
      children: [
        _buildSectionTitle('Wallet'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Available',
                'LKR 0.00',
                Icons.savings_rounded,
                AppTheme.deepLeafGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Pending',
                'LKR 0.00',
                Icons.pending_actions_rounded,
                AppTheme.accentGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No wallet activity',
          subtitle: 'Completed sales and withdrawals will appear here.',
        ),
      ],
    );
  }

  Widget _scrollTab({required List<Widget> children}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(20),
      children: children,
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.deepLeafGreen, AppTheme.freshGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepLeafGreen.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Weather Forecast',
                      style: TextStyle(
                        color: AppTheme.lightMint,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '21 C - Sunny Intervals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Profile and land data are ready for marketplace planning.',
                  style: TextStyle(
                    color: AppTheme.lightMint.withValues(alpha: 0.9),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.spa_rounded, color: AppTheme.lightMint, size: 64),
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
    return Container(
      padding: const EdgeInsets.all(16),
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.darkGreen,
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

  BottomNavigationBar _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: AppTheme.deepLeafGreen,
      unselectedItemColor: const Color(0xFF94A3B8),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.landscape_rounded),
          label: 'Lands',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_rounded),
          label: 'Yields',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wallet_rounded),
          label: 'Wallet',
        ),
      ],
      onTap: (index) {
        setState(() => _currentIndex = index);
      },
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

  const FarmerProfileScreen({
    super.key,
    required this.profile,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onLogout,
    required this.onProfileUpdated,
  });

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  late Map<String, dynamic>? _profile;
  late bool _isLoading;
  late String _errorMessage;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _isLoading = widget.isLoading;
    _errorMessage = widget.errorMessage;
  }

  Map<String, dynamic> get _user =>
      Map<String, dynamic>.from(_profile?['user'] ?? {});

  Map<String, dynamic> get _farmerData =>
      Map<String, dynamic>.from(_profile?['farmer_verification'] ?? {});

  List<dynamic> get _documents =>
      List<dynamic>.from(_profile?['documents'] ?? const []);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Farmer Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshProfile,
          ),
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_rounded),
            onPressed: _openEditor,
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
          padding: const EdgeInsets.all(20),
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 3),
            if (_errorMessage.isNotEmpty) _buildErrorBanner(_errorMessage),
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildLocationMapCard(),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Personal Details',
              icon: Icons.badge_outlined,
              rows: [
                _InfoRow('Full Name', _text(_user['full_name'])),
                _InfoRow('Email', _text(_user['email'])),
                _InfoRow('Phone', _text(_user['phone_number'])),
                _InfoRow('Second Phone', _text(_user['phone_number_2'])),
                _InfoRow('National ID', _text(_user['national_id'])),
                _InfoRow('Verified', _boolText(_user['is_verified'])),
                _InfoRow('Active', _boolText(_user['is_active'])),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Address',
              icon: Icons.location_on_outlined,
              rows: [
                _InfoRow('Address', _text(_user['address'])),
                _InfoRow('City', _text(_user['city'])),
                _InfoRow('District', _text(_user['district'])),
                _InfoRow('Province', _text(_user['province'])),
                _InfoRow('Latitude', _text(_user['latitude'])),
                _InfoRow('Longitude', _text(_user['longitude'])),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Farmer Verification',
              icon: Icons.verified_user_outlined,
              rows: [
                _InfoRow(
                  'License No',
                  _text(_farmerData['farming_license_number']),
                ),
                _InfoRow(
                  'Organic Cert No',
                  _text(_farmerData['organic_certificate_number']),
                ),
                _InfoRow(
                  'Organic Expiry',
                  _text(_farmerData['organic_certificate_expiry']),
                ),
                _InfoRow(
                  'GAP Cert No',
                  _text(_farmerData['gap_certificate_number']),
                ),
                _InfoRow(
                  'GAP Expiry',
                  _text(_farmerData['gap_certificate_expiry']),
                ),
                _InfoRow('Total Lands', _text(_farmerData['total_lands'])),
              ],
            ),
            const SizedBox(height: 16),
            _buildDocumentsCard(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openEditor,
              icon: const Icon(Icons.edit_location_alt_rounded),
              label: const Text('Update Profile Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepLeafGreen,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Color(0xFFFCA5A5)),
              ),
            ),
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

  Widget _buildLocationMapCard() {
    final position = _profileLatLng;
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
              const Icon(
                Icons.pin_drop_outlined,
                color: AppTheme.deepLeafGreen,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pinned Farm Location',
                  style: TextStyle(
                    color: AppTheme.darkGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(onPressed: _openEditor, child: const Text('Edit')),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 180,
              child: position == null
                  ? Container(
                      color: const Color(0xFFF8FAFC),
                      alignment: Alignment.center,
                      child: const Text(
                        'No pinned location yet.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: position,
                        zoom: 14,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('farm_location'),
                          position: position,
                        ),
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            position == null
                ? 'Use Update Profile Details to set latitude and longitude.'
                : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  LatLng? get _profileLatLng {
    final lat = double.tryParse(_text(_user['latitude']));
    final lng = double.tryParse(_text(_user['longitude']));
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppTheme.lightMint,
            child: Text(
              _initials(_text(_user['full_name'], fallback: 'Farmer')),
              style: const TextStyle(
                color: AppTheme.deepLeafGreen,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(_user['full_name'], fallback: 'Farmer'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.darkGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_text(_user['district'], fallback: 'Location not set')} - Farmer',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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

  Widget _buildDocumentsCard() {
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
          const Row(
            children: [
              Icon(Icons.description_outlined, color: AppTheme.deepLeafGreen),
              SizedBox(width: 10),
              Text(
                'Verification Documents',
                style: TextStyle(
                  color: AppTheme.darkGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_documents.isEmpty)
            const Text(
              'No verification documents uploaded yet.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            )
          else
            for (final item in _documents)
              _buildDocumentRow(Map<String, dynamic>.from(item)),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(Map<String, dynamic> document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            color: AppTheme.darkGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(document['document_type']),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _text(document['verification_status'], fallback: 'pending'),
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

  String _boolText(dynamic value) {
    if (value == true || value == 1 || value == '1') return 'Yes';
    return 'No';
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

  GoogleMapController? _mapController;
  LatLng _selectedLocation = _defaultLocation;
  bool _hasPinnedLocation = false;
  bool _isSaving = false;
  bool _isLocating = false;
  String _errorMessage = '';

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

    final lat = double.tryParse(_value(_user['latitude']));
    final lng = double.tryParse(_value(_user['longitude']));
    if (lat != null && lng != null) {
      _selectedLocation = LatLng(lat, lng);
      _hasPinnedLocation = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(title: const Text('Update Farmer Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            if (_errorMessage.isNotEmpty) _buildErrorBanner(_errorMessage),
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
                _buildTextField(_cityController, 'City', Icons.location_city),
                _buildTextField(_districtController, 'District', Icons.map),
                _buildTextField(
                  _provinceController,
                  'Province',
                  Icons.public_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMapPickerCard(),
            const SizedBox(height: 16),
            _buildEditorCard(
              title: 'Farmer Verification',
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
                ),
                _buildTextField(
                  _totalLandsController,
                  'Total Lands',
                  Icons.landscape_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
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
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepLeafGreen,
              ),
            ),
          ],
        ),
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
          Text(
            _hasPinnedLocation
                ? 'Pinned: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}'
                : 'Tap the map or use Current to pin your farm location.',
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
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
          hintText: hintText,
          prefixIcon: Icon(icon, color: AppTheme.deepLeafGreen),
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

  void _setLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _hasPinnedLocation = true;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(location));
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

    final result = await ApiService.updateFarmerProfile(data);
    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(Map<String, dynamic>.from(result['profile']));
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to update profile.';
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
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}
