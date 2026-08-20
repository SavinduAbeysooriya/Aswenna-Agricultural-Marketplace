import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/dashboards/buyer_dashboard.dart';
import 'package:aswenna/screens/market_rates/retailer_profile_screen.dart';
import 'package:aswenna/screens/dashboards/retailer_products_screen.dart';

import 'package:aswenna/screens/dashboards/retailer_orders_screen.dart';
import 'package:aswenna/screens/my_offers_screen.dart';
import 'package:aswenna/screens/dashboards/retailer_wallet_screen.dart';
import 'package:aswenna/screens/dashboards/retailer_campaigns_screen.dart';
import 'package:aswenna/screens/notifications/notifications_screen.dart';

class RetailerDashboard extends StatefulWidget {
  const RetailerDashboard({super.key});

  @override
  State<RetailerDashboard> createState() => _RetailerDashboardState();
}

class _RetailerDashboardState extends State<RetailerDashboard> {
  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  List<dynamic> _retailerCampaigns = [];
  bool _isLoading = true;
  bool _isVerified = false;
  bool _hasPendingDoc = false;
  bool _hasRejectedDoc = false;
  String? _rejectionReason;
  String? _profilePic;

  @override
  void initState() {
    super.initState();
    _loadProfileStatus();
    _fetchDashboardData();
  }

