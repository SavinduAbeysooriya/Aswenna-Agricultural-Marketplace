import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/dashboards/order_review_dialog.dart';
import 'package:aswenna/screens/chat/chat_screen.dart';
import 'package:aswenna/screens/market_rates/buyer_profile_view_screen.dart';
import 'package:aswenna/screens/market_rates/delivery_profile_view_screen.dart';

class RetailerOrdersScreen extends StatefulWidget {
  const RetailerOrdersScreen({super.key});

  @override
  State<RetailerOrdersScreen> createState() => _RetailerOrdersScreenState();
}

class _RetailerOrdersScreenState extends State<RetailerOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getRetailerOrders();
      if (response['success'] == true && mounted) {
        setState(() {
          _orders = response['orders'] ?? [];
        });
      } else {
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
        setState(() => _isLoading = false);
      }
    }
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RetailerOrderDetailSheet(
        order: order,
        onReviewSubmitted: _fetchOrders,
      ),
    ).then((_) {
      _fetchOrders();
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
        _fetchOrders();
      }
    });
  }

  Widget _buildSummaryCard(double totalEarnings, int completed, int pending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Store Earnings',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Live Stats', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'LKR ${totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$completed Orders', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        const Text('Completed', style: TextStyle(color: Colors.white60, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                      child: const Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$pending Orders', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        const Text('Pending Fulfillment', style: TextStyle(color: Colors.white60, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalEarnings = 0.0;
    int completedCount = 0;
    int pendingCount = 0;

    for (var order in _orders) {
      final status = order['order_status'] ?? 'pending';
      final items = order['retailer_items'] as List? ?? [];
      final double orderTotal = items.fold(0.0, (sum, item) => sum + double.parse(item['final_price'].toString()));

      if (status == 'completed' || status == 'delivered') {
        totalEarnings += orderTotal;
        completedCount++;
      } else if (status != 'cancelled') {
        pendingCount++;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Store Orders & Sales'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.darkGreen),
            onPressed: _fetchOrders,
          )
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
                        ElevatedButton(onPressed: _fetchOrders, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  color: AppTheme.deepLeafGreen,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.isEmpty ? 1 : _orders.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildSummaryCard(totalEarnings, completedCount, pendingCount);
                      }
                      final order = _orders[index - 1];
                      return RetailerOrderListItemCard(
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

class RetailerOrderListItemCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final Function(int targetId, String name, String role) onOpenReview;

  const RetailerOrderListItemCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onOpenReview,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['order_status'] ?? 'pending';
    final items = order['retailer_items'] as List? ?? [];
    final double salesTotal = items.fold(0.0, (sum, item) => sum + double.parse(item['final_price'].toString()));
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

    final ratingButtons = <Widget>[];
    if (status == 'delivered' || status == 'completed') {
      final deliveryPartner = order['deliveryPartner'];
      final deliveryPartnerId = order['delivery_partner_id'] as int?;
      if (deliveryPartnerId != null) {
        final partnerName = deliveryPartner != null ? (deliveryPartner['full_name'] ?? 'Delivery Partner') : 'Delivery Partner';
        final itemsList = order['retailer_items'] as List? ?? [];
        if (itemsList.isNotEmpty) {
          final retailerId = itemsList[0]['retailer_id'] as int?;
          if (retailerId != null) {
            final reviews = order['reviews'] as List? ?? [];
            final alreadyReviewed = reviews.any((review) =>
                review['reviewed_by'] == retailerId && review['reviewed_to'] == deliveryPartnerId);

            if (!alreadyReviewed) {
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
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.lightMint,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: order['customer']?['profile_picture_path'] != null
                            ? Image.network(
                                ApiService.fileUrl(order['customer']['profile_picture_path']) ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: AppTheme.deepLeafGreen, size: 14),
                              )
                            : const Icon(Icons.person_rounded, color: AppTheme.deepLeafGreen, size: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Customer: ${order['customer']?['full_name'] ?? 'Buyer'}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (order['customer'] != null) ...[
                      GestureDetector(
                        onTap: () {
                          final customerId = int.tryParse(order['customer']['id'].toString());
                          if (customerId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BuyerProfileViewScreen(
                                  buyerId: customerId,
                                  buyerName: order['customer']['full_name'] ?? 'Customer',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Icon(Icons.account_circle_outlined, color: AppTheme.deepLeafGreen, size: 20),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          final customerId = int.tryParse(order['customer']['id'].toString());
                          if (customerId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUserId: customerId,
                                  otherUserName: order['customer']['full_name'] ?? 'Customer',
                                  otherUserProfilePicture: order['customer']['profile_picture_path'],
                                ),
                              ),
                            );
                          }
                        },
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.deepLeafGreen, size: 18),
                      ),
                    ],
                  ],
                ),
                if (order['deliveryPartner'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.lightMint,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: order['deliveryPartner']?['profile_picture_path'] != null
                              ? Image.network(
                                  ApiService.fileUrl(order['deliveryPartner']['profile_picture_path']) ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.local_shipping_rounded, color: AppTheme.deepLeafGreen, size: 12),
                                )
                              : const Icon(Icons.local_shipping_rounded, color: AppTheme.deepLeafGreen, size: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rider: ${order['deliveryPartner']['full_name']}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final partnerId = int.tryParse(order['deliveryPartner']['id'].toString());
                          if (partnerId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeliveryProfileViewScreen(
                                  partnerId: partnerId,
                                  partnerName: order['deliveryPartner']['full_name'] ?? 'Delivery Partner',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Icon(Icons.account_circle_outlined, color: AppTheme.deepLeafGreen, size: 20),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          final partnerId = int.tryParse(order['deliveryPartner']['id'].toString());
                          if (partnerId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUserId: partnerId,
                                  otherUserName: order['deliveryPartner']['full_name'] ?? 'Delivery Partner',
                                  otherUserProfilePicture: order['deliveryPartner']['profile_picture_path'],
                                ),
                              ),
                            );
                          }
                        },
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.deepLeafGreen, size: 18),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Placed on: $formattedDate · ${items.length} items sold',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const Divider(height: 24, color: AppTheme.softGray),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Earnings', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text(
                      'LKR ${salesTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                    ),
                  ],
                ),
                // Add feedback button if feedback is needed
                if (ratingButtons.isNotEmpty) ...ratingButtons,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RetailerOrderDetailSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onReviewSubmitted;

  const RetailerOrderDetailSheet({
    super.key,
    required this.order,
    required this.onReviewSubmitted,
  });

  @override
  State<RetailerOrderDetailSheet> createState() => _RetailerOrderDetailSheetState();
}

class _RetailerOrderDetailSheetState extends State<RetailerOrderDetailSheet> {
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
    final items = widget.order['retailer_items'] as List? ?? [];
    if (items.isEmpty) return false;
    final retailerId = items[0]['retailer_id'] as int?;
    if (retailerId == null) return false;

    return _existingReviews.any((review) =>
        review['reviewed_to'] == userId && review['reviewed_by'] == retailerId);
  }

  int? _getReviewRating(int userId) {
    final items = widget.order['retailer_items'] as List? ?? [];
    if (items.isEmpty) return null;
    final retailerId = items[0]['retailer_id'] as int?;
    if (retailerId == null) return null;

    for (var r in _existingReviews) {
      if (r['reviewed_to'] == userId && r['reviewed_by'] == retailerId) {
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
        widget.onReviewSubmitted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['order_status'] ?? 'pending';
    final items = widget.order['retailer_items'] as List? ?? [];
    final double salesTotal = items.fold(0.0, (sum, item) => sum + double.parse(item['final_price'].toString()));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.softGray,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.order['order_number'] ?? 'Order details',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                  ),
                  const SizedBox(height: 12),
                  if (widget.order['customer'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Details',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.lightMint,
                                backgroundImage: widget.order['customer']['profile_picture_path'] != null
                                    ? NetworkImage(ApiService.fileUrl(widget.order['customer']['profile_picture_path']) ?? '')
                                    : null,
                                child: widget.order['customer']['profile_picture_path'] == null
                                    ? const Icon(Icons.person, color: AppTheme.deepLeafGreen)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.order['customer']['full_name'] ?? 'Customer',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    Text(
                                      widget.order['customer']['phone_number'] ?? 'No Phone',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F1F1)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final customerId = int.tryParse(widget.order['customer']['id'].toString());
                                    if (customerId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BuyerProfileViewScreen(
                                            buyerId: customerId,
                                            buyerName: widget.order['customer']['full_name'] ?? 'Customer',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.person_outline_rounded, size: 16),
                                  label: const Text('View Profile', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.deepLeafGreen,
                                    side: const BorderSide(color: AppTheme.deepLeafGreen),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final customerId = int.tryParse(widget.order['customer']['id'].toString());
                                    if (customerId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            otherUserId: customerId,
                                            otherUserName: widget.order['customer']['full_name'] ?? 'Customer',
                                            otherUserProfilePicture: widget.order['customer']['profile_picture_path'],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                                  label: const Text('Chat with Customer', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.deepLeafGreen,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Order status
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
                              const Text('Order Stage', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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

                  // Items sold
                  const Text('Sold Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                      'Grade ${item['grade']} x ${item['quantity']}',
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

                  // Total Earnings Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Earnings from Order', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
                        Text(
                          'LKR ${salesTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                        ),
                      ],
                    ),
                  ),

                  // Delivery Partner Feedback
                  if (status == 'delivered' || status == 'completed') ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Delivery Feedback',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGreen),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingReviews)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: AppTheme.deepLeafGreen, strokeWidth: 2),
                      ))
                    else if (widget.order['deliveryPartner'] == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'No delivery partner was assigned to this order.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Builder(
                          builder: (context) {
                            final partner = widget.order['deliveryPartner'];
                            final partnerId = partner['id'] as int;
                            final partnerName = partner['full_name'] ?? 'Delivery Partner';
                            final reviewed = _hasReviewed(partnerId);
                            final rating = _getReviewRating(partnerId);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppTheme.lightMint,
                                      backgroundImage: partner['profile_picture_path'] != null
                                          ? NetworkImage(ApiService.fileUrl(partner['profile_picture_path']) ?? '')
                                          : null,
                                      child: partner['profile_picture_path'] == null
                                          ? const Icon(Icons.local_shipping_rounded, color: AppTheme.deepLeafGreen)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            partnerName,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                          ),
                                          const Text(
                                            'Assigned Delivery Courier',
                                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (reviewed)
                                      Row(
                                        children: List.generate(5, (star) => Icon(
                                          Icons.star_rounded,
                                          color: star < (rating ?? 0) ? AppTheme.accentGold : Colors.grey[300],
                                          size: 14,
                                        )),
                                      )
                                    else
                                      TextButton.icon(
                                        onPressed: () => _openReviewDialog(partnerId, partnerName, 'Delivery Partner'),
                                        icon: const Icon(Icons.star_outline_rounded, size: 14, color: AppTheme.deepLeafGreen),
                                        label: const Text('Rate Partner', style: TextStyle(fontSize: 11, color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          backgroundColor: AppTheme.lightMint,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: Color(0xFFF1F1F1)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
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
                                        icon: const Icon(Icons.person_outline_rounded, size: 16),
                                        label: const Text('View Profile', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.deepLeafGreen,
                                          side: const BorderSide(color: AppTheme.deepLeafGreen),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                otherUserId: partnerId,
                                                otherUserName: partnerName,
                                                otherUserProfilePicture: partner['profile_picture_path'],
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                                        label: const Text('Chat with Rider', style: TextStyle(fontSize: 12, color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.deepLeafGreen,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
