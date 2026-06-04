import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/dashboards/buyer_dashboard.dart';
import 'package:aswenna/screens/market_rates/retailer_profile_screen.dart';
import 'package:aswenna/screens/dashboards/retailer_products_screen.dart';

import 'package:aswenna/screens/dashboards/retailer_orders_screen.dart';

class RetailerDashboard extends StatefulWidget {
  const RetailerDashboard({super.key});

  @override
  State<RetailerDashboard> createState() => _RetailerDashboardState();
}

class _RetailerDashboardState extends State<RetailerDashboard> {
  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (mounted) setState(() => _isLoading = true);
    await Future.wait([
      _fetchProducts(),
      _fetchOrders(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await ApiService.getRetailerProducts();
      if (response['success'] == true && mounted) {
        setState(() {
          _products = response['products'] ?? [];
        });
      }
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await ApiService.getRetailerOrders();
      if (response['success'] == true && mounted) {
        setState(() {
          _orders = response['orders'] ?? [];
        });
      }
    } catch (e) {
      // Fail silently
    }
  }

  void _navigateToInventory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RetailerProductsScreen()),
    ).then((_) => _fetchDashboardData());
  }

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RetailerProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.deepLeafGreen,
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RetailerOrdersScreen()),
                            ).then((_) => _fetchDashboardData());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.lightMint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _buildMiniMetric('Orders', '${_orders.length} Sales'),
                          ),
                        ),
                        _buildMiniMetric('Inventory', '${_products.length} Items'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Banner to Manage Shop
              GestureDetector(
                onTap: _navigateToInventory,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.deepLeafGreen, AppTheme.darkGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Inventory',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add, edit or update products',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick Inventory Check',
                    style: TextStyle(color: AppTheme.darkGreen, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: _navigateToInventory,
                    child: const Text('See All', style: TextStyle(color: AppTheme.deepLeafGreen)),
                  )
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppTheme.deepLeafGreen),
                ))
              else if (_products.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: Colors.grey[400], size: 48),
                        const SizedBox(height: 12),
                        Text('Your shop is empty.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                ..._products.take(3).map((product) {
                  final price = double.parse(product['price_per_unit'].toString());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildInventoryItem(
                      product['product_name'] ?? 'Product',
                      'Stock: ${product['stock_quantity']} ${product['unit_type']}',
                      'LKR ${price.toStringAsFixed(2)}',
                      product['thumbnail_path'],
                    ),
                  );
                }),
            ],
          ),
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
          if (index == 1) {
            _navigateToInventory();
          } else if (index == 2) {
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

  Widget _buildInventoryItem(String title, String stock, String price, String? thumbnailPath) {
    final imageUrl = thumbnailPath != null ? ApiService.fileUrl(thumbnailPath) : null;

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
                  decoration: BoxDecoration(
                    color: AppTheme.softGray,
                    shape: BoxShape.circle,
                    image: imageUrl != null
                        ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imageUrl == null
                      ? const Icon(Icons.spa_rounded, color: AppTheme.deepLeafGreen, size: 22)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
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