  Future<void> _loadProfileStatus() async {
    try {
      final result = await ApiService.getRetailSellerProfile();
      if (mounted && result['success'] == true) {
        final profile = result['profile'] ?? {};
        
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

  Future<void> _fetchDashboardData() async {
    if (mounted) setState(() => _isLoading = true);
    await Future.wait([
      _fetchProducts(),
      _fetchOrders(),
      _fetchRetailerCampaigns(),
      _loadProfileStatus(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRetailerCampaigns() async {
    try {
      final res = await ApiService.getRetailerCampaigns();
      if (res['success'] == true && mounted) {
        setState(() {
          _retailerCampaigns = List<dynamic>.from(res['campaigns'] ?? []);
        });
      }
    } catch (_) {}
  }

  void _showCreateCampaignDialog() {
    final titleController = TextEditingController(text: 'Weekend Harvest Festival');
    final discountController = TextEditingController(text: '15');
    final categoryController = TextEditingController(text: 'Fresh Vegetables');
    final durationController = TextEditingController(text: '3');

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Flash Sale Promo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Campaign Title',
                      hintText: 'e.g. Weekend Harvest Festival',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Discount %',
                            suffixText: '% OFF',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Duration (Days)',
                            suffixText: 'Days',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: 'Target Category',
                      hintText: 'e.g. Fresh Vegetables',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepLeafGreen,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final discount = double.tryParse(discountController.text.trim()) ?? 15.0;
                        final category = categoryController.text.trim();
                        final duration = int.tryParse(durationController.text.trim()) ?? 3;

                        Navigator.of(context, rootNavigator: true).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Creating flash sale campaign...')),
                        );

                        final res = await ApiService.createRetailerCampaign(
                          title: title.isEmpty ? 'Weekend Harvest Festival' : title,
                          discountPercentage: discount,
                          targetCategory: category.isEmpty ? 'Fresh Vegetables' : category,
                          durationDays: duration,
                        );

                        if (mounted) {
                          if (res['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Campaign recorded with status pending_admin_approval and a scheduled promotional banner preview displayed.'),
                                backgroundColor: AppTheme.deepLeafGreen,
                              ),
                            );
                            _fetchRetailerCampaigns();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message'] ?? 'Failed to create campaign.')),
                            );
                          }
                        }
                      },
                      child: const Text('Create Flash Sale Campaign (RET-002)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCampaignsSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flash Sales & Promos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
                        Text('RET-002: Promotional Offer Campaigns', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        _showCreateCampaignDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepLeafGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('+ Flash Sale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _retailerCampaigns.isEmpty
                      ? const Center(child: Text('No promotional offer campaigns created yet.', style: TextStyle(fontSize: 12, color: Colors.grey)))
                      : ListView.separated(
                          itemCount: _retailerCampaigns.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final c = _retailerCampaigns[index];
                            final title = c['title']?.toString() ?? 'Weekend Harvest Festival';
                            final discount = c['discount_percentage']?.toString() ?? '15';
                            final category = c['target_category']?.toString() ?? 'Fresh Vegetables';
                            final status = c['status']?.toString() ?? 'pending_admin_approval';
                            final code = c['code']?.toString() ?? 'WEEKEND-HARVEST-15';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTheme.deepLeafGreen.withOpacity(0.15)),
                                boxShadow: [
                                  BoxShadow(color: AppTheme.deepLeafGreen.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: AppTheme.lightMint, borderRadius: BorderRadius.circular(14)),
                                    child: const Icon(Icons.local_offer_rounded, color: AppTheme.deepLeafGreen, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentGold.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                status,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Code: #$code • Category: $category', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        const SizedBox(height: 6),
                                        Text('$discount% OFF Flash Sale • Scheduled Preview', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.deepLeafGreen)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    double totalEarnings = 0.0;
    int completedOrdersCount = 0;
    int pendingOrdersCount = 0;

    for (var order in _orders) {
      final status = order['order_status'] ?? 'pending';
      final items = order['retailer_items'] as List? ?? [];
      final double orderTotal = items.fold(0.0, (sum, item) => sum + double.parse(item['final_price'].toString()));

      if (status == 'completed' || status == 'delivered') {
        totalEarnings += orderTotal;
        completedOrdersCount++;
      } else if (status != 'cancelled') {
        pendingOrdersCount++;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Retailer Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.deepLeafGreen),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RetailerProfileScreen()),
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
      body: RefreshIndicator(
        color: AppTheme.deepLeafGreen,
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Status Overview Card (Stunning Header)
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agro Retail Mart',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Retail seller dashboard console',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.lightMint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppTheme.deepLeafGreen, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text('ONLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stunning Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Earnings',
                      value: 'LKR ${totalEarnings >= 1000 ? "${(totalEarnings / 1000).toStringAsFixed(1)}K" : totalEarnings.toStringAsFixed(0)}',
                      subtitle: 'From completed orders',
                      icon: Icons.monetization_on_rounded,
                      color: const Color(0xFF2E7D32),
                      bgColor: const Color(0xFFE8F5E9),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Orders',
                      value: '${_orders.length}',
                      subtitle: 'All order status history',
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF1565C0),
                      bgColor: const Color(0xFFE3F2FD),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Active Orders',
                      value: '$pendingOrdersCount',
                      subtitle: 'Awaiting fulfillment',
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFE65100),
                      bgColor: const Color(0xFFFFF3E0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Products in Shop',
                      value: '${_products.length}',
                      subtitle: 'Active inventory items',
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFF7B1FA2),
                      bgColor: const Color(0xFFF3E5F5),
                    ),
                  ),
                ],
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
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepLeafGreen.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
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
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RetailerCampaignsScreen()),
                    ).then((_) => _fetchRetailerCampaigns());
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4A017), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4A017).withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Flash Sales & Promo Campaigns',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_retailerCampaigns.length} active campaigns • Tap to view (RET-002)',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Recent Customer Orders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Customer Orders',
                    style: TextStyle(color: AppTheme.darkGreen, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RetailerOrdersScreen()),
                      ).then((_) => _fetchDashboardData());
                    },
                    child: const Text('See All', style: TextStyle(color: AppTheme.deepLeafGreen)),
                  )
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppTheme.deepLeafGreen),
                  ),
                )
              else if (_orders.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: Colors.grey[400], size: 48),
                        const SizedBox(height: 12),
                        Text('No recent customer orders.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                ..._orders.take(3).map((order) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildRecentOrderCard(order),
                  );
                }),
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
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
        ],
        onTap: (index) {
          if (index == 1) {
            _navigateToInventory();
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RetailerOrdersScreen()),
            ).then((_) => _fetchDashboardData());
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RetailerWalletScreen()),
            ).then((_) => _fetchDashboardData());
          }
        },
      ),
    );
  }

  Widget _buildRecentOrderCard(dynamic order) {
    final status = order['order_status'] ?? 'pending';
    final items = order['retailer_items'] as List? ?? [];
    final double salesTotal = items.fold(0.0, (sum, item) => sum + double.parse(item['final_price'].toString()));
    final date = DateTime.parse(order['created_at']);
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final customerName = order['customer']?['full_name'] ?? 'Buyer';

    Color statusColor;
    switch (status) {
      case 'completed':
      case 'delivered':
        statusColor = AppTheme.deepLeafGreen;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'processing':
      case 'confirmed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RetailerOrdersScreen()),
            ).then((_) => _fetchDashboardData());
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_bag_outlined, color: statusColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              order['order_number'] ?? 'Order No',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LKR ${salesTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Customer: $customerName',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            status.toUpperCase().replaceAll('_', ' '),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$formattedDate · ${items.length} items',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: color.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
