import 'package:flutter/material.dart';
import 'dart:async';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/dashboards/customer_cart_screen.dart';
import 'package:aswenna/screens/dashboards/customer_profile_screen.dart';
import 'package:aswenna/screens/dashboards/customer_orders_screen.dart';
import 'package:aswenna/screens/login_screen.dart';

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

  // Profile Verification State
  bool _isVerified = false;
  bool _hasPendingDoc = false;
  bool _hasRejectedDoc = false;
  String? _profilePic;

  // Search & Filter State
  final _searchController = TextEditingController();
  int? _selectedCropId;
  String? _selectedGrade;
  
  // Advanced Filter System
  double _maxPrice = 2000.0;
  double _maxDistance = 50.0;
  bool _inStockOnly = false;
  double _minRating = 0.0;
  bool _sameDayOnly = false;
  String _sortBy = 'Best Match'; // Best Match, Nearest, Lowest Price, Highest Price, Most Popular, Highest Rated
  String _categorySearchQuery = '';

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

  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _loadLocationAndData() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    setState(() {
      _isLoadingProducts = true;
    });

    try {
      // 1. Load user profile details for coordinates and verification status
      final profileRes = await ApiService.getBuyerProfile();
      if (profileRes['success'] == true && profileRes['profile'] != null) {
        final profile = profileRes['profile'] ?? {};
        final u = profile['user'] ?? {};
        _latitude = u['latitude'] != null ? double.tryParse(u['latitude'].toString()) : null;
        _longitude = u['longitude'] != null ? double.tryParse(u['longitude'].toString()) : null;
        _cityName = u['city'] ?? u['district'];

        final docsVal = profile['documents'];
        final List<dynamic> documents = docsVal is List ? docsVal : [];
        setState(() {
          _isVerified = u['is_verified'] == true;
          _hasPendingDoc = documents.any((doc) => doc is Map && doc['verification_status'] == 'pending');
          _hasRejectedDoc = documents.any((doc) => doc is Map && doc['verification_status'] == 'rejected');
          _profilePic = u['profile_picture_path'];
        });
      } else if (profileRes['success'] == false &&
                 (profileRes['message']?.toString().toLowerCase().contains('expired') == true ||
                  profileRes['message']?.toString().toLowerCase().contains('sign in') == true ||
                  profileRes['message']?.toString().toLowerCase().contains('unauthenticated') == true ||
                  profileRes['message']?.toString().toLowerCase().contains('unauthorized') == true)) {
        _redirectToLogin();
        return;
      }
    } catch (e) {
      // ignore
    }

    // 2. Fetch products and approved crop categories
    _fetchProducts();
    _fetchCrops();
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
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
      } else if (response['success'] == false &&
                 (response['message']?.toString().toLowerCase().contains('expired') == true ||
                  response['message']?.toString().toLowerCase().contains('sign in') == true ||
                  response['message']?.toString().toLowerCase().contains('unauthenticated') == true ||
                  response['message']?.toString().toLowerCase().contains('unauthorized') == true)) {
        _redirectToLogin();
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
    if (!mounted) return;
    setState(() => _isLoadingCrops = true);
    try {
      final response = await ApiService.getApprovedCrops();
      if (response['success'] == true && mounted) {
        setState(() {
          _crops = response['crops'] ?? [];
        });
      } else if (response['success'] == false &&
                 (response['message']?.toString().toLowerCase().contains('expired') == true ||
                  response['message']?.toString().toLowerCase().contains('sign in') == true ||
                  response['message']?.toString().toLowerCase().contains('unauthenticated') == true ||
                  response['message']?.toString().toLowerCase().contains('unauthorized') == true)) {
        _redirectToLogin();
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
    final displayLocation = _cityName ?? "Colombo 03";

    // 1. Filter local product lists based on criteria
    List<dynamic> filteredProducts = [];
    try {
      filteredProducts = _products.where((p) {
        // Grade Filter
        if (_selectedGrade != null && p['grade']?.toString().toLowerCase() != _selectedGrade?.toLowerCase()) {
          return false;
        }
        // Crop Category Filter
        if (_selectedCropId != null && p['crop_id'] != _selectedCropId) {
          return false;
        }
        // Price Filter
        final double price = double.tryParse(p['price_per_unit']?.toString() ?? '0') ?? 0.0;
        final double discountPrice = p['discount_price_per_unit'] != null ? (double.tryParse(p['discount_price_per_unit'].toString()) ?? 0.0) : 0.0;
        final double activePrice = discountPrice > 0 ? discountPrice : price;
        if (activePrice > _maxPrice) {
          return false;
        }
        // Distance Filter
        final double distance = p['distance'] != null ? (double.tryParse(p['distance'].toString()) ?? 0.0) : 0.0;
        if (distance > _maxDistance) {
          return false;
        }
        // In Stock Only Filter
        final double stockQty = double.tryParse(p['stock_quantity']?.toString() ?? '0') ?? 0.0;
        final bool isOutOfStock = stockQty <= 0 || p['status'] == 'out_of_stock';
        if (_inStockOnly && isOutOfStock) {
          return false;
        }
        // Rating Filter
        final double rating = p['seller']?['rating'] != null ? (double.tryParse(p['seller']['rating'].toString()) ?? 0.0) : 0.0;
        if (rating < _minRating) {
          return false;
        }
        // Same-Day Delivery Filter (Mocked for distance <= 15 km)
        if (_sameDayOnly && distance > 15) {
          return false;
        }
        return true;
      }).toList();

      // Sorting implementation
      if (_sortBy == 'Nearest') {
        filteredProducts.sort((a, b) {
          final double distA = a['distance'] != null ? (double.tryParse(a['distance'].toString()) ?? 0.0) : 999.0;
          final double distB = b['distance'] != null ? (double.tryParse(b['distance'].toString()) ?? 0.0) : 999.0;
          return distA.compareTo(distB);
        });
      } else if (_sortBy == 'Lowest Price') {
        filteredProducts.sort((a, b) {
          final double priceA = a['discount_price_per_unit'] != null && (double.tryParse(a['discount_price_per_unit'].toString()) ?? 0.0) > 0
              ? (double.tryParse(a['discount_price_per_unit'].toString()) ?? 0.0)
              : (double.tryParse(a['price_per_unit'].toString()) ?? 0.0);
          final double priceB = b['discount_price_per_unit'] != null && (double.tryParse(b['discount_price_per_unit'].toString()) ?? 0.0) > 0
              ? (double.tryParse(b['discount_price_per_unit'].toString()) ?? 0.0)
              : (double.tryParse(b['price_per_unit'].toString()) ?? 0.0);
          return priceA.compareTo(priceB);
        });
      } else if (_sortBy == 'Highest Price') {
        filteredProducts.sort((a, b) {
          final double priceA = a['discount_price_per_unit'] != null && (double.tryParse(a['discount_price_per_unit'].toString()) ?? 0.0) > 0
              ? (double.tryParse(a['discount_price_per_unit'].toString()) ?? 0.0)
              : (double.tryParse(a['price_per_unit'].toString()) ?? 0.0);
          final double priceB = b['discount_price_per_unit'] != null && (double.tryParse(b['discount_price_per_unit'].toString()) ?? 0.0) > 0
              ? (double.tryParse(b['discount_price_per_unit'].toString()) ?? 0.0)
              : (double.tryParse(b['price_per_unit'].toString()) ?? 0.0);
          return priceB.compareTo(priceA);
        });
      } else if (_sortBy == 'Highest Rated') {
        filteredProducts.sort((a, b) {
          final double rateA = a['seller']?['rating'] != null ? (double.tryParse(a['seller']['rating'].toString()) ?? 0.0) : 0.0;
          final double rateB = b['seller']?['rating'] != null ? (double.tryParse(b['seller']['rating'].toString()) ?? 0.0) : 0.0;
          return rateB.compareTo(rateA);
        });
      } else if (_sortBy == 'Most Popular') {
        filteredProducts.sort((a, b) {
          final double stockA = double.tryParse(a['stock_quantity']?.toString() ?? '0') ?? 0.0;
          final double stockB = double.tryParse(b['stock_quantity']?.toString() ?? '0') ?? 0.0;
          return stockB.compareTo(stockA);
        });
      }
    } catch (e) {
      debugPrint('Error filtering products: $e');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: GestureDetector(
          onTap: _openLocationPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.deepLeafGreen, size: 20),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivering to', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Text(
                        displayLocation,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.deepLeafGreen, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF475569)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications.')),
              );
            },
          ),
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
          GestureDetector(
            onTap: _navigateToProfile,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 34,
                    height: 34,
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
                      borderRadius: BorderRadius.circular(17),
                      child: () {
                        final String? pic = _profilePic;
                        final String? url = pic != null && pic.isNotEmpty ? ApiService.fileUrl(pic) : null;
                        if (url != null && url.trim().isNotEmpty) {
                          return Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppTheme.deepLeafGreen, size: 18),
                          );
                        }
                        return const Icon(Icons.person, color: AppTheme.deepLeafGreen, size: 18);
                      }(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1.0),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
                        size: 9,
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
        onRefresh: () async {
          await _fetchProducts();
          await _fetchCrops();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Search Bar & Filter Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _fetchProducts(),
                      decoration: InputDecoration(
                        hintText: 'Search products, retailers, categories...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.deepLeafGreen),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _fetchProducts();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF334155),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _openFilterBottomSheet,
                          icon: const Icon(Icons.tune_rounded, size: 16, color: AppTheme.deepLeafGreen),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              if (_selectedGrade != null || _inStockOnly || _sameDayOnly || _minRating > 0 || _maxPrice < 2000.0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppTheme.deepLeafGreen, shape: BoxShape.circle),
                                  child: const Text('!', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF334155),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _openSortBottomSheet,
                          icon: const Icon(Icons.sort_rounded, size: 16, color: AppTheme.deepLeafGreen),
                          label: Text(
                            _sortBy,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Promotional Banner Carousel
            _buildPromoBannerCarousel(),
            
            // Crop Categories Grid
            _buildCropCategoriesGrid(),

            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Retail Groceries',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${filteredProducts.length} Items Found',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            if (_isLoadingProducts)
              const Center(child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: AppTheme.deepLeafGreen),
              ))
            else if (filteredProducts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco_rounded, color: Colors.grey[300], size: 64),
                      const SizedBox(height: 12),
                      const Text(
                        'No items match your filters.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Try resetting filters or changing the search keyword.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: filteredProducts.map((p) {
                    return _buildPremiumProductListItem(p);
                  }).toList(),
                ),
              ),

            const SizedBox(height: 40),
          ],
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

  void _openLocationPicker() {
    _navigateToProfile();
  }

  Widget _buildPromoBannerCarousel() {
    final List<Map<String, String>> banners = [
      {
        'title': 'Fresh Organic Harvest',
        'subtitle': 'Direct from Nuwara Eliya Farms',
        'discount': 'Up to 30% OFF',
        'asset': 'assets/images/welcome_bg1.jpg',
      },
      {
        'title': 'Premium Grade Crops',
        'subtitle': 'Freshly plucked this morning',
        'discount': 'Buy 1 Get 1 Free',
        'asset': 'assets/images/rate_engine_bg.jpg',
      },
      {
        'title': 'Same-Day Fast Delivery',
        'subtitle': 'Zero emissions green shipping',
        'discount': 'Free over LKR 1500',
        'asset': 'assets/images/role_selection_bg.jpg',
      },
    ];

    return Container(
      height: 130,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          final String assetPath = banner['asset'] ?? '';
          return Container(
            width: MediaQuery.of(context).size.width * 0.82,
            margin: EdgeInsets.only(left: 16, right: index == banners.length - 1 ? 16 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: assetPath.isNotEmpty
                  ? DecorationImage(
                      image: AssetImage(assetPath),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(const Color(0x66000000), BlendMode.darken),
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    banner['discount'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  banner['title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                Text(
                  banner['subtitle'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCropCategoriesGrid() {
    if (_crops.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<dynamic> categoriesToDisplay = _crops.take(6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore Categories 🥬',
            style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoriesToDisplay.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final cat = categoriesToDisplay[index];
              final isSelected = cat is Map ? (_selectedCropId == cat['id']) : false;
              final String name = cat is Map ? (cat['cropname']?.toString() ?? '') : '';
              final Color bg = const Color(0xFFE8F5E9);
              final IconData icon = Icons.eco_rounded;

              return GestureDetector(
                onTap: () {
                  if (cat is Map && cat['id'] != null) {
                    setState(() {
                      if (isSelected) {
                        _selectedCropId = null;
                      } else {
                        _selectedCropId = cat['id'];
                      }
                    });
                    _fetchProducts();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.deepLeafGreen : bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.deepLeafGreen : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(color: const Color(0x05000000), blurRadius: 8, offset: const Offset(0, 4))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      () {
                        final String? imgPath = cat is Map ? cat['image_path'] : null;
                        if (imgPath != null && imgPath.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              ApiService.fileUrl(imgPath)!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                icon,
                                color: isSelected ? Colors.white : AppTheme.deepLeafGreen,
                                size: 24,
                              ),
                            ),
                          );
                        }
                        return Icon(icon, color: isSelected ? Colors.white : AppTheme.deepLeafGreen, size: 24);
                      }(),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _openCategoriesSearchSheet,
              icon: const Icon(Icons.grid_view_rounded, size: 14, color: AppTheme.deepLeafGreen),
              label: const Text('View All Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.deepLeafGreen)),
            ),
          ),
        ],
      ),
    );
  }

  void _openCategoriesSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCrops = _crops.where((c) {
              final String name = c['cropname']?.toString().toLowerCase() ?? '';
              return name.contains(_categorySearchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search crop categories...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search_rounded, color: AppTheme.deepLeafGreen),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          _categorySearchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCrops.length,
                      itemBuilder: (context, index) {
                        final crop = filteredCrops[index];
                        final isSelected = _selectedCropId == crop['id'];
                        final String? imgPath = crop['image_path'];
                        Widget leadingWidget;
                        if (imgPath != null && imgPath.isNotEmpty) {
                          leadingWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              ApiService.fileUrl(imgPath)!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 20),
                            ),
                          );
                        } else {
                          leadingWidget = const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 20);
                        }

                        return ListTile(
                          leading: leadingWidget,
                          title: Text(crop['cropname'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.deepLeafGreen) : null,
                          onTap: () {
                            setState(() {
                              _selectedCropId = crop['id'];
                            });
                            _fetchProducts();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openFilterBottomSheet() {
    double localMaxPrice = _maxPrice;
    double localMaxDistance = _maxDistance;
    bool localInStockOnly = _inStockOnly;
    bool localSameDayOnly = _sameDayOnly;
    String? localSelectedGrade = _selectedGrade;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setFilterState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Advanced Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setFilterState(() {
                            localSelectedGrade = null;
                            localMaxPrice = 2000.0;
                            localMaxDistance = 50.0;
                            localInStockOnly = false;
                            localSameDayOnly = false;
                          });
                        },
                        child: const Text('Reset All', style: TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(),

                  const Text('Crop Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Grade A', 'Grade B', 'Grade C'].map((g) {
                      final gradeLetter = g.replaceAll('Grade ', '');
                      final isSel = localSelectedGrade?.toLowerCase() == gradeLetter.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(g),
                          selected: isSel,
                          onSelected: (selected) {
                            setFilterState(() {
                              localSelectedGrade = selected ? gradeLetter : null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Maximum Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('LKR ${localMaxPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen)),
                    ],
                  ),
                  Slider(
                    value: localMaxPrice,
                    min: 100.0,
                    max: 2000.0,
                    divisions: 19,
                    activeColor: AppTheme.deepLeafGreen,
                    inactiveColor: const Color(0xFFE2E8F0),
                    onChanged: (val) {
                      setFilterState(() {
                        localMaxPrice = val;
                      });
                    },
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Maximum Distance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${localMaxDistance.toStringAsFixed(0)} km', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen)),
                    ],
                  ),
                  Slider(
                    value: localMaxDistance,
                    min: 5.0,
                    max: 50.0,
                    divisions: 9,
                    activeColor: AppTheme.deepLeafGreen,
                    inactiveColor: const Color(0xFFE2E8F0),
                    onChanged: (val) {
                      setFilterState(() {
                        localMaxDistance = val;
                      });
                    },
                  ),

                  SwitchListTile(
                    activeColor: AppTheme.deepLeafGreen,
                    title: const Text('In Stock Only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    value: localInStockOnly,
                    onChanged: (val) {
                      setFilterState(() {
                        localInStockOnly = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    activeColor: AppTheme.deepLeafGreen,
                    title: const Text('Same-day Speed Delivery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    value: localSameDayOnly,
                    onChanged: (val) {
                      setFilterState(() {
                        localSameDayOnly = val;
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepLeafGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _maxPrice = localMaxPrice;
                          _maxDistance = localMaxDistance;
                          _inStockOnly = localInStockOnly;
                          _sameDayOnly = localSameDayOnly;
                          _selectedGrade = localSelectedGrade;
                        });
                        _fetchProducts();
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Advanced Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openSortBottomSheet() {
    final sorts = ['Best Match', 'Nearest', 'Lowest Price', 'Highest Price', 'Most Popular', 'Highest Rated'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sort By', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Divider(),
              ...sorts.map((s) {
                final isSel = _sortBy == s;
                return ListTile(
                  title: Text(s, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? AppTheme.deepLeafGreen : null)),
                  trailing: isSel ? const Icon(Icons.check_circle_rounded, color: AppTheme.deepLeafGreen) : null,
                  onTap: () {
                    setState(() {
                      _sortBy = s;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumProductListItem(dynamic productData) {
    final Map<String, dynamic> product = productData is Map<String, dynamic> ? productData : <String, dynamic>{};
    try {
      final double price = double.tryParse(product['price_per_unit']?.toString() ?? '0') ?? 0.0;
      final hasDiscount = product['discount_price_per_unit'] != null &&
          (double.tryParse(product['discount_price_per_unit'].toString()) ?? 0.0) > 0;
      final discountPrice = hasDiscount ? (double.tryParse(product['discount_price_per_unit'].toString()) ?? 0.0) : 0.0;

      final distance = product['distance'];
      final distanceStr = distance != null ? '${(double.tryParse(distance.toString()) ?? 0.0).toStringAsFixed(1)} km away' : 'Distance unknown';

      final String? thumb = product['thumbnail_path'];
      final String? rawUrl = thumb != null && thumb.isNotEmpty ? ApiService.fileUrl(thumb) : null;
      final String? imageUrl = (rawUrl != null && rawUrl.trim().isNotEmpty) ? rawUrl : null;

      final double stockQty = double.tryParse(product['stock_quantity']?.toString() ?? '0') ?? 0.0;
      final bool isOutOfStock = stockQty <= 0 || product['status'] == 'out_of_stock';
      
      final String grade = product['grade']?.toString() ?? 'A';
      final String productName = product['product_name']?.toString() ?? 'Fresh Produce';
      final String sellerName = product['seller']?['full_name']?.toString() ?? 'Aswenna Seller';
      final String unitType = product['unit_type']?.toString() ?? 'kg';

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showProductDetailsPopup(product),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0A1B5E20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppTheme.softGray,
                  child: imageUrl != null && imageUrl.trim().isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 32);
                          },
                        )
                      : const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 32),
                ),
              ),
              const SizedBox(width: 14),
              
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
                            color: isOutOfStock ? const Color(0xFFFFEBEE) : AppTheme.lightMint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOutOfStock ? 'Sold Out' : 'Grade $grade',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isOutOfStock ? const Color(0xFFC62828) : AppTheme.darkGreen,
                            ),
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
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Retailer: $sellerName',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                if (hasDiscount) ...[
                                  TextSpan(
                                    text: 'LKR ${discountPrice.toStringAsFixed(0)} ',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.deepLeafGreen),
                                  ),
                                  TextSpan(
                                    text: 'LKR ${price.toStringAsFixed(0)} ',
                                    style: const TextStyle(fontSize: 10, color: Colors.red, decoration: TextDecoration.lineThrough),
                                  ),
                                ] else
                                  TextSpan(
                                    text: 'LKR ${price.toStringAsFixed(0)} ',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.deepLeafGreen),
                                  ),
                                TextSpan(
                                  text: '/ $unitType',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOutOfStock ? Colors.grey : AppTheme.deepLeafGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: isOutOfStock ? null : () => _showProductDetailsPopup(product),
                            child: const Text('ADD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint("Error rendering card: $e\n$stack");
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        color: Colors.red[50],
        child: Text("Error rendering card: $e", style: const TextStyle(color: Colors.red, fontSize: 10)),
      );
    }
  }

  void _showProductDetailsPopup(Map<String, dynamic> product) {
    final double price = double.tryParse(product['price_per_unit']?.toString() ?? '0') ?? 0.0;
    final hasDiscount = product['discount_price_per_unit'] != null &&
        (double.tryParse(product['discount_price_per_unit'].toString()) ?? 0.0) > 0;
    final discountPrice = hasDiscount ? (double.tryParse(product['discount_price_per_unit'].toString()) ?? 0.0) : null;
    final activePrice = discountPrice ?? price;

    final distance = product['distance'];
    final distanceStr = distance != null ? '${(double.tryParse(distance.toString()) ?? 0.0).toStringAsFixed(1)} km away' : 'Distance unknown';

    final String? thumb = product['thumbnail_path'];
    final imageUrl = thumb != null ? ApiService.fileUrl(thumb) : null;

    final double stockQty = double.tryParse(product['stock_quantity']?.toString() ?? '0') ?? 0.0;
    final bool isOutOfStock = stockQty <= 0 || product['status'] == 'out_of_stock';
    
    double selectedQty = 1.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Stack(
                      children: [
                        Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.softGray,
                            image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                          ),
                          child: imageUrl == null ? const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 72) : null,
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconButton(
                            style: IconButton.styleFrom(backgroundColor: Colors.white),
                            icon: const Icon(Icons.close_rounded, color: Colors.black87),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.deepLeafGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Grade ${product['grade']}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['product_name'] ?? 'Product',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Retailer: ${product['seller']?['full_name'] ?? 'Shop'}',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (hasDiscount) ...[
                                    Text(
                                      'LKR ${(discountPrice ?? 0.0).toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.deepLeafGreen),
                                    ),
                                    Text(
                                      'LKR ${price.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 13, color: Colors.red, decoration: TextDecoration.lineThrough),
                                    ),
                                  ] else
                                    Text(
                                      'LKR ${price.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.deepLeafGreen),
                                    ),
                                  Text(
                                    'per ${product['unit_type']}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  Icons.social_distance_rounded,
                                  'Distance',
                                  distanceStr,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  Icons.star_rounded,
                                  'Seller Rating',
                                  '${product['seller']?['rating'] ?? "N/A"} ★',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Product Details & Description',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product['description']?.toString().isNotEmpty == true
                                ? (product['description']?.toString() ?? '')
                                : 'No description provided by the seller. This crop is freshly harvested and certified under Aswenna Agricultural Marketplace standards.',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                  const SizedBox(height: 4),
                                  ProductQuantitySelector(
                                    stockQuantity: stockQty,
                                    unitType: product['unit_type'] ?? 'kg',
                                    initialValue: selectedQty,
                                    onChanged: (val) {
                                      setModalState(() {
                                        selectedQty = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isOutOfStock ? Colors.grey : AppTheme.deepLeafGreen,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                      onPressed: isOutOfStock
                                          ? null
                                          : () {
                                              setState(() {
                                                Cart.add(product, qty: selectedQty);
                                              });
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('$selectedQty ${product['unit_type']} of ${product['product_name']} added to cart!'),
                                                ),
                                              );
                                            },
                                      child: Text(
                                        isOutOfStock ? 'OUT OF STOCK' : 'ADD TO BASKET',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
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

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.deepLeafGreen, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductQuantitySelector extends StatefulWidget {
  final double stockQuantity;
  final String unitType;
  final double initialValue;
  final ValueChanged<double> onChanged;
  final bool allowManualInput;

  const ProductQuantitySelector({
    super.key,
    required this.stockQuantity,
    required this.unitType,
    required this.initialValue,
    required this.onChanged,
    this.allowManualInput = true,
  });

  @override
  State<ProductQuantitySelector> createState() => _ProductQuantitySelectorState();
}

class _ProductQuantitySelectorState extends State<ProductQuantitySelector> {
  late TextEditingController _controller;
  late double _currentVal;

  @override
  void initState() {
    super.initState();
    _currentVal = widget.initialValue;
    _controller = TextEditingController(text: _formatValue(_currentVal));
  }

  @override
  void didUpdateWidget(ProductQuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _currentVal) {
      setState(() {
        _currentVal = widget.initialValue;
        _controller.text = _formatValue(_currentVal);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  String _formatValue(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  void _updateVal(double newVal) {
    if (newVal < 0.1) newVal = 0.1;
    if (newVal > widget.stockQuantity) {
      newVal = widget.stockQuantity;
    }
    setState(() {
      _currentVal = newVal;
      _controller.text = _formatValue(_currentVal);
    });
    widget.onChanged(_currentVal);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.deepLeafGreen, size: 24),
          onPressed: () => _updateVal(_currentVal - 1.0),
        ),
        const SizedBox(width: 8),
        Container(
          width: 80,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300] ?? Colors.grey),
          ),
          child: widget.allowManualInput
              ? TextFormField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      double safeVal = parsed;
                      if (safeVal < 0.1) safeVal = 0.1;
                      if (safeVal > widget.stockQuantity) {
                        safeVal = widget.stockQuantity;
                        _controller.text = _formatValue(safeVal);
                        _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
                      }
                      _currentVal = safeVal;
                      widget.onChanged(_currentVal);
                    }
                  },
                )
              : Text(
                  _formatValue(_currentVal),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
        ),
        const SizedBox(width: 8),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.deepLeafGreen, size: 24),
          onPressed: () => _updateVal(_currentVal + 1.0),
        ),
      ],
    );
  }
}
