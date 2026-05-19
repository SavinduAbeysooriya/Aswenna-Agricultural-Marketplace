import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';

class DeliveryDashboard extends StatelessWidget {
  const DeliveryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Delivery Console'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver earnings status card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.deepLeafGreen, AppTheme.freshGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today\'s Payout', style: TextStyle(color: AppTheme.lightMint, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('LKR 3,850.00', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      SizedBox(height: 6),
                      Text('4 Completed Deliveries', style: TextStyle(color: AppTheme.lightMint, fontSize: 11)),
                    ],
                  ),
                  Icon(Icons.sports_motorsports_rounded, color: AppTheme.lightMint, size: 54),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Assigned Tasks',
              style: TextStyle(color: AppTheme.darkGreen, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(24),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('LKR 450.00 Payout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.lightMint, borderRadius: BorderRadius.circular(6)),
                        child: const Text('HEADING TO PICKUP', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen)),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppTheme.softGray),
                  const Text('PICKUP LOCATION:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  const Text('Saman Kumara\'s Farm, Nuwara Eliya', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  const Text('DELIVERY DESTINATION:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  const Text('Central Supermarket Warehouse, Kandy', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepLeafGreen,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: const Text('Update Assignment Status'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppTheme.deepLeafGreen,
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.navigation_rounded), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet_rounded), label: 'Earnings'),
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
}
