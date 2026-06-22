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
  List<dynamic> _allBiddingListings = [];
  List<dynamic> _filteredBiddingListings = [];
  bool _isLoading = true;
  String? _errorMessage;

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
  
  // Basic list of Sri Lankan agricultural districts for filtering
  final List<String> _districts = [
    'Anuradhapura', 'Badulla', 'Colombo', 'Galle', 'Gampaha', 
    'Hambantota', 'Jaffna', 'Kandy', 'Kurunegala', 'Matale', 
    'Nuwara Eliya', 'Polonnaruwa', 'Ratnapura'
  ];

  @override
  void initState() {
    super.initState();
    _loadBiddingOpportunities();
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
          // Filter only those with bidding enabled (min_bid_price_per_unit is not null)
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

  void _applyFiltersAndSort() {
    List<dynamic> temp = List.from(_allBiddingListings);

    // Search Query (crop name or farmer name)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      temp = temp.where((item) {
        final crop = (item['cropname'] ?? '').toString().toLowerCase();
        final farmer = (item['farmer_name'] ?? '').toString().toLowerCase();
        return crop.contains(q) || farmer.contains(q);
      }).toList();
    }

    // Grade Filter
    if (_selectedGrade != null) {
      temp = temp.where((item) => item['grade']?.toString().toUpperCase() == _selectedGrade).toList();
    }

    // District Filter
    if (_selectedDistrict != null) {
      temp = temp.where((item) {
        final dist = item['district']?.toString().toLowerCase() ?? '';
        return dist.contains(_selectedDistrict!.toLowerCase());
      }).toList();
    }

    // Price Range Filter
    if (_minPrice != null) {
      temp = temp.where((item) {
        final price = double.tryParse(item['min_bid_price_per_unit']?.toString() ?? '0') ?? 0.0;
        return price >= _minPrice!;
      }).toList();
    }
    if (_maxPrice != null) {
      temp = temp.where((item) {
        final price = double.tryParse(item['min_bid_price_per_unit']?.toString() ?? '0') ?? 0.0;
        return price <= _maxPrice!;
      }).toList();
    }

    // Sorting
    if (_sortBy == 'recent') {
      // Assuming higher ID means newer, or keep default
      temp.sort((a, b) {
        final idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
        final idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
        return idB.compareTo(idA); // Descending order
      });
    } else if (_sortBy == 'price_asc') {
      temp.sort((a, b) {
        final prA = double.tryParse(a['min_bid_price_per_unit']?.toString() ?? '0') ?? 0.0;
        final prB = double.tryParse(b['min_bid_price_per_unit']?.toString() ?? '0') ?? 0.0;
        return prA.compareTo(prB);
      });
    } else if (_sortBy == 'price_desc') {
      temp.sort((a, b) {
        final prA = double.tryParse(a['min_bid_price_per_unit']?.toString() ?? '0') ?? 0.0;
        final prB = double.tryParse(b['min_bid_price_per_unit']?.toString() ?? '0') ?? 0.0;
        return prB.compareTo(prA);
      });
    } else if (_sortBy == 'qty_desc') {
      temp.sort((a, b) {
        final qtyA = double.tryParse(a['available_quantity']?.toString() ?? '0') ?? 0.0;
        final qtyB = double.tryParse(b['available_quantity']?.toString() ?? '0') ?? 0.0;
        return qtyB.compareTo(qtyA);
      });
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
                    
                    // Grade selection
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
                    const SizedBox(height: 20),

                    // District selector
                    const Text('Farmer District', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDistrict,
                          hint: const Text('Select a District'),
                          isExpanded: true,
                          items: _districts.map((dist) {
                            return DropdownMenuItem(value: dist, child: Text(dist));
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              _selectedDistrict = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Price range inputs
                    const Text('Min Bid Price Range (LKR / kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Min Price',
                              prefixText: 'LKR ',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            controller: TextEditingController(text: _minPrice?.toString() ?? ''),
                            onChanged: (val) {
                              _minPrice = double.tryParse(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Max Price',
                              prefixText: 'LKR ',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            controller: TextEditingController(text: _maxPrice?.toString() ?? ''),
                            onChanged: (val) {
                              _maxPrice = double.tryParse(val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFiltersAndSort();
                          Navigator.pop(context);
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
                
                // Sorting row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${_filteredBiddingListings.length} auctions',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.sort_rounded, size: 14, color: AppTheme.deepLeafGreen),
                        const SizedBox(width: 6),
                        DropdownButton<String>(
                          value: _sortBy,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.deepLeafGreen),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen, fontSize: 12),
                          items: const [
                            DropdownMenuItem(value: 'recent', child: Text('Recently Added')),
                            DropdownMenuItem(value: 'price_asc', child: Text('Min Bid: Low to High')),
                            DropdownMenuItem(value: 'price_desc', child: Text('Min Bid: High to Low')),
                            DropdownMenuItem(value: 'qty_desc', child: Text('Quantity: High to Low')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _sortBy = val;
                              });
                              _applyFiltersAndSort();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Listings Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
                : _errorMessage != null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ))
                    : _filteredBiddingListings.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _loadBiddingOpportunities,
                            color: AppTheme.deepLeafGreen,
                            child: ListView(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.gavel_rounded, size: 64, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      const Text('No Bidding Items Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      const Text('Try modifying your search queries or filter settings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBiddingOpportunities,
                            color: AppTheme.deepLeafGreen,
                            child: ListView.separated(
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
                                        // Product Thumbnail
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
                                        
                                        // Card Details
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
        ],
      ),
    );
  }
}
