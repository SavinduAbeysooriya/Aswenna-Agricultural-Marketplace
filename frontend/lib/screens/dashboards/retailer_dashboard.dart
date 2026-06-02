import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/dashboards/buyer_dashboard.dart';

class RetailerDashboard extends StatelessWidget {
  const RetailerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Retailer Center'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const BuyerDashboard()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.deepLeafGreen),
            label: const Text('Buyer Mode', style: TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.deepLeafGreen),
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
            // Store Status Overview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepLeafGreen.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Agro Retail Mart',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.lightMint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('ONLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen)),
                      ),
                    ],
                  ),
                  const Divider(height: 30, color: AppTheme.softGray),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniMetric('Total Sales', 'LKR 45K'),
                      _buildMiniMetric('Orders', '12 Done'),
                      _buildMiniMetric('Inventory', '8 Products'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Inventory Check',
              style: TextStyle(color: AppTheme.darkGreen, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _buildInventoryItem('High-yield Seeds Pack', 'Stock: 45 units', 'LKR 450.00', Icons.spa_rounded),
            const SizedBox(height: 12),
            _buildInventoryItem('Organic Liquid Fertilizer', 'Stock: 12 units', 'LKR 1,850.00', Icons.water_drop_rounded),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppTheme.deepLeafGreen,
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Console'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_rounded), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.logout_rounded), label: 'Logout'),
        ],
        onTap: (index) {
          if (index == 2) {
            ApiService.logout().then((_) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            });
          }
        },
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
      ],
    );
  }

  Widget _buildInventoryItem(String title, String stock, String price, IconData icon) {
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
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppTheme.softGray, shape: BoxShape.circle),
                  child: Icon(icon, color: AppTheme.deepLeafGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(stock, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(price, style: const TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
