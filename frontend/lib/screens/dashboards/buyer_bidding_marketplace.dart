import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/harvest_listings/harvest_listing_detail_screen.dart';

class BuyerBiddingMarketplace extends StatefulWidget {
  const BuyerBiddingMarketplace({super.key});

  @override
  State<BuyerBiddingMarketplace> createState() => _BuyerBiddingMarketplaceState();
}

class _BuyerBiddingMarketplaceState extends State<BuyerBiddingMarketplace> {
  int _activeMarketTab = 0; // 0: Bidding Opportunities, 1: Digital Contracts & Negotiation

  List<dynamic> _allBiddingListings = [];
  List<dynamic> _filteredBiddingListings = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Digital Contracts State (BUY-004)
  List<dynamic> _digitalContracts = [];
  bool _isLoadingContracts = false;

  // Search and Filter States
  String _searchQuery = '';
  final _searchController = TextEditingController();
  
  String? _selectedGrade;
  String? _selectedDistrict;
  double? _minPrice;
  double? _maxPrice;
  
  // Sort State: 'recent', 'price_asc', 'price_desc', 'qty_desc'
  String _sortBy = 'recent';

  final List<String> _grades = ['A', 'B', 'C'];
  
  final List<String> _districts = [
    'Anuradhapura', 'Badulla', 'Colombo', 'Galle', 'Gampaha', 
    'Hambantota', 'Jaffna', 'Kandy', 'Kurunegala', 'Matale', 
    'Nuwara Eliya', 'Polonnaruwa', 'Ratnapura'
  ];

