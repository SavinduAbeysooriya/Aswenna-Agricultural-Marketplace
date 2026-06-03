import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/dashboards/customer_cart_screen.dart';
import 'package:aswenna/screens/dashboards/customer_profile_screen.dart';
import 'package:aswenna/screens/dashboards/customer_orders_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;
  List<dynamic> _products = [];
  List<dynamic> _crops = [];
  bool _isLoadingProducts = true;
  bool _isLoadingCrops = true;

  double? _latitude;
  double? _longitude;
  String? _cityName;

  // Search & Filter State
  final _searchController = TextEditingController();
  int? _selectedCropId;
  String? _selectedGrade;

  @override
  void initState() {
    super.initState();
    _loadLocationAndData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationAndData() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      // 1. Load user profile details for coordinates
      final profileRes = await ApiService.getBuyerProfile();
      if (profileRes['success'] == true && profileRes['profile'] != null) {
        final u = profileRes['profile']['user'];
        _latitude = u['latitude'] != null ? double.tryParse(u['latitude'].toString()) : null;
        _longitude = u['longitude'] != null ? double.tryParse(u['longitude'].toString()) : null;
        _cityName = u['city'] ?? u['district'];
      }
    } catch (e) {
      // ignore
    }

    // 2. Fetch products and approved crop categories
    _fetchProducts();
    _fetchCrops();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final response = await ApiService.getCustomerProducts(
        lat: _latitude,
        lng: _longitude,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        cropId: _selectedCropId,
        grade: _selectedGrade,
      );

      if (response['success'] == true && mounted) {
        setState(() {
          _products = response['products'] ?? [];
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  Future<void> _fetchCrops() async {
    setState(() => _isLoadingCrops = true);
    try {
      final response = await ApiService.getApprovedCrops();
      if (response['success'] == true && mounted) {
        setState(() {
          _crops = response['crops'] ?? [];
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _isLoadingCrops = false);
      }
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
    ).then((updated) {
      if (updated == true) {
        _loadLocationAndData();
      }
    });
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerCartScreen()),
    ).then((checkOutDone) {
      if (checkOutDone == true) {
        _loadLocationAndData();
      } else {
        setState(() {}); // refresh cart badge length
      }
    });
  }

  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerOrdersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _latitude != null && _longitude != null;

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Aswenna Retail Mart'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.deepLeafGreen),
                onPressed: _navigateToCart,
              ),
              if (Cart.items.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '${Cart.items.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.deepLeafGreen,
        onRefresh: _fetchProducts,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location guidance alert card
              GestureDetector(
                onTap: _navigateToProfile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: hasLocation ? AppTheme.lightMint : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: hasLocation ? AppTheme.deepLeafGreen.withOpacity(0.2) : Colors.orange.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasLocation ? Icons.location_on_rounded : Icons.location_off_rounded,
                        color: hasLocation ? AppTheme.deepLeafGreen : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasLocation ? 'Delivering Near: ${_cityName ?? "My Location"}' : 'Live Location Disabled',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: hasLocation ? AppTheme.darkGreen : Colors.orange[800],
                              ),
                            ),
                            Text(
                              hasLocation ? 'Showing retailers within 30 km radius' : 'Tap to pin coordinates on map for nearby filter',
                              style: TextStyle(fontSize: 11, color: hasLocation ? AppTheme.darkGreen : Colors.orange[900]),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              // Search field with real-time submit callback
              TextField(
                controller: _searchController,
                onSubmitted: (_) => _fetchProducts(),
                decoration: InputDecoration(
                  hintText: 'Search fresh crops & grocers...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.deepLeafGreen),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _fetchProducts();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Grade filter options
              const Text('Filter by Grade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGradeChip(null, 'All Grades'),
                  const SizedBox(width: 8),
                  _buildGradeChip('A', 'Grade A'),
                  const SizedBox(width: 8),
                  _buildGradeChip('B', 'Grade B'),
                  const SizedBox(width: 8),
                  _buildGradeChip('C', 'Grade C'),
                ],
              ),
              const SizedBox(height: 20),

              // Crop Category horizontal items list
              if (!_isLoadingCrops && _crops.isNotEmpty) ...[
                const Text('Crop Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _crops.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: const Text('All Categories'),
                            selected: _selectedCropId == null,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCropId = null);
                                _fetchProducts();
                              }
                            },
                          ),
                        );
                      }
                      final crop = _crops[index - 1];
                      final isSelected = _selectedCropId == crop['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(crop['cropname'] ?? ''),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCropId = selected ? crop['id'] : null;
                            });
                            _fetchProducts();
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Products Listing Grid or list
              const Text(
                'Retail Groceries',
                style: TextStyle(color: AppTheme.darkGreen, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),

              if (_isLoadingProducts)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppTheme.deepLeafGreen),
                ))
              else if (_products.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        Icon(Icons.eco_rounded, color: Colors.grey[400], size: 64),
                        const SizedBox(height: 12),
                        const Text(
                          'No products found near you.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasLocation ? 'Try increasing your search filters.' : 'Set coordinates to match local retailers.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return _buildProductListItem(product);
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppTheme.deepLeafGreen,
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_mall_rounded), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 1) {
            _navigateToOrders();
          } else if (index == 2) {
            _navigateToProfile();
          } else {
            setState(() => _currentIndex = index);
          }
        },
      ),
    );
  }

  Widget _buildGradeChip(String? grade, String label) {
    final isSelected = _selectedGrade == grade;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedGrade = selected ? grade : null;
        });
        _fetchProducts();
      },
    );
  }

  Widget _buildProductListItem(Map<String, dynamic> product) {
    final price = double.parse(product['price_per_unit'].toString());
    final hasDiscount = product['discount_price_per_unit'] != null &&
        double.parse(product['discount_price_per_unit'].toString()) > 0;
    final discountPrice = hasDiscount ? double.parse(product['discount_price_per_unit'].toString()) : null;

    final distance = product['distance'];
    final distanceStr = distance != null ? '${double.parse(distance.toString()).toStringAsFixed(1)} km away' : 'Distance unknown';

    final String? thumb = product['thumbnail_path'];
    final imageUrl = thumb != null ? ApiService.fileUrl(thumb) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.softGray,
              borderRadius: BorderRadius.circular(16),
              image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
            ),
            child: imageUrl == null ? const Icon(Icons.eco, color: AppTheme.deepLeafGreen, size: 30) : null,
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.lightMint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Grade ${product['grade']}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                      ),
                    ),
                    Text(
                      distanceStr,
                      style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  product['product_name'] ?? 'Product',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Retailer: ${product['seller']?['full_name'] ?? 'Shop'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            'LKR ${price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 9, color: Colors.red, decoration: TextDecoration.lineThrough),
                          ),
                          Text(
                            'LKR ${discountPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                          ),
                        ] else
                          Text(
                            'LKR ${price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                          ),
                        Text(
                          'per ${product['unit_type']}',
                          style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(60, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          Cart.add(product);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product['product_name']} added to cart!'),
                            duration: const Duration(seconds: 1),
                            action: SnackBarAction(
                              label: 'View Cart',
                              textColor: Colors.white,
                              onPressed: _navigateToCart,
                            ),
                          ),
                        );
                      },
                      child: const Text('Buy', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
