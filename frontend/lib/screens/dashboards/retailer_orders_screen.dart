import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/dashboards/order_review_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
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
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, color: AppTheme.deepLeafGreen.withOpacity(0.4), size: 100),
                          const SizedBox(height: 16),
                          const Text(
                            'No sales orders found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          const Text('Your shop orders will appear here!', style: TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      color: AppTheme.deepLeafGreen,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
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
                    const Icon(Icons.person_rounded, color: AppTheme.deepLeafGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Customer: ${order['customer']?['full_name'] ?? 'Buyer'}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
              Text(
                'Customer: ${widget.order['customer']?['full_name'] ?? 'Buyer'} · Phone: ${widget.order['customer']?['phone_number'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Builder(
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
                                  const Text('Delivery Courier Partner', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
