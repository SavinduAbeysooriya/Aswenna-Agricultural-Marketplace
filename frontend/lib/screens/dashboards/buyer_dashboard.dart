import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';

class BuyerDashboard extends StatelessWidget {
  const BuyerDashboard({super.key});

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
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        currentIndex: 0,
        selectedItemColor: AppTheme.deepLeafGreen,
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_rounded), label: 'Purchases'),
          BottomNavigationBarItem(icon: Icon(Icons.logout_rounded), label: 'Logout'),
        ],
        onTap: (index) {
          if (index == 2) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
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
