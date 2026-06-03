import 'package:flutter/material.dart';
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
      // 1. Load user profile details for coordinates
      final profileRes = await ApiService.getBuyerProfile();
      if (profileRes['success'] == true && profileRes['profile'] != null) {
        final u = profileRes['profile']['user'];
        _latitude = u['latitude'] != null ? double.tryParse(u['latitude'].toString()) : null;
        _longitude = u['longitude'] != null ? double.tryParse(u['longitude'].toString()) : null;
        _cityName = u['city'] ?? u['district'];
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
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
              ),
              const SizedBox(height: 20),

              // Crop Category horizontal items list
              if (!_isLoadingCrops && _crops.isNotEmpty) ...[
                const Text('Crop Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All Categories'),
                        selected: _selectedCropId == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCropId = null);
                            _fetchProducts();
                          }
                        },
                      ),
                      ..._crops.map((crop) {
                        final isSelected = _selectedCropId == crop['id'];
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
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
                      }),
                    ],
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
                Column(
                  children: _products.map((product) {
                    return _buildProductListItem(product, key: ValueKey('prod_${product['id']}'));
                  }).toList(),
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


  void _showProductDetailsPopup(Map<String, dynamic> product) {
    final int productId = product['id'];
    final double price = double.parse(product['price_per_unit'].toString());
    final hasDiscount = product['discount_price_per_unit'] != null &&
        double.parse(product['discount_price_per_unit'].toString()) > 0;
    final discountPrice = hasDiscount ? double.parse(product['discount_price_per_unit'].toString()) : null;
    final activePrice = discountPrice ?? price;

    final String? thumb = product['thumbnail_path'];
    final imageUrl = thumb != null ? ApiService.fileUrl(thumb) : null;
    final double stockQty = double.tryParse(product['stock_quantity']?.toString() ?? '0') ?? 0.0;
    final bool isOutOfStock = stockQty <= 0 || product['status'] == 'out_of_stock';

    double popupQty = 1.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            final double currentTotal = activePrice * popupQty;
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Product Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Image
                      Center(
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppTheme.softGray,
                            borderRadius: BorderRadius.circular(20),
                            image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                          ),
                          child: imageUrl == null ? const Icon(Icons.eco, color: AppTheme.deepLeafGreen, size: 64) : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details
                      Text(
                        product['product_name'] ?? 'Product',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seller: ${product['seller']?['full_name'] ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),

                      // Grade / Distance / Stock row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOutOfStock ? const Color(0xFFFFEBEE) : AppTheme.lightMint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOutOfStock ? 'Sold Out' : 'Grade ${product['grade']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOutOfStock ? const Color(0xFFC62828) : AppTheme.darkGreen,
                              ),
                            ),
                          ),
                          Text(
                            isOutOfStock ? 'Out of Stock' : '${stockQty.toStringAsFixed(1)} ${product['unit_type']} left',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOutOfStock ? const Color(0xFFC62828) : AppTheme.deepLeafGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 16),

                      // Price Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Unit Price',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'LKR ${activePrice.toStringAsFixed(2)} per ${product['unit_type']}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quantity Selector Row
                      if (!isOutOfStock) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Order Quantity',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                            ProductQuantitySelector(
                              key: ValueKey('qty_popup_$productId'),
                              stockQuantity: stockQty,
                              unitType: product['unit_type'] ?? 'kg',
                              initialValue: popupQty,
                              onChanged: (newQty) {
                                setPopupState(() {
                                  popupQty = newQty;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 16),

                        // Calculated Total Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Calculated Price',
                              style: TextStyle(fontSize: 14, color: AppTheme.darkGreen, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'LKR ${currentTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.deepLeafGreen),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Add to Cart / Buy Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isOutOfStock
                              ? null
                              : () {
                                  setState(() {
                                    Cart.add(product, qty: popupQty);
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product['product_name']} (x$popupQty) added to cart!'),
                                      duration: const Duration(seconds: 1),
                                      action: SnackBarAction(
                                        label: 'View Cart',
                                        textColor: Colors.white,
                                        onPressed: _navigateToCart,
                                      ),
                                    ),
                                  );
                                },
                          child: Text(
                            isOutOfStock ? 'Product Out of Stock' : 'Add to Cart',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductListItem(Map<String, dynamic> product, {Key? key}) {
    final double price = double.parse(product['price_per_unit'].toString());
    final hasDiscount = product['discount_price_per_unit'] != null &&
        double.parse(product['discount_price_per_unit'].toString()) > 0;
    final discountPrice = hasDiscount ? double.parse(product['discount_price_per_unit'].toString()) : null;

    final distance = product['distance'];
    final distanceStr = distance != null ? '${double.parse(distance.toString()).toStringAsFixed(1)} km away' : 'Distance unknown';

    final String? thumb = product['thumbnail_path'];
    final imageUrl = thumb != null ? ApiService.fileUrl(thumb) : null;

    final double stockQty = double.tryParse(product['stock_quantity']?.toString() ?? '0') ?? 0.0;
    final bool isOutOfStock = stockQty <= 0 || product['status'] == 'out_of_stock';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showProductDetailsPopup(product),
      child: Container(
        key: key,
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
            // Thumbnail Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.softGray,
                borderRadius: BorderRadius.circular(16),
                image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
              ),
              child: imageUrl == null ? const Icon(Icons.eco, color: AppTheme.deepLeafGreen, size: 32) : null,
            ),
            const SizedBox(width: 14),
            
            // Details
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
                          isOutOfStock ? 'Sold Out' : 'Grade ${product['grade']}',
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
                    product['product_name'] ?? 'Product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Retailer: ${product['seller']?['full_name'] ?? 'Shop'}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  
                  // Price and stock status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              'LKR ${discountPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.deepLeafGreen),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LKR ${price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 10, color: Colors.red, decoration: TextDecoration.lineThrough),
                            ),
                          ] else
                            Text(
                              'LKR ${price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.deepLeafGreen),
                            ),
                          Text(
                            ' / ${product['unit_type']}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      Text(
                        isOutOfStock ? 'Out of stock' : '${stockQty.toStringAsFixed(1)} ${product['unit_type']} left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOutOfStock ? const Color(0xFFC62828) : AppTheme.deepLeafGreen,
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
          icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.deepLeafGreen, size: 20),
          onPressed: () {
            _updateVal(_currentVal - 1.0);
          },
        ),
        const SizedBox(width: 4),
        Container(
          width: 44,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: widget.allowManualInput
              ? TextFormField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
        ),
        const SizedBox(width: 4),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.deepLeafGreen, size: 20),
          onPressed: () {
            _updateVal(_currentVal + 1.0);
          },
        ),
      ],
    );
  }
}
