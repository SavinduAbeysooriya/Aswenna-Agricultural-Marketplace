import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/screens/market_rates/market_rates_screen.dart';
import 'package:aswenna/screens/market_rates/buyer_profile_screen.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/harvest_listings/harvest_listing_detail_screen.dart';
import 'package:aswenna/screens/chat/chat_screen.dart';
import 'package:aswenna/screens/payment/payment_screen.dart';
import 'package:aswenna/screens/review/review_screen.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _currentNavIndex = 0;
  bool _isVerified = false;
  bool _hasPendingDoc = false;
  bool _hasRejectedDoc = false;
  String? _rejectionReason;
  String? _profilePic;

  List<dynamic> _harvestListings = [];
  bool _isLoadingHarvests = true;

  List<dynamic> _confirmedBids = [];
  bool _isLoadingPurchases = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileStatus();
      _loadHarvestListings();
      _loadConfirmedBids();
    });
  }

  Future<void> _loadConfirmedBids() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLoadingPurchases = true);
    });
    try {
      final result = await ApiService.getBuyerConfirmedBids();
      if (mounted) {
        setState(() {
          _confirmedBids = result['success'] == true ? List<dynamic>.from(result['confirmed_bids'] ?? []) : [];
          _isLoadingPurchases = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPurchases = false);
      }
    }
  }

  Future<void> _loadProfileStatus() async {
    try {
      final result = await ApiService.getBuyerProfile();
      if (mounted && result['success'] == true) {
        final profile = result['profile'] ?? {};
        
        // Extremely safe casts
        final user = profile['user'];
        final Map<dynamic, dynamic> userMap = user is Map ? user : {};
        
        final docsVal = profile['documents'];
        final List<dynamic> documents = docsVal is List ? docsVal : [];
        
        setState(() {
          _isVerified = userMap['is_verified'] == true;
          _hasPendingDoc = documents.any((doc) => doc is Map && doc['verification_status'] == 'pending');
          _hasRejectedDoc = documents.any((doc) => doc is Map && doc['verification_status'] == 'rejected');
          if (_hasRejectedDoc) {
            final rejectedDoc = documents.firstWhere(
              (doc) => doc is Map && doc['verification_status'] == 'rejected',
              orElse: () => null,
            );
            _rejectionReason = rejectedDoc is Map ? rejectedDoc['rejection_reason'] : null;
          } else {
            _rejectionReason = null;
          }
          _profilePic = userMap['profile_picture_path'];
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading dashboard profile status: $e\n$stack');
    }
  }

  Future<void> _loadHarvestListings() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLoadingHarvests = true);
    });
    try {
      final result = await ApiService.getBuyerHarvestListings();
      if (mounted) {
        setState(() {
          _harvestListings = result['success'] == true ? List<dynamic>.from(result['listings'] ?? []) : [];
          _isLoadingHarvests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHarvests = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety Net: Handle sub-widget rendering crashes cleanly with detailed diagnostic info instead of a blank white screen
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: const Color(0xFFFFF1F2),
        child: Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Dashboard Interface Crash Caught',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9F1239),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDA4AF)),
                  ),
                  child: Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFFBE123C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'A safe fallback was triggered to prevent whitescreen. Please copy this error trace and report it.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFE11D48), height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    };

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Buyer Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.deepLeafGreen),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BuyerProfileScreen()),
              );
              _loadProfileStatus();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
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
                            ? AppTheme.deepLeafGreen
                            : (_hasPendingDoc
                                ? AppTheme.accentGold
                                : (_hasRejectedDoc ? Colors.red : Colors.grey[300] ?? Colors.grey)),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: _profilePic != null
                          ? Image.network(
                              ApiService.fileUrl(_profilePic) ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppTheme.deepLeafGreen),
                            )
                          : const Icon(Icons.person, color: AppTheme.deepLeafGreen),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                        ],
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
                                : (_hasRejectedDoc ? Colors.red : Colors.grey[500] ?? Colors.grey)),
                        size: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _currentNavIndex == 2
          ? _buildPurchasesView()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasRejectedDoc) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFBD5D5), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel_rounded, color: Color(0xFFE53E3E), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verification Rejected',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE53E3E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your verification document was rejected. Please review the reason below and tap Resubmit.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_rejectionReason != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Reason: $_rejectionReason',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFC53030),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BuyerProfileScreen()),
                        );
                        _loadProfileStatus();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53E3E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Resubmit',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // ── Market Rates Hero Card ──
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarketRatesScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                      Color(0xFF388E3C),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.deepLeafGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Market Rates',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View & update today\'s crop prices',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Search Yields Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search crops, harvests, potato, seeds...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.deepLeafGreen),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppTheme.deepLeafGreen),
                  onPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoadingHarvests)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: AppTheme.deepLeafGreen),
              ))
            else ...[
              const Text(
                'Premium Direct Yields',
                style: TextStyle(color: AppTheme.darkGreen, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (_harvestListings.where((l) => l is Map && l['min_bid_price_per_unit'] == null).isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'No direct purchase yields available at this moment.',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _harvestListings.where((l) => l is Map && l['min_bid_price_per_unit'] == null).length,
                  itemBuilder: (context, index) {
                    final directList = _harvestListings.where((l) => l is Map && l['min_bid_price_per_unit'] == null).toList();
                    return _buildProductGridItem(Map<String, dynamic>.from(directList[index]));
                  },
                ),
              const SizedBox(height: 24),
              const Text(
                'Bidding Opportunities',
                style: TextStyle(color: AppTheme.darkGreen, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (_harvestListings.where((l) => l is Map && l['min_bid_price_per_unit'] != null).isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'No active crop bidding sessions open right now.',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _harvestListings.where((l) => l is Map && l['min_bid_price_per_unit'] != null).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bidList = _harvestListings.where((l) => l is Map && l['min_bid_price_per_unit'] != null).toList();
                    return _buildBiddingOpportunityCard(Map<String, dynamic>.from(bidList[index]));
                  },
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        selectedItemColor: AppTheme.deepLeafGreen,
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up_rounded), label: 'Rates'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_rounded), label: 'Purchases'),
          BottomNavigationBarItem(icon: Icon(Icons.logout_rounded), label: 'Logout'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarketRatesScreen()),
            );
          } else if (index == 3) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          } else {
            setState(() => _currentNavIndex = index);
            if (index == 2) {
              _loadConfirmedBids();
            }
          }
        },
      ),
    );
  }

  Widget _buildProductGridItem(Map<String, dynamic> listing) {
    final title = listing['cropname']?.toString() ?? 'Crop';
    final seller = 'Seller: ${listing['farmer_name'] ?? 'Farmer'}';
    final price = 'LKR ${listing['price_per_unit']}/${listing['unit'] ?? 'kg'}';
    final badge = 'Grade ${listing['grade'] ?? 'A'}';
    final String? imageUrl = listing['image_1'] ?? listing['crop_image'];

    return InkWell(
      onTap: () async {
        final id = int.tryParse(listing['id']?.toString() ?? '');
        if (id == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HarvestListingDetailScreen(listingId: id, role: 'buyer'),
          ),
        );
        _loadHarvestListings();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepLeafGreen.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.lightMint,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          ApiService.fileUrl(imageUrl) ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 48),
                        ),
                      )
                    else
                      const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 48),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: BorderRadius.circular(8)),
                        child: Text(badge, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(seller, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(price, style: const TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: AppTheme.deepLeafGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, color: AppTheme.pureWhite, size: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiddingOpportunityCard(Map<String, dynamic> listing) {
    final title = listing['cropname']?.toString() ?? 'Crop';
    final qty = 'Farmer: ${listing['farmer_name'] ?? 'Farmer'} • ${listing['available_quantity']} ${listing['unit'] ?? 'kg'}';
    final price = 'Min Bid: LKR ${listing['min_bid_price_per_unit']}/${listing['unit'] ?? 'kg'}';
    final String? imageUrl = listing['crop_image'];

    return InkWell(
      onTap: () async {
        final id = int.tryParse(listing['id']?.toString() ?? '');
        if (id == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HarvestListingDetailScreen(listingId: id, role: 'buyer'),
          ),
        );
        _loadHarvestListings();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepLeafGreen.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: const Color(0xFFFFF9E6), borderRadius: BorderRadius.circular(16)),
                    child: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              ApiService.fileUrl(imageUrl) ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.gavel_rounded, color: AppTheme.accentGold, size: 24),
                            ),
                          )
                        : const Icon(Icons.gavel_rounded, color: AppTheme.accentGold, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text(qty, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.accentGold, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasesView() {
    if (_isLoadingPurchases) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.deepLeafGreen),
            SizedBox(height: 16),
            Text(
              'Loading your purchases...',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_confirmedBids.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadConfirmedBids,
        color: AppTheme.deepLeafGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Container(
                       padding: const EdgeInsets.all(24),
                       decoration: const BoxDecoration(
                         color: AppTheme.lightMint,
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(
                         Icons.shopping_bag_outlined,
                         size: 64,
                         color: AppTheme.deepLeafGreen,
                       ),
                     ),
                     const SizedBox(height: 24),
                     const Text(
                       'No Purchases Yet',
                       style: TextStyle(
                         fontSize: 20,
                         fontWeight: FontWeight.w800,
                         color: AppTheme.darkGreen,
                         letterSpacing: -0.5,
                       ),
                     ),
                     const SizedBox(height: 8),
                     const Text(
                       'Browse active crop listings and place bids to purchase fresh agricultural products directly from farmers.',
                       style: TextStyle(
                         fontSize: 13,
                         color: Color(0xFF64748B),
                         height: 1.5,
                       ),
                       textAlign: TextAlign.center,
                     ),
                     const SizedBox(height: 24),
                     ElevatedButton(
                       onPressed: () {
                         setState(() {
                           _currentNavIndex = 0;
                         });
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppTheme.deepLeafGreen,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(16),
                         ),
                         elevation: 2,
                       ),
                       child: const Text(
                         'Explore Marketplace',
                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                       ),
                     ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.expand(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Purchases Header
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Purchases',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track and manage your confirmed crop orders',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadConfirmedBids,
              color: AppTheme.deepLeafGreen,
              child: ListView.separated(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
              itemCount: _confirmedBids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                try {
                  final item = _confirmedBids[index];
                  if (item == null) return const SizedBox.shrink();
                  final bid = Map<String, dynamic>.from(item as Map);
                  
                  final id = int.tryParse(bid['id']?.toString() ?? '') ?? 0;
                  final harvestListingId = int.tryParse(bid['harvest_listing_id']?.toString() ?? '');
                  final farmerId = int.tryParse(bid['farmer_id']?.toString() ?? '');
                  
                  final cropName = bid['cropname']?.toString() ?? 'Crop';
                  final qty = bid['bid_quantity_unit']?.toString() ?? '0';
                  final unit = bid['unit']?.toString() ?? 'kg';
                  final rate = double.tryParse(bid['bid_amount_per_unit']?.toString() ?? '0') ?? 0;
                  final total = double.tryParse(bid['total_amount']?.toString() ?? '0') ?? 0;
                  final farmerName = bid['farmer_name']?.toString() ?? 'Farmer';
                  final paymentStatus = (bid['payment_status'] ?? 'unpaid').toString().toLowerCase();
                  final isPaid = paymentStatus == 'paid';
                  final hasReview = bid['has_review'] == true;
                  final cropImage = bid['crop_image']?.toString();

                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.deepLeafGreen.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: harvestListingId == null
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HarvestListingDetailScreen(
                                    listingId: harvestListingId,
                                    role: 'buyer',
                                  ),
                                ),
                              );
                              _loadConfirmedBids();
                            },
                      child: Padding(
                         padding: const EdgeInsets.all(16),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             // Top section: Image & details
                             Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 // Crop image thumbnail
                                 Container(
                                   width: 72,
                                   height: 72,
                                   decoration: BoxDecoration(
                                     color: AppTheme.lightMint,
                                     borderRadius: BorderRadius.circular(16),
                                   ),
                                   child: cropImage != null
                                       ? ClipRRect(
                                           borderRadius: BorderRadius.circular(16),
                                           child: Image.network(
                                             ApiService.fileUrl(cropImage) ?? '',
                                             fit: BoxFit.cover,
                                             errorBuilder: (_, __, ___) => const Icon(
                                               Icons.shopping_bag_outlined,
                                               color: AppTheme.deepLeafGreen,
                                               size: 28,
                                             ),
                                           ),
                                         )
                                       : const Icon(
                                           Icons.shopping_bag_outlined,
                                           color: AppTheme.deepLeafGreen,
                                           size: 28,
                                         ),
                                 ),
                                 const SizedBox(width: 16),
                                 // Details
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Expanded(
                                             child: Text(
                                               cropName,
                                               style: const TextStyle(
                                                 fontSize: 16,
                                                 fontWeight: FontWeight.bold,
                                                 color: Color(0xFF0F172A),
                                               ),
                                               maxLines: 1,
                                               overflow: TextOverflow.ellipsis,
                                             ),
                                           ),
                                           const SizedBox(width: 8),
                                           // Status Badge
                                           Container(
                                             padding: const EdgeInsets.symmetric(
                                               horizontal: 10,
                                               vertical: 4,
                                             ),
                                             decoration: BoxDecoration(
                                               color: isPaid
                                                   ? const Color(0xFFE8F5E9)
                                                   : const Color(0xFFFFF8E1),
                                               borderRadius: BorderRadius.circular(30),
                                             ),
                                             child: Row(
                                               mainAxisSize: MainAxisSize.min,
                                               children: [
                                                 Icon(
                                                   isPaid
                                                       ? Icons.check_circle_rounded
                                                       : Icons.hourglass_full_rounded,
                                                   color: isPaid
                                                       ? const Color(0xFF2E7D32)
                                                       : const Color(0xFFF57F17),
                                                   size: 12,
                                                 ),
                                                 const SizedBox(width: 4),
                                                 Text(
                                                   isPaid ? 'Paid' : 'Unpaid',
                                                   style: TextStyle(
                                                     fontSize: 10,
                                                     fontWeight: FontWeight.w800,
                                                     color: isPaid
                                                         ? const Color(0xFF2E7D32)
                                                         : const Color(0xFFF57F17),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           ),
                                         ],
                                       ),
                                       const SizedBox(height: 4),
                                       Text(
                                         'Farmer: $farmerName',
                                         style: const TextStyle(
                                           fontSize: 12,
                                           color: Color(0xFF64748B),
                                           fontWeight: FontWeight.w500,
                                         ),
                                       ),
                                       const SizedBox(height: 8),
                                       Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                           Text(
                                             '$qty $unit @ LKR ${rate.toStringAsFixed(0)}/$unit',
                                             style: const TextStyle(
                                               fontSize: 12,
                                               color: Color(0xFF64748B),
                                               fontWeight: FontWeight.w500,
                                             ),
                                           ),
                                           Text(
                                             'Total: LKR ${total.toStringAsFixed(0)}',
                                             style: const TextStyle(
                                               fontSize: 13,
                                               fontWeight: FontWeight.w800,
                                               color: AppTheme.deepLeafGreen,
                                             ),
                                           ),
                                         ],
                                       ),
                                     ],
                                   ),
                                 ),
                               ],
                             ),
                                                    /*
                              if (id > 0) ...[
                                const SizedBox(height: 16),
                                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    // Chat Button
                                    if (farmerId != null) ...[  
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                otherUserId: farmerId,
                                                otherUserName: farmerName,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                        label: const Text(
                                          'Chat',
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.deepLeafGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    // Pay Now or Review Button
                                    if (!isPaid)
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PaymentScreen(
                                                confirmedBidId: id,
                                                confirmedBid: bid,
                                              ),
                                            ),
                                          );
                                          _loadConfirmedBids();
                                        },
                                        icon: const Icon(Icons.payment_rounded, size: 14),
                                        label: const Text(
                                          'Pay Now',
                                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.deepLeafGreen,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      )
                                    else if (!hasReview)
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ReviewScreen(
                                                confirmedBidId: id,
                                                confirmedBid: bid,
                                              ),
                                            ),
                                          );
                                          _loadConfirmedBids();
                                        },
                                        icon: const Icon(Icons.star_rate_rounded, size: 14),
                                        label: const Text(
                                          'Review Farmer',
                                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.accentGold,
                                          foregroundColor: const Color(0xFF0F172A),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.star_rounded, color: Colors.grey, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'Reviewed',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              */
                            ],
                          ),
                       ),
                     ),
                   );
                } catch (e, stack) {
                  debugPrint("Error rendering purchase card: $e\n$stack");
                  return Card(
                    color: Colors.red[50],
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text("Error rendering card: $e\nRaw item: ${_confirmedBids[index]}"),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    ),
    );
  }
}