  @override
  void initState() {
    super.initState();
    _loadBiddingOpportunities();
    _loadDigitalContracts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBiddingOpportunities() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getBuyerHarvestListings();
      if (mounted) {
        if (result['success'] == true) {
          final list = List<dynamic>.from(result['listings'] ?? []);
          _allBiddingListings = list.where((l) => l is Map && l['min_bid_price_per_unit'] != null).toList();
          _applyFiltersAndSort();
        } else {
          _errorMessage = result['message'] ?? 'Failed to load bidding opportunities.';
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  Future<void> _loadDigitalContracts() async {
    setState(() => _isLoadingContracts = true);
    try {
      final res = await ApiService.getDigitalContracts();
      if (mounted) {
        if (res['success'] == true) {
          _digitalContracts = List<dynamic>.from(res['contracts'] ?? []);
        }
        setState(() => _isLoadingContracts = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingContracts = false);
      }
    }
  }

  Future<void> _acceptCounterOffer(int contractId, String offerCode, double escrowAmount, double rate) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Accept Offer #$offerCode', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightMint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.deepLeafGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Negotiated Rate:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Text('LKR ${rate.toStringAsFixed(2)} / kg', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('20% Escrow Down Payment:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Text('LKR ${escrowAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('By accepting this counter-offer, contract_signed status will be triggered, and 20% down payment reserved in escrow with delivery partner assignment.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepLeafGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing contract acceptance & escrow deposit...')),
                    );
                    final res = await ApiService.acceptCounterOffer(contractId);
                    if (mounted) {
                      if (res['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Offer status updated to contract_signed! Escrow hold reserved.'),
                            backgroundColor: AppTheme.deepLeafGreen,
                          ),
                        );
                        _loadDigitalContracts();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? 'Failed to accept offer.')),
                        );
                      }
                    }
                  },
                  child: Text('Accept Counter-Offer LKR ${rate.toStringAsFixed(0)}/kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyFiltersAndSort() {
    List<dynamic> temp = List.from(_allBiddingListings);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      temp = temp.where((item) {
        final crop = (item['cropname'] ?? '').toString().toLowerCase();
        final farmer = (item['farmer_name'] ?? '').toString().toLowerCase();
        return crop.contains(q) || farmer.contains(q);
      }).toList();
    }

    if (_selectedGrade != null) {
      temp = temp.where((item) => item['grade']?.toString().toUpperCase() == _selectedGrade).toList();
    }

    if (_selectedDistrict != null) {
      temp = temp.where((item) => item['farmer_district']?.toString() == _selectedDistrict).toList();
    }

    if (_minPrice != null) {
      temp = temp.where((item) {
        final price = double.tryParse(item['min_bid_price_per_unit']?.toString() ?? '0') ?? 0;
        return price >= _minPrice!;
      }).toList();
    }

    if (_maxPrice != null) {
      temp = temp.where((item) {
        final price = double.tryParse(item['min_bid_price_per_unit']?.toString() ?? '0') ?? 0;
        return price <= _maxPrice!;
      }).toList();
    }

    if (_sortBy == 'price_asc') {
      temp.sort((a, b) {
        final pa = double.tryParse(a['min_bid_price_per_unit']?.toString() ?? '0') ?? 0;
        final pb = double.tryParse(b['min_bid_price_per_unit']?.toString() ?? '0') ?? 0;
        return pa.compareTo(pb);
      });
    } else if (_sortBy == 'price_desc') {
      temp.sort((a, b) {
        final pa = double.tryParse(a['min_bid_price_per_unit']?.toString() ?? '0') ?? 0;
        final pb = double.tryParse(b['min_bid_price_per_unit']?.toString() ?? '0') ?? 0;
        return pb.compareTo(pa);
      });
    } else if (_sortBy == 'qty_desc') {
      temp.sort((a, b) {
        final qa = double.tryParse(a['available_quantity']?.toString() ?? '0') ?? 0;
        final qb = double.tryParse(b['available_quantity']?.toString() ?? '0') ?? 0;
        return qb.compareTo(qa);
      });
    } else {
      temp.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
    }

    setState(() {
      _filteredBiddingListings = temp;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Advanced Filters',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedGrade = null;
                              _selectedDistrict = null;
                              _minPrice = null;
                              _maxPrice = null;
                            });
                          },
                          child: const Text('Reset All', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Produce Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: _grades.map((grade) {
                        final isSelected = _selectedGrade == grade;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text('Grade $grade'),
                            selected: isSelected,
                            selectedColor: AppTheme.deepLeafGreen.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.deepLeafGreen : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              setModalState(() {
                                _selectedGrade = val ? grade : null;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Farmer District', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: InputDecoration(
                        hintText: 'Select District',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (val) {
                        setModalState(() => _selectedDistrict = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFiltersAndSort();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deepLeafGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Column(
        children: [
          // Segmented Tab Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Bidding Opportunities')),
                    selected: _activeMarketTab == 0,
                    selectedColor: AppTheme.deepLeafGreen.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: _activeMarketTab == 0 ? AppTheme.deepLeafGreen : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _activeMarketTab = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Digital Contracts (#OFF-4412)')),
                    selected: _activeMarketTab == 1,
                    selectedColor: AppTheme.deepLeafGreen.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: _activeMarketTab == 1 ? AppTheme.deepLeafGreen : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() => _activeMarketTab = 1);
                      _loadDigitalContracts();
                    },
                  ),
                ),
              ],
            ),
          ),

          if (_activeMarketTab == 0) ...[
            // Search & Filter Panel
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                            _applyFiltersAndSort();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search crop or farmer...',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.deepLeafGreen),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                      _applyFiltersAndSort();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _showFilterBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.deepLeafGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppTheme.deepLeafGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${_filteredBiddingListings.length} auctions',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      DropdownButton<String>(
                        value: _sortBy,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                        items: const [
                          DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                          DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                          DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                          DropdownMenuItem(value: 'qty_desc', child: Text('Highest Quantity')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _sortBy = val);
                            _applyFiltersAndSort();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : RefreshIndicator(
                          onRefresh: _loadBiddingOpportunities,
                          child: _filteredBiddingListings.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 80),
                                    Center(child: Text('No bidding opportunities found.')),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredBiddingListings.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final item = _filteredBiddingListings[index];
                                    final id = int.tryParse(item['id']?.toString() ?? '') ?? 0;
                                    final title = item['cropname']?.toString() ?? 'Crop';
                                    final farmer = item['farmer_name']?.toString() ?? 'Farmer';
                                    final minBid = double.tryParse(item['min_bid_price_per_unit']?.toString() ?? '0') ?? 0.0;
                                    final qty = item['available_quantity']?.toString() ?? '0';
                                    final unit = item['unit']?.toString() ?? 'kg';
                                    final grade = item['grade']?.toString() ?? 'A';
                                    final imageUrl = item['crop_image'];
                                    
                                    Color gradeColor = AppTheme.deepLeafGreen;
                                    if (grade.toUpperCase() == 'B') gradeColor = const Color(0xFF0284C7);
                                    if (grade.toUpperCase() == 'C') gradeColor = AppTheme.accentGold;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.deepLeafGreen.withOpacity(0.03),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(24),
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => HarvestListingDetailScreen(listingId: id, role: 'buyer'),
                                            ),
                                          );
                                          _loadBiddingOpportunities();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 76,
                                                height: 76,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.lightMint,
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: imageUrl != null
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(16),
                                                        child: Image.network(
                                                          ApiService.fileUrl(imageUrl) ?? '',
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => const Icon(Icons.gavel_rounded, color: AppTheme.accentGold, size: 32),
                                                        ),
                                                      )
                                                    : const Icon(Icons.gavel_rounded, color: AppTheme.accentGold, size: 32),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          title,
                                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: gradeColor.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            'Grade $grade',
                                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: gradeColor),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Farmer: $farmer',
                                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Min Bid: LKR ${minBid.toStringAsFixed(0)}/$unit',
                                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.accentGold),
                                                        ),
                                                        Text(
                                                          'Qty: $qty $unit',
                                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),
          ] else ...[
            // Digital Contracts & Counter Offer View (BUY-004)
            Expanded(
              child: _isLoadingContracts
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadDigitalContracts,
                      child: _digitalContracts.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(child: Text('No digital contract offers found.')),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _digitalContracts.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final contract = _digitalContracts[index];
                                final contractId = int.tryParse(contract['id']?.toString() ?? '0') ?? 0;
                                final offerCode = contract['offer_code']?.toString() ?? 'OFF-4412';
                                final cropName = contract['crop_name']?.toString() ?? 'Green Chilli';
                                final farmerName = contract['farmer_name']?.toString() ?? 'Isuru Kawshalya';
                                final qty = double.tryParse(contract['quantity']?.toString() ?? '1000') ?? 1000.0;
                                final initialRate = double.tryParse(contract['initial_price_per_unit']?.toString() ?? '350') ?? 350.0;
                                final counterRate = double.tryParse(contract['counter_offer_price_per_unit']?.toString() ?? '315') ?? 315.0;
                                final totalVal = double.tryParse(contract['total_contract_value']?.toString() ?? '315000') ?? 315000.0;
                                final escrowPct = double.tryParse(contract['escrow_deposit_percent']?.toString() ?? '20') ?? 20.0;
                                final escrowAmt = double.tryParse(contract['escrow_deposit_amount']?.toString() ?? '63000') ?? 63000.0;
                                final status = contract['status']?.toString() ?? 'counter_offer_received';

                                final isSigned = status == 'contract_signed';

                                return Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: AppTheme.deepLeafGreen.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                                    ],
                                    border: Border.all(color: isSigned ? AppTheme.deepLeafGreen : AppTheme.accentGold.withOpacity(0.5), width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Offer ID: #$offerCode', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.darkGreen)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isSigned ? Colors.green.withOpacity(0.12) : AppTheme.accentGold.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isSigned ? 'contract_signed' : 'Counter-Offer Received',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isSigned ? AppTheme.deepLeafGreen : Colors.orange[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(color: AppTheme.lightMint, borderRadius: BorderRadius.circular(12)),
                                            child: const Icon(Icons.handshake_rounded, color: AppTheme.deepLeafGreen, size: 28),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('$cropName (${qty.toStringAsFixed(0)} kg)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                                Text('Supplier: $farmerName', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('Initial Ask:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                Text('LKR ${initialRate.toStringAsFixed(2)} / kg', style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('Counter-Offer Rate:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                Text('LKR ${counterRate.toStringAsFixed(2)} / kg', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.deepLeafGreen)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('Total Value:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                Text('LKR ${totalVal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Escrow Down Payment (${escrowPct.toStringAsFixed(0)}%):', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                Text('LKR ${escrowAmt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      if (isSigned) ...[
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          width: double.infinity,
                                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                                          child: const Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.check_circle_rounded, color: AppTheme.deepLeafGreen, size: 18),
                                                  SizedBox(width: 6),
                                                  Text('Contract Signed & Escrow Confirmed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen)),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Text('20% down payment (LKR 63,000) reserved in escrow. Delivery partner assignment triggered.', style: TextStyle(fontSize: 10, color: Colors.black87)),
                                            ],
                                          ),
                                        ),
                                      ] else ...[
                                        SizedBox(
                                          width: double.infinity,
                                          height: 44,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.deepLeafGreen,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                                            label: Text('Accept Counter-Offer LKR ${counterRate.toStringAsFixed(0)}/kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            onPressed: () => _acceptCounterOffer(contractId, offerCode, escrowAmt, counterRate),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
