import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'dart:async';
import 'package:aswenna/screens/market_rates/buyer_profile_screen.dart';
import 'package:aswenna/screens/market_rates/retailer_profile_screen.dart';
import 'package:aswenna/screens/dashboards/farmer_dashboard.dart';
import 'package:aswenna/screens/login_screen.dart';

class MarketRatesScreen extends StatefulWidget {
  const MarketRatesScreen({super.key});

  @override
  State<MarketRatesScreen> createState() => _MarketRatesScreenState();
}

class _MarketRatesScreenState extends State<MarketRatesScreen>
    with TickerProviderStateMixin {
  List<dynamic> _crops = [];
  bool _isLoading = true;
  String _todayDate = '';
  String? _errorMessage;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Profile-related state variables
  String? _userRole;
  bool _isVerified = false;
  bool _hasPendingDoc = false;
  bool _hasRejectedDoc = false;
  String? _profilePic;
  Map<String, dynamic>? _profileData;
  bool _isProfileLoading = false;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadCropRates();
    _loadProfileStatus();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCropRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getCropRates();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _crops = result['crops'] ?? [];
          _todayDate = result['date'] ?? '';
          _fadeController.forward(from: 0);
        } else {
          _errorMessage = result['message'] ?? 'Failed to load rates.';
        }
      });
    }
  }

  Future<void> _loadProfileStatus() async {
    try {
      final role = await ApiService.getUserRole();
      if (!mounted) return;
      setState(() {
        _userRole = role;
      });

      Map<String, dynamic> result = {};
      setState(() => _isProfileLoading = true);

      if (role == 'buyer') {
        result = await ApiService.getBuyerProfile();
      } else if (role == 'farmer') {
        result = await ApiService.getFarmerProfile();
      } else if (role == 'retail_seller') {
        result = await ApiService.getRetailSellerProfile();
      }

      if (mounted) {
        setState(() {
          _isProfileLoading = false;
          if (result['success'] == true) {
            _profileData = result['profile'] ?? {};
            _profileError = null;
            final user = _profileData?['user'];
            final Map<dynamic, dynamic> userMap = user is Map ? user : {};
            
            final docsVal = _profileData?['documents'] ?? _profileData?['verification_documents'];
            final List<dynamic> documents = docsVal is List ? docsVal : [];
            
            _isVerified = userMap['is_verified'] == true || userMap['is_verified'] == 1;
            _hasPendingDoc = documents.any((doc) => doc is Map && doc['verification_status'] == 'pending');
            _hasRejectedDoc = documents.any((doc) => doc is Map && doc['verification_status'] == 'rejected');
            final pic = userMap['profile_picture_path'];
            _profilePic = (pic != null && pic != '-') ? pic : null;
          } else {
            _profileError = result['message'] ?? 'Failed to load profile details.';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading profile status: $e');
      if (mounted) {
        setState(() => _isProfileLoading = false);
      }
    }
  }

  Future<void> _loadFarmerProfile() async {
    await _loadProfileStatus();
  }

  void _navigateToProfile() async {
    if (_userRole == 'buyer') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BuyerProfileScreen()),
      );
      _loadProfileStatus();
    } else if (_userRole == 'retail_seller') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RetailerProfileScreen()),
      );
      _loadProfileStatus();
    } else if (_userRole == 'farmer') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FarmerProfileScreen(
            profile: _profileData,
            isLoading: _isProfileLoading,
            errorMessage: _profileError ?? '',
            onRefresh: _loadFarmerProfile,
            onLogout: () async {
              await ApiService.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            onProfileUpdated: (updated) {
              setState(() {
                _profileData = updated;
                final user = updated['user'];
                final Map<dynamic, dynamic> userMap = user is Map ? user : {};
                _isVerified = userMap['is_verified'] == true || userMap['is_verified'] == 1;
                final pic = userMap['profile_picture_path'];
                _profilePic = (pic != null && pic != '-') ? pic : null;
              });
            },
            onViewTransactions: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
      _loadProfileStatus();
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showUpdateRateSheet(Map<String, dynamic> crop) {
    final cropId = crop['id'];
    final cropName = crop['cropname'] ?? 'Unknown';
    final currentAvgA = _parseDouble(crop['avg_rate_grade_a']);
    final currentAvgB = _parseDouble(crop['avg_rate_grade_b']);
    final currentAvgC = _parseDouble(crop['avg_rate_grade_c']);
    final buyerRateA = _parseDouble(crop['buyer_today_rate_a']);
    final buyerRateB = _parseDouble(crop['buyer_today_rate_b']);
    final buyerRateC = _parseDouble(crop['buyer_today_rate_c']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RateUpdateSheet(
        cropId: cropId,
        cropName: cropName,
        currentAvgA: currentAvgA,
        currentAvgB: currentAvgB,
        currentAvgC: currentAvgC,
        buyerExistingRateA: buyerRateA,
        buyerExistingRateB: buyerRateB,
        buyerExistingRateC: buyerRateC,
        onSubmitted: () {
          _loadCropRates();
        },
      ),
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  List<dynamic> get _filteredCrops {
    if (_searchQuery.isEmpty) return _crops;
    return _crops.where((c) {
      final name = (c['cropname'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCrops;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Premium SliverAppBar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.deepLeafGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/rate_engine_bg.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.trending_up_rounded,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Today's Market Rates",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (_todayDate.isNotEmpty)
                                      Text(
                                        _formatDate(_todayDate),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.amber[300],
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    "It is your duty to include effective pricing to protect our farmers.",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 24),
                onPressed: _loadCropRates,
              ),
              if (_userRole != null)
                GestureDetector(
                  onTap: _navigateToProfile,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, left: 8),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isVerified
                                    ? AppTheme.freshGreen
                                    : (_hasPendingDoc
                                        ? AppTheme.accentGold
                                        : (_hasRejectedDoc ? Colors.red : Colors.white.withOpacity(0.4))),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(19),
                              child: _profilePic != null
                                  ? Image.network(
                                      ApiService.fileUrl(_profilePic) ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                    )
                                  : const Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isVerified
                                    ? Icons.verified_rounded
                                    : (_hasPendingDoc
                                        ? Icons.hourglass_bottom_rounded
                                        : (_hasRejectedDoc ? Icons.cancel_rounded : Icons.info_outline_rounded)),
                                color: _isVerified
                                    ? AppTheme.deepLeafGreen
                                    : (_hasPendingDoc
                                        ? AppTheme.accentGold
                                        : (_hasRejectedDoc ? Colors.red : Colors.grey[500])),
                                size: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Stats Summary Bar
          if (!_isLoading && _errorMessage == null && _crops.isNotEmpty)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppTheme.freshGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      _buildStatChip(
                        Icons.eco_rounded,
                        '${_crops.length}',
                        'Crops',
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: AppTheme.deepLeafGreen.withOpacity(0.2),
                      ),
                      _buildStatChip(
                        Icons.people_alt_rounded,
                        '${_crops.fold<int>(0, (sum, c) => sum + ((c['total_submissions'] as num?)?.toInt() ?? 0))}',
                        'Submissions',
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: AppTheme.deepLeafGreen.withOpacity(0.2),
                      ),
                      _buildStatChip(
                        Icons.check_circle_rounded,
                        '${_crops.where((c) => c['has_submitted_today'] == true).length}',
                        'Your Rates',
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Advanced Search Bar
          if (!_isLoading && _errorMessage == null && _crops.isNotEmpty)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B5E20).withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search crops by name...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.deepLeafGreen),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

          // Content
          if (_isLoading)
            SliverToBoxAdapter(child: _buildShimmerLoading())
          else if (_errorMessage != null)
            SliverFillRemaining(child: _buildErrorState())
          else if (_crops.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'No crops matching "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final crop = filtered[index] as Map<String, dynamic>;
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildCropRateCard(crop, index),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.deepLeafGreen, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.deepLeafGreen.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropRateCard(Map<String, dynamic> crop, int index) {
    final cropName = crop['cropname'] ?? 'Unknown Crop';
    final avgRateA = _parseDouble(crop['avg_rate_grade_a']);
    final avgRateB = _parseDouble(crop['avg_rate_grade_b']);
    final avgRateC = _parseDouble(crop['avg_rate_grade_c']);
    final submissions = (crop['total_submissions'] as num?)?.toInt() ?? 0;
    final hasSubmitted = crop['has_submitted_today'] == true;
    final buyerRateA = _parseDouble(crop['buyer_today_rate_a']);
    final buyerRateB = _parseDouble(crop['buyer_today_rate_b']);
    final buyerRateC = _parseDouble(crop['buyer_today_rate_c']);
    final imagePath = crop['image_path'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: hasSubmitted
              ? AppTheme.freshGreen.withOpacity(0.2)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showUpdateRateSheet(crop),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Image and Details
                Row(
                  children: [
                    Hero(
                      tag: 'crop_${crop['id']}',
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.freshGreen.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: imagePath != null &&
                                  imagePath.toString().isNotEmpty
                              ? Image.network(
                                  ApiService.fileUrl(imagePath) ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.eco_rounded,
                                    color: AppTheme.deepLeafGreen,
                                    size: 26,
                                  ),
                                )
                              : const Icon(
                                  Icons.eco_rounded,
                                  color: AppTheme.deepLeafGreen,
                                  size: 26,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cropName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B3A1B),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (hasSubmitted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: AppTheme.deepLeafGreen,
                                          size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Submitted',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.deepLeafGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.people_alt_rounded,
                                  size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                '$submissions buyers submitted today',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Beautiful Grid showing Market Averages
                const Divider(height: 1, color: Color(0xFFF1F1F1)),
                const SizedBox(height: 12),
                const Text(
                  'Today\'s Average Market Rates:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF558B2F),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _buildGradePriceBadge('Grade A', avgRateA,
                          const Color(0xFF2E7D32), buyerRateA),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGradePriceBadge('Grade B', avgRateB,
                          const Color(0xFF1565C0), buyerRateB),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGradePriceBadge('Grade C', avgRateC,
                          const Color(0xFFE65100), buyerRateC),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradePriceBadge(
      String grade, double? avgPrice, Color color, double? buyerPrice) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: buyerPrice != null ? color.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                grade,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            avgPrice != null
                ? 'LKR ${avgPrice.toStringAsFixed(0)}'
                : 'No rate',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: avgPrice != null ? const Color(0xFF1B3A1B) : Colors.grey[400],
            ),
          ),
          if (buyerPrice != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Mine: ${buyerPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 48, color: Color(0xFFE65100)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to Load Rates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B3A1B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please check your connection.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCropRates,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepLeafGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.trending_flat_rounded,
                  size: 48, color: AppTheme.deepLeafGreen),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Crops Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B3A1B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Market rates will appear here once crops are approved by admin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rate Update Bottom Sheet ────────────────────────────────────────────────

class _RateUpdateSheet extends StatefulWidget {
  final int cropId;
  final String cropName;
  final double? currentAvgA;
  final double? currentAvgB;
  final double? currentAvgC;
  final double? buyerExistingRateA;
  final double? buyerExistingRateB;
  final double? buyerExistingRateC;
  final VoidCallback onSubmitted;

  const _RateUpdateSheet({
    required this.cropId,
    required this.cropName,
    this.currentAvgA,
    this.currentAvgB,
    this.currentAvgC,
    this.buyerExistingRateA,
    this.buyerExistingRateB,
    this.buyerExistingRateC,
    required this.onSubmitted,
  });

  @override
  State<_RateUpdateSheet> createState() => _RateUpdateSheetState();
}

class _RateUpdateSheetState extends State<_RateUpdateSheet>
    with SingleTickerProviderStateMixin {
  final _rateController = TextEditingController();
  final _rateBController = TextEditingController();
  final _rateCController = TextEditingController();
  final _minQtyController = TextEditingController();
  final _maxQtyController = TextEditingController();
  List<String> _selectedGrades = ['A', 'B', 'C'];
  bool _isSubmitting = false;
  bool _showSuccess = false;
  String? _errorMsg;

  double? _minAllowedA;
  double? _maxAllowedA;
  double? _minAllowedB;
  double? _maxAllowedB;
  double? _minAllowedC;
  double? _maxAllowedC;

  bool _isLoadingDetail = true;

  late AnimationController _successController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    if (widget.buyerExistingRateA != null) {
      _rateController.text = widget.buyerExistingRateA!.toStringAsFixed(2);
    }
    if (widget.buyerExistingRateB != null) {
      _rateBController.text = widget.buyerExistingRateB!.toStringAsFixed(2);
    }
    if (widget.buyerExistingRateC != null) {
      _rateCController.text = widget.buyerExistingRateC!.toStringAsFixed(2);
    }

    _loadDetail();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _rateBController.dispose();
    _rateCController.dispose();
    _minQtyController.dispose();
    _maxQtyController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final result = await ApiService.getCropRateDetail(widget.cropId);
    if (mounted) {
      setState(() {
        _isLoadingDetail = false;
        if (result['success'] == true) {
          final today = result['today'] as Map<String, dynamic>?;
          if (today != null) {
            _minAllowedA = _parseDouble(today['min_allowed_rate_a']);
            _maxAllowedA = _parseDouble(today['max_allowed_rate_a']);
            _minAllowedB = _parseDouble(today['min_allowed_rate_b']);
            _maxAllowedB = _parseDouble(today['max_allowed_rate_b']);
            _minAllowedC = _parseDouble(today['min_allowed_rate_c']);
            _maxAllowedC = _parseDouble(today['max_allowed_rate_c']);
          }
          final buyerRate = result['buyer_rate'];
          if (buyerRate != null) {
            _rateController.text =
                _parseDouble(buyerRate['rate_per_kg_grade_a'])
                        ?.toStringAsFixed(2) ??
                    '';
            _rateBController.text =
                _parseDouble(buyerRate['rate_per_kg_grade_b'])
                        ?.toStringAsFixed(2) ??
                    '';
            _rateCController.text =
                _parseDouble(buyerRate['rate_per_kg_grade_c'])
                        ?.toStringAsFixed(2) ??
                    '';
            _minQtyController.text =
                _parseDouble(buyerRate['min_qty_required'])
                        ?.toStringAsFixed(0) ??
                    '';
            _maxQtyController.text =
                _parseDouble(buyerRate['max_qty_required'])
                        ?.toStringAsFixed(0) ??
                    '';
            
            final gradesStr = buyerRate['accepted_grade'] ?? 'All';
            if (gradesStr == 'All') {
              _selectedGrades = ['A', 'B', 'C'];
            } else {
              _selectedGrades = gradesStr
                  .toString()
                  .split(',')
                  .map((g) => g.trim())
                  .where((g) => g == 'A' || g == 'B' || g == 'C')
                  .toList();
            }
          }
        }
      });
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _submit() async {
    final rateA = double.tryParse(_rateController.text.trim());
    if (rateA == null || rateA <= 0) {
      setState(() => _errorMsg = 'Please enter a valid Grade A rate.');
      return;
    }

    // Client-side validations
    if (_minAllowedA != null && _maxAllowedA != null) {
      if (rateA < _minAllowedA! || rateA > _maxAllowedA!) {
        setState(() {
          _errorMsg =
              'Grade A rate must be between LKR ${_minAllowedA!.toStringAsFixed(2)} and LKR ${_maxAllowedA!.toStringAsFixed(2)}';
        });
        return;
      }
    }

    final rateB = double.tryParse(_rateBController.text.trim());
    if (rateB != null) {
      if (rateB < 0) {
        setState(() => _errorMsg = 'Grade B rate must be positive.');
        return;
      }
      if (_minAllowedB != null && _maxAllowedB != null) {
        if (rateB < _minAllowedB! || rateB > _maxAllowedB!) {
          setState(() {
            _errorMsg =
                'Grade B rate must be between LKR ${_minAllowedB!.toStringAsFixed(2)} and LKR ${_maxAllowedB!.toStringAsFixed(2)}';
          });
          return;
        }
      }
    }

    final rateC = double.tryParse(_rateCController.text.trim());
    if (rateC != null) {
      if (rateC < 0) {
        setState(() => _errorMsg = 'Grade C rate must be positive.');
        return;
      }
      if (_minAllowedC != null && _maxAllowedC != null) {
        if (rateC < _minAllowedC! || rateC > _maxAllowedC!) {
          setState(() {
            _errorMsg =
                'Grade C rate must be between LKR ${_minAllowedC!.toStringAsFixed(2)} and LKR ${_maxAllowedC!.toStringAsFixed(2)}';
          });
          return;
        }
      }
    }

    if (_selectedGrades.isEmpty) {
      setState(() => _errorMsg = 'Please select at least one accepted grade.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    final acceptedGradeStr = _selectedGrades.length == 3
        ? 'All'
        : _selectedGrades.join(', ');

    final data = <String, dynamic>{
      'crop_id': widget.cropId,
      'rate_per_kg_grade_a': rateA,
      'accepted_grade': acceptedGradeStr,
    };

    final minQty = double.tryParse(_minQtyController.text.trim());
    final maxQty = double.tryParse(_maxQtyController.text.trim());

    if (rateB != null) data['rate_per_kg_grade_b'] = rateB;
    if (rateC != null) data['rate_per_kg_grade_c'] = rateC;
    if (minQty != null) data['min_qty_required'] = minQty;
    if (maxQty != null) data['max_qty_required'] = maxQty;

    final result = await ApiService.submitCropRate(data);

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        setState(() => _showSuccess = true);
        _successController.forward();
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          widget.onSubmitted();
          Navigator.pop(context);
        }
      } else {
        setState(() => _errorMsg = result['message'] ?? 'Failed to submit.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: _showSuccess ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        ScaleTransition(
          scale: _successAnimation,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.deepLeafGreen,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Rate Updated!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Market averages are being recalculated.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.rate_review_rounded,
                  color: AppTheme.deepLeafGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.buyerExistingRateA != null
                        ? 'Update Your Rate'
                        : 'Set Today\'s Rate',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B3A1B),
                    ),
                  ),
                  Text(
                    widget.cropName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Averages Summary display
        Row(
          children: [
            Expanded(
              child: _buildSheetGradeAvgCard(
                  'Grade A', widget.currentAvgA, _minAllowedA, _maxAllowedA, const Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSheetGradeAvgCard(
                  'Grade B', widget.currentAvgB, _minAllowedB, _maxAllowedB, const Color(0xFF1565C0)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSheetGradeAvgCard(
                  'Grade C', widget.currentAvgC, _minAllowedC, _maxAllowedC, const Color(0xFFE65100)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Grade A Rate (Primary)
        const Text(
          'Grade A Rate (LKR/kg) *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B3A1B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _rateController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20),
          ),
          decoration: InputDecoration(
            prefixText: 'LKR ',
            prefixStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepLeafGreen.withOpacity(0.5),
            ),
            hintText: '0.00',
            filled: true,
            fillColor: const Color(0xFFF5F9F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppTheme.freshGreen.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppTheme.freshGreen.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: AppTheme.deepLeafGreen, width: 2),
            ),
          ),
          onChanged: (_) => setState(() => _errorMsg = null),
        ),
        const SizedBox(height: 16),

        // Grade B & C in a row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grade B (LKR/kg)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _rateBController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Optional',
                      hintStyle: TextStyle(
                          color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grade C (LKR/kg)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _rateCController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Optional',
                      hintStyle: TextStyle(
                          color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Accepted Grade selector
        Text(
          'Accepted Grade (Select multiple)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: ['All', 'A', 'B', 'C'].map((grade) {
            bool isSelected = false;
            if (grade == 'All') {
              isSelected = _selectedGrades.length == 3;
            } else {
              isSelected = _selectedGrades.contains(grade);
            }
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (grade == 'All') {
                      if (_selectedGrades.length == 3) {
                        _selectedGrades = [];
                      } else {
                        _selectedGrades = ['A', 'B', 'C'];
                      }
                    } else {
                      if (_selectedGrades.contains(grade)) {
                        _selectedGrades.remove(grade);
                      } else {
                        _selectedGrades.add(grade);
                      }
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                      right: grade != 'C' ? 8 : 0),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.deepLeafGreen
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.deepLeafGreen
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      grade,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Qty row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Min Qty (kg)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _minQtyController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Optional',
                      hintStyle: TextStyle(
                          color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max Qty (kg)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _maxQtyController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Optional',
                      hintStyle: TextStyle(
                          color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Error message
        if (_errorMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEF9A9A), width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFC62828), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepLeafGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppTheme.deepLeafGreen.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    widget.buyerExistingRateA != null
                        ? 'Update Rate'
                        : 'Submit Rate',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSheetGradeAvgCard(
      String grade, double? avgPrice, double? minPrice, double? maxPrice, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            grade,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            avgPrice != null ? 'LKR ${avgPrice.toStringAsFixed(0)}' : 'No Avg',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: avgPrice != null ? Colors.black87 : Colors.grey[400],
            ),
          ),
          if (minPrice != null && maxPrice != null) ...[
            const SizedBox(height: 4),
            Text(
              'Limit: ${minPrice.toStringAsFixed(0)}-${maxPrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
