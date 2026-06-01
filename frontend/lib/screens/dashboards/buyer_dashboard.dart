import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/screens/market_rates/market_rates_screen.dart';
import 'package:aswenna/screens/market_rates/buyer_profile_screen.dart';
import 'package:aswenna/services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfileStatus();
  }

  Future<void> _loadProfileStatus() async {
    final result = await ApiService.getBuyerProfile();
    if (mounted && result['success'] == true) {
      final profile = result['profile'] ?? {};
      final user = profile['user'] ?? {};
      final documents = profile['documents'] ?? [];
      setState(() {
        _isVerified = user['is_verified'] == true;
        _hasPendingDoc = documents.any((doc) => doc['verification_status'] == 'pending');
        _hasRejectedDoc = documents.any((doc) => doc['verification_status'] == 'rejected');
        if (_hasRejectedDoc) {
          final rejectedDoc = documents.firstWhere(
            (doc) => doc['verification_status'] == 'rejected',
            orElse: () => null,
          );
          _rejectionReason = rejectedDoc?['rejection_reason'];
        } else {
          _rejectionReason = null;
        }
        _profilePic = user['profile_picture_path'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                : (_hasRejectedDoc ? Colors.red : Colors.grey[300]!)),
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
                                : (_hasRejectedDoc ? Colors.red : Colors.grey[500]!)),
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
      body: SingleChildScrollView(
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
            // Premium direct yields grid
            const Text(
              'Premium Direct Yields',
              style: TextStyle(color: AppTheme.darkGreen, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
              children: [
                _buildProductGridItem('Nuwara Eliya Carrots', 'Seller: Saman K.', 'LKR 180/kg', Icons.eco, 'Grade A'),
                _buildProductGridItem('Red Onions (Jaffna)', 'Seller: Sunil P.', 'LKR 280/kg', Icons.spa, 'Fresh'),
              ],
            ),
            const SizedBox(height: 24),
            // Direct harvest bids
            const Text(
              'Bidding Opportunities',
              style: TextStyle(color: AppTheme.darkGreen, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _buildBiddingOpportunityCard('Premium Keeri Samba Yield', 'Anuradhapura • 2,500 kg', 'Current Bid: LKR 195/kg', Icons.gavel_rounded),
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
          }
        },
      ),
    );
  }

  Widget _buildProductGridItem(String title, String seller, String price, IconData icon, String badge) {
    return Container(
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
                  Icon(icon, color: AppTheme.deepLeafGreen, size: 48),
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
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(seller, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(price, style: const TextStyle(color: AppTheme.deepLeafGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: AppTheme.deepLeafGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: AppTheme.pureWhite, size: 14),
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

  Widget _buildBiddingOpportunityCard(String title, String qty, String price, IconData icon) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: const Color(0xFFFFF9E6), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: AppTheme.accentGold, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(qty, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
                ],
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.accentGold, size: 16),
        ],
      ),
    );
  }
}
