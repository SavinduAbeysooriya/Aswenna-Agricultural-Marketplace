import 'dart:io';
import 'package:flutter/material.dart';
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

  Map<String, dynamic> get _user =>
      Map<String, dynamic>.from(_profile?['user'] ?? {});

  Map<String, dynamic> get _farmerData =>
      Map<String, dynamic>.from(_profile?['farmer_verification'] ?? {});

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLands();
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
        onRefresh: () async {
          await _loadProfile();
          await _loadLands();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
        backgroundColor: AppTheme.deepLeafGreen,
        tooltip: 'AI Agent',
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
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
                '${_lands.length} Lands',
                Icons.terrain_rounded,
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepLeafGreen.withValues(alpha: 0.05),
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
                    Text(
                      '${land['size']} Perches · ${_ownershipLabel(land['ownership_type'])}',
                      style: const TextStyle(
                        color: AppTheme.darkGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (land['registration_number'] != null)
                      Text(
                        'Reg: ${land['registration_number']}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
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
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Crops',
                onPressed: _openCropPicker,
                icon: const Icon(Icons.grass_outlined, size: 18, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 2),
              IconButton(
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
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
              ),
            ],
          ),
          if (land['latitude'] != null && land['longitude'] != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  '${double.tryParse(land['latitude'].toString())?.toStringAsFixed(5)}, '
                  '${double.tryParse(land['longitude'].toString())?.toStringAsFixed(5)}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ],
          if (land['notes'] != null && land['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              land['notes'].toString(),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
        BottomNavigationBarItem(
          icon: Icon(Icons.note_alt_rounded),
          label: 'Logs',
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
                _InfoRow('Record ID', _text(_farmerData['id'])),
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
                _InfoRow('Created', _text(_farmerData['created_at'])),
                _InfoRow('Updated', _text(_farmerData['updated_at'])),
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
    final verificationDocuments = _verificationDocuments
        .where((document) => document.hasAnyData)
        .toList();

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
          if (verificationDocuments.isNotEmpty) ...[
            for (final document in verificationDocuments)
              _buildFarmerDocumentRow(document),
            if (_documents.isNotEmpty) const SizedBox(height: 8),
          ],
          if (_documents.isEmpty)
            const Text(
              'No general verification documents uploaded yet.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            )
          else
            for (final item in _documents)
              _buildDocumentRow(Map<String, dynamic>.from(item)),
        ],
      ),
    );
  }

  Widget _buildFarmerDocumentRow(_VerificationDocumentItem document) {
    final canOpen = document.path != '-';
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
            Icons.assignment_turned_in_outlined,
            color: AppTheme.darkGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (document.number != '-') document.number,
                    if (document.expiry != '-') 'Expires ${document.expiry}',
                    if (!canOpen) 'No file uploaded',
                  ].join(' - '),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'View document',
            onPressed: canOpen ? () => _openDocument(document.path) : null,
            icon: const Icon(Icons.visibility_outlined),
          ),
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
          IconButton(
            tooltip: 'View front',
            onPressed: () => _openDocument(
              document['front_image_url'] ?? document['front_image_path'],
            ),
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
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
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng _selectedLocation = _defaultLocation;
  String? _licenseFilePath;
  String? _organicFilePath;
  String? _gapFilePath;
  final List<_FarmerCertificateEdit> _otherCertificateEdits = [];
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
            const SizedBox(height: 16),
            _buildVerificationUploadsCard(),
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

  Widget _buildOtherCertificateEditor(int index) {
    final certificate = _otherCertificateEdits[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(
            hasSelected ? Icons.check_circle : Icons.description_outlined,
            color: hasSelected ? AppTheme.freshGreen : AppTheme.deepLeafGreen,
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
            icon: const Icon(Icons.attach_file_rounded),
          ),
          if (hasSelected)
            IconButton(
              tooltip: 'Clear selection',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            )
          else
            IconButton(
              tooltip: 'View existing',
              onPressed: hasExisting ? () => _openDocument(existing) : null,
              icon: const Icon(Icons.visibility_outlined),
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
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    isDense: true,
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
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLocation: _hasPinnedLocation ? _selectedLocation : null,
          title: 'Pick Farm Location',
        ),
      ),
    );

    if (!mounted || picked == null) return;
    _setLocation(picked);
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

    final result = await ApiService.updateFarmerProfile(
      data,
      files: {
        'farming_license_file': _licenseFilePath,
        'organic_certificate_file': _organicFilePath,
        'gap_certificate_file': _gapFilePath,
      },
      otherCertificates: otherCertificates,
    );
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
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLocation: _hasPinnedLocation ? _selectedLocation : null,
          title: 'Pick Land Location',
        ),
      ),
    );

    if (!mounted || picked == null) return;
    _setLocation(picked);
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
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLocation: _hasPinnedLocation ? _selectedLocation : null,
          title: 'Pick Land Location',
        ),
      ),
    );

    if (!mounted || picked == null) return;
    _setLocation(picked);
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
