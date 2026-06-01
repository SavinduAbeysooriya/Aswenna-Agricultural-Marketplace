import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/harvest_listings/harvest_listing_form.dart';

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
  final _bidAmountController = TextEditingController();
  final _bidQtyController = TextEditingController();
  final _bidNotesController = TextEditingController();
  final _bidFormKey = GlobalKey<FormState>();

  GoogleMapController? _mapController;

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
            _bids = List<Map<String, dynamic>>.from(
              (result['bids'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
            );
            _isLoading = false;

            // If buyer has already placed a bid, pre-fill inputs
            final ownBid = _bids.firstWhere((b) => b['is_own_bid'] == 1 || b['is_own_bid'] == true, orElse: () => {});
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
        SnackBar(content: Text(result['message'] ?? 'Bid placed successfully!')),
      );
      _bidNotesController.clear();
      _loadListingDetails(); // Refresh listing details and bids list
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
        title: const Text('Accept Bid?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to accept the bid of LKR ${amount.toStringAsFixed(2)} per unit from $buyerName? This will decline all other bids and mark this harvest listing as successfully sold.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLeafGreen),
            child: const Text('Accept Bid', style: TextStyle(color: Colors.white)),
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
        const SnackBar(content: Text('Bid accepted successfully! Listing is now marked sold out.')),
      );
      _loadListingDetails();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to accept bid.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleRejectBid(int bidId, String buyerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
        SnackBar(content: Text(result['message'] ?? 'Failed to reject bid.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFarmer = widget.role == 'farmer';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text('Harvest Listing Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context, true), // Returns true to trigger parent updates
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
                if (updated == true) {
                  _loadListingDetails();
                }
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
                      // Photo slider gallery
                      _buildPhotoGallery(),
                      const SizedBox(height: 20),

                      // Core description header card
                      _buildHeaderCard(),
                      const SizedBox(height: 20),

                      // Listing specifications
                      _buildSpecsCard(),
                      const SizedBox(height: 20),

                      // Location Map Card
                      _buildLocationMapCard(),
                      const SizedBox(height: 24),

                      // Farmer Bids Panel (Incoming bids)
                      if (isFarmer) ...[
                        _buildFarmerBidsPanel(),
                      ] else ...[
                        // Buyer Bidding Placement Panel
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
                      ],
                    ],
                  ),
                ),
    );
  }

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
          color: AppTheme.lightMint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.deepLeafGreen.withOpacity(0.1)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_florist_rounded, size: 48, color: AppTheme.deepLeafGreen),
            SizedBox(height: 12),
            Text('No Harvest Photos Uploaded', style: TextStyle(color: AppTheme.darkGreen, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
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
            child: Container(
              width: 240,
              height: 180,
              color: Colors.white,
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
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Published by Farmer: ${_listing['farmer_name'] ?? 'Aswenna Farmer'}',
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
                  Text('PRICE PER UNIT', style: TextStyle(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.bold)),
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
                    Text('MIN BID STARTING RATE', style: TextStyle(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.bold)),
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

  Widget _buildSpecsCard() {
    final harvestDate = _listing['harvest_date'] != null ? DateTime.tryParse(_listing['harvest_date'].toString()) : null;
    final harvestDateStr = harvestDate != null ? "${harvestDate.year}-${harvestDate.month.toString().padLeft(2, '0')}-${harvestDate.day.toString().padLeft(2, '0')}" : 'Not specified';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Harvest Specifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildSpecRow(Icons.scale_rounded, 'Available Quantity', '${_listing['available_quantity']} ${_listing['unit']}'),
          _buildSpecRow(Icons.shopping_basket_rounded, 'Min Order Qty', '${_listing['minimum_order_quantity']} ${_listing['unit']}'),
          _buildSpecRow(Icons.local_shipping_rounded, 'Max Order Qty', '${_listing['maximum_order_quantity']} ${_listing['unit']}'),
          _buildSpecRow(Icons.calendar_today_rounded, 'Harvest Date', harvestDateStr),
          _buildSpecRow(Icons.health_and_safety_rounded, 'Crop Condition', '${_listing['harvest_condition']}'),
          _buildSpecRow(Icons.warehouse_rounded, 'Storage Method', '${_listing['storage_method'] ?? 'Standard Room storage'}'),
          
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Logistics / Delivery Available', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            value: _listing['delivery_available'] == 1 || _listing['delivery_available'] == true,
            onChanged: null,
            activeColor: AppTheme.deepLeafGreen,
          ),
          if (_listing['delivery_available'] == 1 || _listing['delivery_available'] == true) ...[
            const SizedBox(height: 4),
            _buildSpecRow(Icons.monetization_on_rounded, 'Delivery Fee', 'LKR ${_listing['delivery_fee_per_km']} per KM'),
            _buildSpecRow(Icons.explore_rounded, 'Max Delivery Dist.', '${_listing['max_delivery_distance']} KM'),
          ],

          if (_listing['notes'] != null && _listing['notes'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            const Text('Notes / Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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

  Widget _buildLocationMapCard() {
    final double? lat = _listing['pickup_latitude'] != null ? double.tryParse(_listing['pickup_latitude'].toString()) : null;
    final double? lng = _listing['pickup_longitude'] != null ? double.tryParse(_listing['pickup_longitude'].toString()) : null;

    if (lat == null || lng == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: const Center(
          child: Text('No pickup location pinned.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    final LatLng pickupPos = LatLng(lat, lng);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pickup Collection Site', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[100]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: pickupPos, zoom: 14),
                markers: {
                  Marker(
                    markerId: const MarkerId('pickup'),
                    position: pickupPos,
                    infoWindow: const InfoWindow(title: 'Pickup Location'),
                  ),
                },
                onMapCreated: (c) {
                  _mapController = c;
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerBidsPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Received Harvest Bids', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.lightMint, borderRadius: BorderRadius.circular(8)),
                child: Text('${_bids.length} BIDS', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_bids.isEmpty)
            Container(
              height: 80,
              alignment: Alignment.center,
              child: Text(
                'No bids received yet.',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bid = _bids[index];
                final status = bid['status']?.toString().toUpperCase() ?? 'PENDING';
                final statusColor = status == 'ACCEPTED'
                    ? AppTheme.deepLeafGreen
                    : (status == 'REJECTED' ? Colors.red : AppTheme.accentGold);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bid['buyer_name'] ?? 'Buyer User',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              if (bid['buyer_phone'] != null)
                                Text(
                                  bid['buyer_phone'],
                                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BID RATE / UNIT', style: TextStyle(fontSize: 8, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                'LKR ${double.tryParse(bid['bid_amount_per_unit'].toString())?.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('BID QUANTITY', style: TextStyle(fontSize: 8, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                '${bid['bid_quantity_unit']} ${_listing['unit']}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (bid['notes'] != null && bid['notes'].toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Notes: ${bid['notes']}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                      ],
                      if (status == 'PENDING') ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _handleRejectBid(bid['id'], bid['buyer_name'] ?? 'Buyer',),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => _handleAcceptBid(
                                bid['id'],
                                bid['buyer_name'] ?? 'Buyer',
                                double.tryParse(bid['bid_amount_per_unit'].toString()) ?? 0,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.deepLeafGreen,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Accept Bid', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBuyerBiddingPanel() {
    final ownBid = _bids.firstWhere((b) => b['is_own_bid'] == 1 || b['is_own_bid'] == true, orElse: () => {});
    final hasOwnBid = ownBid.isNotEmpty;

    // Filter competitor bid values anonymously
    final competitorBids = _bids.where((b) => b['is_own_bid'] != 1 && b['is_own_bid'] != true).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                      'You placed a bid: LKR ${double.tryParse(ownBid['bid_amount_per_unit'].toString())?.toStringAsFixed(2)}/unit for ${ownBid['bid_quantity_unit']} ${_listing['unit']}. Status: ${ownBid['status']?.toUpperCase()}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.darkGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Competitors feed
          if (competitorBids.isNotEmpty) ...[
            Text(
              'Competitor Bid Rates',
              style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: competitorBids.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LKR ${double.tryParse(competitorBids[idx]['bid_amount_per_unit'].toString())?.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                  );
                },
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
                            if (val < min) return 'Must be >= LKR ${min.toStringAsFixed(2)}';
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
                    : Container(
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
