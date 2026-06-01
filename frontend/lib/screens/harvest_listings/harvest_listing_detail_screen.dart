import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/harvest_listings/harvest_listing_form.dart';
import 'package:aswenna/screens/chat/chat_screen.dart';

class HarvestListingDetailScreen extends StatefulWidget {
  final int listingId;
  final String role; // 'farmer' or 'buyer'

  const HarvestListingDetailScreen({
    super.key,
    required this.listingId,
    required this.role,
  });

  @override
  State<HarvestListingDetailScreen> createState() => _HarvestListingDetailScreenState();
}

class _HarvestListingDetailScreenState extends State<HarvestListingDetailScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _listing = {};
  List<Map<String, dynamic>> _bids = [];

  // Bidding Form State (Buyer facing)
  bool _isPlacingBid = false;
  bool _isConfirmingBid = false;
  final _bidAmountController = TextEditingController();
  final _bidQtyController = TextEditingController();
  final _bidNotesController = TextEditingController();
  final _bidFormKey = GlobalKey<FormState>();

  GoogleMapController? _mapController;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _loadListingDetails();
  }

  @override
  void dispose() {
    _bidAmountController.dispose();
    _bidQtyController.dispose();
    _bidNotesController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadListingDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final result = await ApiService.getSingleHarvestListing(widget.listingId);
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _listing = Map<String, dynamic>.from(result['listing'] ?? {});
            
            final rawBids = result['bids'];
            List<Map<String, dynamic>> parsedBids = [];
            if (rawBids is List) {
              for (final e in rawBids) {
                if (e is Map) {
                  parsedBids.add(Map<String, dynamic>.from(e));
                }
              }
            } else if (rawBids is Map) {
              for (final e in rawBids.values) {
                if (e is Map) {
                  parsedBids.add(Map<String, dynamic>.from(e));
                }
              }
            }
            _bids = parsedBids;
            _isLoading = false;

            // If buyer has already placed a bid, pre-fill inputs
            final ownBid = _bids.firstWhere(
              (b) => b['is_own_bid'] == 1 || b['is_own_bid'] == true || b['is_own_bid']?.toString() == '1' || b['is_own_bid']?.toString() == 'true',
              orElse: () => <String, dynamic>{},
            );
            if (ownBid.isNotEmpty) {
              _bidAmountController.text = (ownBid['bid_amount_per_unit'] ?? '').toString();
              _bidQtyController.text = (ownBid['bid_quantity_unit'] ?? '').toString();
            } else {
              _bidQtyController.text = (_listing['minimum_order_quantity'] ?? '').toString();
            }
          });
        } else {
          setState(() {
            _error = result['message'] ?? 'Failed to load details.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading listing: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitBid() async {
    if (!_bidFormKey.currentState!.validate()) return;
    setState(() => _isPlacingBid = true);
    final data = {
      'bid_amount_per_unit': _bidAmountController.text.trim(),
      'bid_quantity_unit': _bidQtyController.text.trim(),
      'notes': _bidNotesController.text.trim(),
    };
    final result = await ApiService.placeHarvestBid(widget.listingId, data);
    if (!mounted) return;
    setState(() => _isPlacingBid = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Bid placed successfully!'),
          backgroundColor: AppTheme.deepLeafGreen,
        ),
      );
      _bidNotesController.clear();
      _loadListingDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to place bid.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAcceptBid(int bidId, String buyerName, double amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Accept Bid?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Accept the bid of LKR ${amount.toStringAsFixed(2)} per unit from $buyerName?\n\nThis will decline all other pending bids.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLeafGreen),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    final result = await ApiService.acceptHarvestBid(bidId);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bid accepted! Listing is now marked sold out.'),
          backgroundColor: AppTheme.deepLeafGreen,
        ),
      );
      _loadListingDetails();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to accept bid.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRejectBid(int bidId, String buyerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Bid?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to reject this bid from $buyerName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    final result = await ApiService.rejectHarvestBid(bidId);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bid rejected successfully.')),
      );
      _loadListingDetails();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to reject bid.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleConfirmBid(int bidId, int buyerId, String buyerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Deal?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Confirm the deal with $buyerName? This will create a confirmed order and notify the buyer to proceed with payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            child: const Text('Confirm Deal', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isConfirmingBid = true);
    final result = await ApiService.confirmBid(bidId);
    if (!mounted) return;
    setState(() => _isConfirmingBid = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deal confirmed! You can now chat with the buyer.'),
          backgroundColor: AppTheme.deepLeafGreen,
        ),
      );
      _loadListingDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to confirm bid.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openChat(int otherUserId, String otherUserName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final isFarmer = widget.role == 'farmer';

      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F4),
        appBar: AppBar(
          title: const Text('Harvest Listing'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context, true),
          ),
          actions: [
            if (isFarmer && !_isLoading && _listing.isNotEmpty && _listing['status'] == 'active')
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppTheme.deepLeafGreen, size: 28),
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HarvestListingForm(existingListing: _listing),
                    ),
                  );
                  if (updated == true) _loadListingDetails();
                },
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
            : _error.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadListingDetails,
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLeafGreen),
                            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhotoGallery(),
                        const SizedBox(height: 20),
                        _buildHeaderCard(),
                        const SizedBox(height: 20),
                        _buildSpecsCard(),
                        const SizedBox(height: 20),
                        _buildLocationMapCard(),
                        const SizedBox(height: 24),
                        
                        if (isFarmer) ...[
                          _buildFarmerBidsPanel(),
                          const SizedBox(height: 80),
                        ] else ...[
                          if (_listing['status'] == 'active') ...[
                            _buildBuyerBiddingPanel(),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_rounded, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'This listing is currently ${_listing['status'] ?? 'inactive'} and closed for bidding.',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 80),
                        ],
                        
                      ],
                    ),
                  ),
      );
    } catch (e, stack) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F4),
        appBar: AppBar(
          title: const Text('Harvest Listing Detail Error'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rendering Diagnostic Panel',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'A layout or runtime exception was caught during rendering:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.15)),
                  ),
                  child: Text(
                    '$e',
                    style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Stack Trace:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '$stack',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ─── Photo Gallery ───────────────────────────────────────────────────────────

  Widget _buildPhotoGallery() {
    final List<String> images = [];
    for (int i = 1; i <= 4; i++) {
      final img = _listing['image_$i'];
      if (img != null && img.toString().isNotEmpty) {
        images.add(img.toString());
      }
    }

    if (images.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.lightMint, AppTheme.deepLeafGreen.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.deepLeafGreen.withOpacity(0.1)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_florist_rounded, size: 48, color: AppTheme.deepLeafGreen),
            SizedBox(height: 12),
            Text('No Harvest Photos Uploaded',
                style: TextStyle(color: AppTheme.darkGreen, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final imageUrl = ApiService.fileUrl(images[index]);
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 240,
              height: 180,
              child: Image.network(
                imageUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Header Card ─────────────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    final status = _listing['status']?.toString().toUpperCase() ?? 'ACTIVE';
    final statusColor = status == 'SOLD_OUT'
        ? Colors.grey
        : (status == 'ACTIVE' ? AppTheme.deepLeafGreen : AppTheme.accentGold);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppTheme.accentGold, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Grade ${_listing['grade'] ?? 'A'}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _listing['cropname'] ?? 'Harvest Crop',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Published by: ${_listing['farmer_name'] ?? 'Aswenna Farmer'}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PRICE PER UNIT',
                      style: TextStyle(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'LKR ${double.tryParse(_listing['price_per_unit'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.deepLeafGreen),
                  ),
                ],
              ),
              if (_listing['min_bid_price_per_unit'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('MIN BID RATE',
                        style: TextStyle(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'LKR ${double.tryParse(_listing['min_bid_price_per_unit'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.accentGold),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Specs Card ──────────────────────────────────────────────────────────────

  Widget _buildSpecsCard() {
    final harvestDate = _listing['harvest_date'] != null
        ? DateTime.tryParse(_listing['harvest_date'].toString())
        : null;
    final harvestDateStr = harvestDate != null
        ? '${harvestDate.year}-${harvestDate.month.toString().padLeft(2, '0')}-${harvestDate.day.toString().padLeft(2, '0')}'
        : 'Not specified';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Harvest Specifications',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildSpecRow(Icons.scale_rounded, 'Available Quantity',
              '${_listing['available_quantity']} ${_listing['unit']}'),
          _buildSpecRow(Icons.shopping_basket_rounded, 'Min Order Qty',
              '${_listing['minimum_order_quantity']} ${_listing['unit']}'),
          _buildSpecRow(Icons.local_shipping_rounded, 'Max Order Qty',
              '${_listing['maximum_order_quantity']} ${_listing['unit']}'),
          _buildSpecRow(Icons.calendar_today_rounded, 'Harvest Date', harvestDateStr),
          _buildSpecRow(Icons.health_and_safety_rounded, 'Crop Condition', '${_listing['harvest_condition']}'),
          _buildSpecRow(Icons.warehouse_rounded, 'Storage Method',
              '${_listing['storage_method'] ?? 'Standard Room Storage'}'),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Delivery Available',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            value: _listing['delivery_available'] == 1 || _listing['delivery_available'] == true,
            onChanged: null,
            activeColor: AppTheme.deepLeafGreen,
          ),
          if (_listing['delivery_available'] == 1 || _listing['delivery_available'] == true) ...[
            _buildSpecRow(Icons.monetization_on_rounded, 'Delivery Fee',
                'LKR ${_listing['delivery_fee_per_km']} per KM'),
            _buildSpecRow(Icons.explore_rounded, 'Max Delivery Dist.', '${_listing['max_delivery_distance']} KM'),
          ],
          if (_listing['notes'] != null && _listing['notes'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            const Text('Notes / Description',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Text(
              _listing['notes'],
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.deepLeafGreen),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // ─── Location Map Card ────────────────────────────────────────────────────────

  Widget _buildLocationMapCard() {
    final double? lat = _listing['pickup_latitude'] != null
        ? double.tryParse(_listing['pickup_latitude'].toString())
        : null;
    final double? lng = _listing['pickup_longitude'] != null
        ? double.tryParse(_listing['pickup_longitude'].toString())
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.deepLeafGreen, size: 18),
              const SizedBox(width: 8),
              const Text('Pickup Collection Site',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          if (lat == null || lng == null)
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FFF8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.deepLeafGreen.withOpacity(0.1)),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_rounded, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 8),
                  Text('No pickup location pinned.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            )
          else
            /*
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_rounded, color: AppTheme.deepLeafGreen, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Pickup Site Location Map',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Coordinates: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepLeafGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Interactive Map Bypassed for Testing',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            */
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 180,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(lat, lng),
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('pickup'),
                      position: LatLng(lat, lng),
                      infoWindow: const InfoWindow(title: 'Pickup Location'),
                    ),
                  },
                  onMapCreated: (c) => _mapController = c,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Farmer Bids Panel ────────────────────────────────────────────────────────

  Widget _buildFarmerBidsPanel() {
    try {
      final pendingBids = _bids.where((b) => b['status'] == 'pending').toList();
      final acceptedBids = _bids.where((b) => b['status'] == 'accepted').toList();
      final otherBids = _bids.where((b) => b['status'] != 'pending' && b['status'] != 'accepted').toList();
      final orderedBids = [...acceptedBids, ...pendingBids, ...otherBids];

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Incoming Bids',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration:
                      BoxDecoration(color: AppTheme.lightMint, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '${_bids.length} BIDS',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_bids.isEmpty)
              Container(
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FFF8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_rounded, color: Colors.grey[300], size: 28),
                    const SizedBox(height: 6),
                    Text('No bids received yet.', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              )
            else
              Column(
                children: orderedBids.map((bid) => _buildBidCard(bid)).toList(),
              ),
          ],
        ),
      );
    } catch (e, stack) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red),
        ),
        child: Text(
          'Error rendering Farmer Bids Panel: $e\n$stack',
          style: const TextStyle(color: Colors.red, fontSize: 11, fontFamily: 'monospace'),
        ),
      );
    }
  }

  Widget _buildBidCard(Map<String, dynamic> bid) {
    final status = bid['status']?.toString() ?? 'pending';
    final buyerName = bid['buyer_name'] ?? 'Buyer';
    final buyerId = int.tryParse(bid['buyer_id']?.toString() ?? '') ?? 0;
    final bidAmount = double.tryParse(bid['bid_amount_per_unit']?.toString() ?? '') ?? 0;
    final confirmedBidId = int.tryParse(bid['confirmed_bid_id']?.toString() ?? '');
    final bidId = int.tryParse(bid['id']?.toString() ?? '') ?? 0;
    final qty = bid['bid_quantity_unit']?.toString() ?? '0';
    final total = (bidAmount * (double.tryParse(qty) ?? 0)).toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.lightMint,
                child: Icon(Icons.person, color: AppTheme.deepLeafGreen),
              ),
              title: Text(buyerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Status: ${status.toUpperCase()}\nQty: $qty ${_listing['unit'] ?? ''}', style: const TextStyle(fontSize: 12)),
              trailing: Text('LKR $total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1565C0))),
            ),
            if (bid['notes'] != null && bid['notes'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: "${bid['notes']}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openChat(buyerId, buyerName),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                  label: const Text('Chat', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.deepLeafGreen,
                    side: const BorderSide(color: AppTheme.deepLeafGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                if (status == 'pending') ...[
                  TextButton(
                    onPressed: () => _handleRejectBid(bidId, buyerName),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleAcceptBid(bidId, buyerName, bidAmount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepLeafGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ] else if (status == 'accepted') ...[
                  if (confirmedBidId == null)
                    ElevatedButton.icon(
                      onPressed: () => _handleConfirmBid(bidId, buyerId, buyerName),
                      icon: const Icon(Icons.handshake_rounded, size: 14, color: Colors.white),
                      label: const Text('Confirm Deal', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1565C0)),
                          SizedBox(width: 4),
                          Text('Deal Confirmed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Buyer Bidding Panel ─────────────────────────────────────────────────────

  Widget _buildBuyerBiddingPanel() {
    try {
      final ownBid = _bids.firstWhere(
        (b) => b['is_own_bid'] == 1 || b['is_own_bid'] == true,
        orElse: () => <String, dynamic>{},
      );
      final hasOwnBid = ownBid.isNotEmpty;
      final competitorBids = _bids.where((b) => b['is_own_bid'] != 1 && b['is_own_bid'] != true).toList();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasOwnBid ? 'Manage Your Bid' : 'Place Your Bidding Offer',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            if (hasOwnBid) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightMint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.deepLeafGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppTheme.deepLeafGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your bid: LKR ${double.tryParse(ownBid['bid_amount_per_unit']?.toString() ?? '')?.toStringAsFixed(2)}/unit for ${ownBid['bid_quantity_unit']} ${_listing['unit']}. Status: ${ownBid['status']?.toUpperCase()}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.darkGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (competitorBids.isNotEmpty) ...[
              Text('Competitor Bid Rates',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: competitorBids.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration:
                        BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'LKR ${double.tryParse(competitorBids[idx]['bid_amount_per_unit']?.toString() ?? '')?.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Form(
              key: _bidFormKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bidAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Your Bid Rate (LKR) *',
                            labelStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            final val = double.tryParse(v);
                            if (val == null || val <= 0) return 'Invalid price';
                            if (_listing['min_bid_price_per_unit'] != null) {
                              final min = double.tryParse(_listing['min_bid_price_per_unit'].toString()) ?? 0;
                              if (val < min) return 'Min LKR ${min.toStringAsFixed(2)}';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _bidQtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Bid Quantity *',
                            labelStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            prefixIcon: const Icon(Icons.scale_rounded, size: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            final val = double.tryParse(v);
                            if (val == null || val <= 0) return 'Invalid qty';
                            final min = double.tryParse(_listing['minimum_order_quantity'].toString()) ?? 0;
                            final max = double.tryParse(_listing['maximum_order_quantity'].toString()) ?? 0;
                            final avail = double.tryParse(_listing['available_quantity'].toString()) ?? 0;
                            if (val < min) return 'Min $min ${_listing['unit']}';
                            if (val > max) return 'Max $max ${_listing['unit']}';
                            if (val > avail) return 'Max available $avail';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bidNotesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Special requests or notes (Optional)',
                      labelStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isPlacingBid
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _submitBid,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.deepLeafGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              hasOwnBid ? 'Update Bid Offer' : 'Submit Bid Offer',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red),
        ),
        child: Text(
          'Error rendering Buyer Bidding Panel: $e\n$stack',
          style: const TextStyle(color: Colors.red, fontSize: 11, fontFamily: 'monospace'),
        ),
      );
    }
  }
}
