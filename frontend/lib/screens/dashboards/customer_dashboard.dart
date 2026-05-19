import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Aswenna Retail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.deepLeafGreen),
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
            // Search field
            const TextField(
              decoration: InputDecoration(
                hintText: 'Search fresh groceries & home gardens...',
                prefixIcon: Icon(Icons.search, color: AppTheme.deepLeafGreen),
              ),
            ),
            const SizedBox(height: 24),
            // Promotions banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.orange, Colors.amber]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WEEKLY PROMOTIONS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Get 15% Off Seeds', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      SizedBox(height: 2),
                      Text('Code: ASWENNA15', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                  Icon(Icons.discount_rounded, color: Colors.white, size: 48),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Browse Retail Stores',
              style: TextStyle(color: AppTheme.darkGreen, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _buildStoreItem('Agro Lanka Seedlings', 'Seeds, fertilizer & seedlings', '4.8 ⭐ (120+ reviews)', Icons.eco),
            const SizedBox(height: 12),
            _buildStoreItem('Green Field Organics', 'Home garden kits & organic fertilizers', '4.9 ⭐ (80+ reviews)', Icons.spa),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppTheme.deepLeafGreen,
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_mall_rounded), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Favorites'),
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

  Widget _buildStoreItem(String title, String desc, String rating, IconData icon) {
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
                decoration: const BoxDecoration(color: AppTheme.lightMint, shape: BoxShape.circle),
                child: Icon(icon, color: AppTheme.deepLeafGreen, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(rating, style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.deepLeafGreen, size: 14),
        ],
      ),
    );
  }
}
