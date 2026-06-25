import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/market_rates/retailer_profile_view_screen.dart';
import 'package:aswenna/screens/market_rates/delivery_profile_view_screen.dart';
import 'package:aswenna/screens/chat/chat_screen.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/screens/dashboards/order_tracking_screen.dart';
import 'package:aswenna/screens/dashboards/order_review_dialog.dart';
import 'package:aswenna/screens/dashboards/customer_profile_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Profile Verification State
  bool _isVerified = false;
  bool _hasPendingDoc = false;
  bool _hasRejectedDoc = false;
  String? _profilePic;

  @override
  void initState() {
    super.initState();
    _loadProfileStatus();
    _loadOrders();
  }

  Future<void> _loadProfileStatus() async {
    try {
      final result = await ApiService.getBuyerProfile();
      if (mounted && result['success'] == true) {
        final profile = result['profile'] ?? {};
        final user = profile['user'] ?? {};
        final docsVal = profile['documents'];
        final List<dynamic> documents = docsVal is List ? docsVal : [];
        setState(() {
          _isVerified = user['is_verified'] == true;
          _hasPendingDoc = documents.any((doc) => doc is Map && doc['verification_status'] == 'pending');
          _hasRejectedDoc = documents.any((doc) => doc is Map && doc['verification_status'] == 'rejected');
          _profilePic = user['profile_picture_path'];
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _loadOrders() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    _loadProfileStatus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getCustomerOrders();
      if (response['success'] == true) {
        setState(() {
          _orders = response['orders'] ?? [];
        });
      } else {
        if (response['message']?.toString().toLowerCase().contains('expired') == true ||
            response['message']?.toString().toLowerCase().contains('sign in') == true ||
            response['message']?.toString().toLowerCase().contains('unauthenticated') == true ||
            response['message']?.toString().toLowerCase().contains('unauthorized') == true) {
          _redirectToLogin();
          return;
        }
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load orders.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailSheet(order: order),
    ).then((_) {
      _loadOrders();
    });
  }

  void _openReviewDialog(int orderId, int targetId, String name, String role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderReviewDialog(
        orderId: orderId,
        reviewedToId: targetId,
        recipientName: name,
        recipientRole: role,
      ),
    ).then((success) {
      if (success == true) {
        _loadOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('My Retail Orders'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.darkGreen),
            onPressed: _loadOrders,
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
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
                      child: _profilePic != null && _profilePic!.isNotEmpty
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadOrders, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, color: AppTheme.deepLeafGreen.withOpacity(0.4), size: 100),
                          const SizedBox(height: 16),
                          const Text(
                            'No orders found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          const Text('Place a retail order to track shipping progress!', style: TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: AppTheme.deepLeafGreen,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return OrderListItemCard(
                            order: order,
                            onTap: () => _showOrderDetail(order),
                            onOpenReview: (targetId, name, role) => _openReviewDialog(order['id'], targetId, name, role),
                          );
                        },
                      ),
                    ),
    );
  }
}

class OrderListItemCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final Function(int targetId, String name, String role) onOpenReview;

  const OrderListItemCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onOpenReview,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['order_status'] ?? 'pending';
    final total = double.parse(order['total_amount'].toString());
    final date = DateTime.parse(order['created_at']);
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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

    final items = order['items'] as List? ?? [];
    final sellers = items.map((item) => item['retailer']?['full_name'] ?? 'Retailer Shop').toSet().toList();
    final sellersText = sellers.isEmpty ? 'Retailer Shop' : sellers.join(', ');

    // Build rating buttons for delivered/completed orders
    final ratingButtons = <Widget>[];
    final isDeliveredOrCompleted = status == 'delivered' || status == 'completed';

    if (isDeliveredOrCompleted) {
      final reviews = order['reviews'] as List? ?? [];
      final customerId = order['customer_id'] as int?;

      // 1. Check each unique retailer seller
      final uniqueRetailers = <int, Map<String, dynamic>>{};
      for (var item in items) {
        final retailer = item['retailer'];
        if (retailer != null && retailer['id'] != null) {
          uniqueRetailers[retailer['id'] as int] = retailer as Map<String, dynamic>;
        }
      }

      for (var entry in uniqueRetailers.entries) {
        final retailerId = entry.key;
        final retailer = entry.value;
        final retailerName = retailer['full_name'] ?? 'Retailer';

        final hasReviewedRetailer = reviews.any((review) =>
            review['reviewed_by'] == customerId && review['reviewed_to'] == retailerId);

        if (!hasReviewedRetailer) {
          final buttonText = uniqueRetailers.length == 1 ? 'Rate Seller' : 'Rate Seller: $retailerName';
          ratingButtons.add(
            GestureDetector(
              onTap: () => onOpenReview(retailerId, retailerName, 'Retailer'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rate_rounded, color: AppTheme.accentGold, size: 16),
                    const SizedBox(width: 6),
                    Text(buttonText, style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }
      }

      // 2. Check delivery partner
      final deliveryPartner = order['deliveryPartner'];
      final deliveryPartnerId = order['delivery_partner_id'] as int?;
      if (deliveryPartnerId != null) {
        final partnerName = deliveryPartner != null ? (deliveryPartner['full_name'] ?? 'Delivery Partner') : 'Delivery Partner';
        final hasReviewedPartner = reviews.any((review) =>
            review['reviewed_by'] == customerId && review['reviewed_to'] == deliveryPartnerId);

        if (!hasReviewedPartner) {
          ratingButtons.add(
            GestureDetector(
              onTap: () => onOpenReview(deliveryPartnerId, partnerName, 'Delivery Partner'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rate_rounded, color: AppTheme.accentGold, size: 16),
                    SizedBox(width: 6),
                    Text('Rate Delivery Partner', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order['order_number'] ?? 'Order No',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.store_rounded, color: AppTheme.deepLeafGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sellersText,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Placed on: $formattedDate',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const Divider(height: 24, color: AppTheme.softGray),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Cost', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text(
                      'LKR ${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                    ),
                  ],
                ),
                // Track button for active deliveries
                if (status == 'out_for_delivery' || status == 'picked_up' || status == 'on_the_way' || status == 'delivered') ...
                  [
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(
                            orderId: order['id'],
                            orderNumber: order['order_number'] ?? '',
                          ),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.lightMint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.freshGreen),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on_rounded, color: AppTheme.deepLeafGreen, size: 16),
                            SizedBox(width: 6),
                            Text('Track Order', style: TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],

                // Add rating buttons if any are applicable
                if (ratingButtons.isNotEmpty) ...ratingButtons,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrderDetailSheet extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailSheet({super.key, required this.order});

  @override
  State<OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<OrderDetailSheet> {
  List<dynamic> _existingReviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final status = widget.order['order_status'] ?? 'pending';
    if (status != 'delivered' && status != 'completed') {
      setState(() => _isLoadingReviews = false);
      return;
    }

    setState(() => _isLoadingReviews = true);
    try {
      final res = await ApiService.getOrderReviews(widget.order['id']);
      if (res['success'] == true && mounted) {
        setState(() {
          _existingReviews = res['reviews'] ?? [];
          _isLoadingReviews = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingReviews = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  bool _hasReviewed(int userId) {
    return _existingReviews.any((review) =>
        review['reviewed_to'] == userId && review['reviewed_by'] == widget.order['customer_id']);
  }

  int? _getReviewRating(int userId) {
    for (var r in _existingReviews) {
      if (r['reviewed_to'] == userId && r['reviewed_by'] == widget.order['customer_id']) {
        return int.tryParse(r['ratings'].toString());
      }
    }
    return null;
  }

  void _openReviewDialog(int targetId, String name, String role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderReviewDialog(
        orderId: widget.order['id'],
        reviewedToId: targetId,
        recipientName: name,
        recipientRole: role,
      ),
    ).then((success) {
      if (success == true) {
        _loadReviews();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['order_status'] ?? 'pending';
    final subtotal = double.parse(widget.order['subtotal_amount'].toString());
    final deliveryFee = double.parse(widget.order['delivery_fee'].toString());
    final total = double.parse(widget.order['total_amount'].toString());
    final items = widget.order['items'] as List? ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.softGray,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.order['order_number'] ?? 'Order details',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
              ),
              const SizedBox(height: 4),
              // Interactive Retailers and Delivery Contact Buttons
              () {
                final uniqueRetailers = <int, Map<String, dynamic>>{};
                for (var item in items) {
                  final retailer = item['retailer'];
                  if (retailer != null && retailer['id'] != null) {
                    uniqueRetailers[retailer['id'] as int] = retailer as Map<String, dynamic>;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Partners & Contacts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    ...uniqueRetailers.values.map((retailer) {
                      final rId = retailer['id'] as int;
                      final rName = retailer['full_name'] ?? 'Retailer';
                      final String? rPic = retailer['profile_picture_path'];
                      final rPicUrl = rPic != null && rPic.isNotEmpty ? ApiService.fileUrl(rPic) : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.lightMint,
                              backgroundImage: rPicUrl != null ? NetworkImage(rPicUrl) : null,
                              child: rPicUrl == null ? const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.deepLeafGreen) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  const Text('Retail Seller', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.deepLeafGreen, size: 18),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      otherUserId: rId,
                                      otherUserName: rName,
                                      otherUserProfilePicture: rPicUrl,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_outline_rounded, color: AppTheme.deepLeafGreen, size: 18),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RetailerProfileViewScreen(
                                      retailerId: rId,
                                      retailerName: rName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    // Delivery Partner Row
                    if (widget.order['deliveryPartner'] != null) ...[
                      () {
                        final partner = widget.order['deliveryPartner'];
                        final partnerId = partner['id'] as int;
                        final partnerName = partner['full_name'] ?? 'Delivery Partner';
                        final String? pPic = partner['profile_picture_path'];
                        final pPicUrl = pPic != null && pPic.isNotEmpty ? ApiService.fileUrl(pPic) : null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.pureWhite,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.lightMint,
                                backgroundImage: pPicUrl != null ? NetworkImage(pPicUrl) : null,
                                child: pPicUrl == null ? const Icon(Icons.local_shipping_rounded, size: 18, color: AppTheme.deepLeafGreen) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(partnerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                    const Text('Delivery Rider', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.deepLeafGreen, size: 18),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        otherUserId: partnerId,
                                        otherUserName: partnerName,
                                        otherUserProfilePicture: pPicUrl,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.person_outline_rounded, color: AppTheme.deepLeafGreen, size: 18),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DeliveryProfileViewScreen(
                                        partnerId: partnerId,
                                        partnerName: partnerName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }(),
                    ],
                  ],
                );
              }(),
              const SizedBox(height: 20),

              // Order status visual bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.deepLeafGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Shipping Stage', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          Text(
                            status.toUpperCase().replaceAll('_', ' '),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Items List
              const Text('Ordered Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final finalPrice = double.parse(item['final_price'].toString());
                    final String? thumb = item['product']?['thumbnail_path'];
                    final imageUrl = thumb != null ? ApiService.fileUrl(thumb) : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.softGray,
                              borderRadius: BorderRadius.circular(8),
                              image: imageUrl != null
                                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: imageUrl == null
                                ? const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product']?['product_name'] ?? 'Product',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Grade ${item['grade']} x ${item['quantity']} (${item['retailer']?['full_name'] ?? 'Seller'})',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'LKR ${finalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Shipping Cost and Totals Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items Subtotal', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text('LKR ${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text('LKR ${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20, color: AppTheme.softGray),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
                        Text(
                          'LKR ${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Feedback & Ratings
              if (status == 'delivered' || status == 'completed') ...[
                const SizedBox(height: 20),
                const Text(
                  'Feedback & Ratings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGreen),
                ),
                const SizedBox(height: 8),
                if (_isLoadingReviews)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: AppTheme.deepLeafGreen, strokeWidth: 2),
                  ))
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // 1. Rate Retailers
                        ...() {
                          final uniqueRetailers = <int, Map<String, dynamic>>{};
                          for (var item in items) {
                            final retailer = item['retailer'];
                            if (retailer != null && retailer['id'] != null) {
                              uniqueRetailers[retailer['id'] as int] = retailer as Map<String, dynamic>;
                            }
                          }

                          return uniqueRetailers.values.map((retailer) {
                            final retailerId = retailer['id'] as int;
                            final retailerName = retailer['full_name'] ?? 'Retailer';
                            
                            final reviewed = _hasReviewed(retailerId);
                            final rating = _getReviewRating(retailerId);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          retailerName,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text('Retail Seller', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  if (reviewed)
                                    Row(
                                      children: List.generate(5, (star) => Icon(
                                        Icons.star_rounded,
                                        color: star < (rating ?? 0) ? AppTheme.accentGold : Colors.grey[300],
                                        size: 16,
                                      )),
                                    )
                                  else
                                    TextButton.icon(
                                      onPressed: () => _openReviewDialog(retailerId, retailerName, 'Retailer'),
                                      icon: const Icon(Icons.rate_review_rounded, size: 14, color: AppTheme.deepLeafGreen),
                                      label: const Text('Rate Seller', style: TextStyle(fontSize: 11, color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        backgroundColor: AppTheme.lightMint,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          });
                        }(),

                        // 2. Rate Delivery Partner
                        if (widget.order['deliveryPartner'] != null) ...[
                          const Divider(height: 16, color: AppTheme.softGray),
                          Builder(
                            builder: (context) {
                              final partner = widget.order['deliveryPartner'];
                              final partnerId = partner['id'] as int;
                              final partnerName = partner['full_name'] ?? 'Delivery Partner';
                              final reviewed = _hasReviewed(partnerId);
                              final rating = _getReviewRating(partnerId);

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          partnerName,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text('Delivery Partner', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  if (reviewed)
                                    Row(
                                      children: List.generate(5, (star) => Icon(
                                        Icons.star_rounded,
                                        color: star < (rating ?? 0) ? AppTheme.accentGold : Colors.grey[300],
                                        size: 16,
                                      )),
                                    )
                                  else
                                    TextButton.icon(
                                      onPressed: () => _openReviewDialog(partnerId, partnerName, 'Delivery Partner'),
                                      icon: const Icon(Icons.local_shipping_rounded, size: 14, color: AppTheme.deepLeafGreen),
                                      label: const Text('Rate Partner', style: TextStyle(fontSize: 11, color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        backgroundColor: AppTheme.lightMint,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                ],
                              );
                            }
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
