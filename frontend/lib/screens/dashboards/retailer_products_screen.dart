import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/crop_picker_screen.dart';
import 'package:aswenna/screens/market_rates/retailer_profile_screen.dart';

class RetailerProductsScreen extends StatefulWidget {
  const RetailerProductsScreen({super.key});

  @override
  State<RetailerProductsScreen> createState() => _RetailerProductsScreenState();
}

class _RetailerProductsScreenState extends State<RetailerProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isVerified = false;
  bool _hasPendingDoc = false;
  bool _hasRejectedDoc = false;
  String? _profilePic;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadProfileStatus();
  }

  Future<void> _loadProfileStatus() async {
    try {
      final result = await ApiService.getRetailSellerProfile();
      if (mounted && result['success'] == true) {
        final profile = result['profile'] ?? {};
        final user = profile['user'];
        final Map<dynamic, dynamic> userMap = user is Map ? user : {};
        final docsVal = profile['documents'];
        final List<dynamic> documents = docsVal is List ? docsVal : [];
        setState(() {
          _isVerified = userMap['is_verified'] == true;
          _hasPendingDoc = documents.any((doc) => doc is Map && doc['verification_status'] == 'pending');
          _hasRejectedDoc = documents.any((doc) => doc is Map && doc['verification_status'] == 'rejected');
          _profilePic = userMap['profile_picture_path'];
        });
      }
    } catch (e) {
      debugPrint('Error loading products profile status: $e');
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getRetailerProducts();
      if (response['success'] == true) {
        setState(() {
          _products = response['products'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load products.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final result = await ApiService.deleteRetailerProduct(id);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully.')),
          );
          _loadProducts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to delete product.'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openProductForm({Map<String, dynamic>? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductFormSheet(
        existingProduct: product,
        onSaved: () {
          Navigator.pop(context);
          _loadProducts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('My Retail Inventory'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.darkGreen),
            onPressed: () {
              _loadProducts();
              _loadProfileStatus();
            },
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RetailerProfileScreen()),
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
                        ElevatedButton(onPressed: _loadProducts, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, color: AppTheme.deepLeafGreen.withOpacity(0.4), size: 100),
                          const SizedBox(height: 16),
                          const Text(
                            'No products in your retail shop yet.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add your crops to start selling to customers!',
                            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            onPressed: () => _openProductForm(),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded),
                                SizedBox(width: 8),
                                Text('Add First Product'),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      color: AppTheme.deepLeafGreen,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return ProductCard(
                            product: product,
                            onEdit: () => _openProductForm(product: product),
                            onDelete: () => _deleteProduct(product['id']),
                          );
                        },
                      ),
                    ),
      floatingActionButton: _products.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.deepLeafGreen,
              foregroundColor: AppTheme.pureWhite,
              onPressed: () => _openProductForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product['discount_price_per_unit'] != null &&
        double.parse(product['discount_price_per_unit'].toString()) > 0;
    final price = double.parse(product['price_per_unit'].toString());
    final discountPrice = hasDiscount ? double.parse(product['discount_price_per_unit'].toString()) : null;

    final String? thumbnail = product['thumbnail_path'];
    final imageUrl = thumbnail != null ? ApiService.fileUrl(thumbnail) : null;

    final status = product['status'] ?? 'active';
    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = AppTheme.deepLeafGreen;
        break;
      case 'out_of_stock':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    final double stockQty = double.tryParse(product['stock_quantity'].toString()) ?? 0.0;
    final bool isLowStock = stockQty < 10.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.deepLeafGreen.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with rounded border and shadow
            Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.softGray,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    image: imageUrl != null
                        ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imageUrl == null
                      ? const Icon(Icons.eco_rounded, color: AppTheme.deepLeafGreen, size: 36)
                      : null,
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
                      ],
                    ),
                    child: Text(
                      'Grade ${product['grade']}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Details Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase().replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      Text(
                        'Category: ${product['crop']?['cropname'] ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product['product_name'] ?? 'Product Name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (product['description'] != null && product['description'].toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product['description'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stock Quantity with LOW STOCK alert pill
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLowStock ? Colors.orange : AppTheme.deepLeafGreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Stock: ',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          Text(
                            '${product['stock_quantity']} ${product['unit_type']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? Colors.orange[800] : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),
                  // Price and Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              'LKR ${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.red,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              'LKR ${discountPrice!.toStringAsFixed(2)} / ${product['unit_type']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deepLeafGreen,
                              ),
                            ),
                          ] else
                            Text(
                              'LKR ${price.toStringAsFixed(2)} / ${product['unit_type']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deepLeafGreen,
                              ),
                            ),
                        ],
                      ),
                      // Actions buttons with premium round circular tiles
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onEdit,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.edit_rounded, color: Colors.blue, size: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.delete_rounded, color: Colors.red, size: 16),
                            ),
                          ),
                        ],
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

class ProductFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existingProduct;
  final VoidCallback onSaved;

  const ProductFormSheet({
    super.key,
    this.existingProduct,
    required this.onSaved,
  });

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _stockController;

  Map<String, dynamic>? _selectedCrop;
  String _selectedGrade = 'A';
  String _selectedUnit = 'kg';
  String _selectedStatus = 'active';

  // Image picking
  String? _thumbnailPath;
  List<String> _imagesPaths = [];

  // Limit checker
  bool _isLoadingLimits = false;
  double? _marketAvg;
  double? _marketMax;
  bool _isFallback = false;
  String? _rateDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingProduct?['product_name'] ?? '');
    _descController = TextEditingController(text: widget.existingProduct?['description'] ?? '');
    _priceController = TextEditingController(text: widget.existingProduct?['price_per_unit'] ?? '');
    _discountController = TextEditingController(text: widget.existingProduct?['discount_price_per_unit'] ?? '');
    _stockController = TextEditingController(text: widget.existingProduct?['stock_quantity'] ?? '');

    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _selectedGrade = p['grade'] ?? 'A';
      _selectedUnit = p['unit_type'] ?? 'kg';
      _selectedStatus = p['status'] ?? 'active';

      if (p['crop'] != null) {
        _selectedCrop = {
          'id': p['crop_id'],
          'cropname': p['crop']['cropname'],
          'image_path': p['crop']['image_path'],
        };
        _fetchRateLimits();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickCrop() async {
    final pickedIds = await Navigator.push<Set<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => CropPickerScreen(
          initialSelectedIds: _selectedCrop != null ? {int.tryParse(_selectedCrop!['id'].toString()) ?? 0} : <int>{},
          title: 'Select Crop Category',
        ),
      ),
    );

    if (pickedIds != null && pickedIds.isNotEmpty) {
      final selectedId = pickedIds.first;
      final result = await ApiService.getApprovedCrops();
      if (result['success'] == true && result['crops'] != null) {
        final cropsList = List<Map<String, dynamic>>.from(result['crops']);
        final found = cropsList.firstWhere(
          (c) => (int.tryParse(c['id']?.toString() ?? '') ?? -1) == selectedId,
          orElse: () => <String, dynamic>{},
        );
        if (found.isNotEmpty) {
          setState(() {
            _selectedCrop = found;
            if (_nameController.text.isEmpty) {
              _nameController.text = 'Fresh ${found['cropname']}';
            }
          });
          _fetchRateLimits();
        }
      }
    }
  }

  Future<void> _fetchRateLimits() async {
    if (_selectedCrop == null) return;
    setState(() {
      _isLoadingLimits = true;
      _marketAvg = null;
      _marketMax = null;
    });

    final cropId = _selectedCrop!['id'];
    final result = await ApiService.getRetailerRateLimit(cropId, _selectedGrade);

    if (!mounted) return;

    setState(() {
      _isLoadingLimits = false;
      if (result['success'] == true && result['rate_info'] != null) {
        final info = result['rate_info'];
        _marketAvg = info['avg_rate'] != null ? double.tryParse(info['avg_rate'].toString()) : null;
        _marketMax = info['max_allowed_price'] != null ? double.tryParse(info['max_allowed_price'].toString()) : null;
        _isFallback = info['is_fallback'] == true;
        _rateDate = info['rate_date'];
      }
    });
  }

  Future<void> _pickThumbnail() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: false);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _thumbnailPath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking photo: $e')));
    }
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: true);
      if (result != null) {
        setState(() {
          _imagesPaths = result.paths.whereType<String>().toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking photos: $e')));
    }
  }

  Future<void> _save() async {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the crop category.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Direct check of price threshold again to ensure we absolute match rules
    final enteredPrice = double.tryParse(_priceController.text) ?? 0.0;
    if (_marketMax != null && enteredPrice > _marketMax!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Price cannot exceed maximum limit of LKR ${_marketMax!.toStringAsFixed(2)} for Grade $_selectedGrade.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'crop_id': _selectedCrop!['id'],
      'product_name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'price_per_unit': _priceController.text.trim(),
      'discount_price_per_unit': _discountController.text.trim().isEmpty ? null : _discountController.text.trim(),
      'stock_quantity': _stockController.text.trim(),
      'unit_type': _selectedUnit,
      'grade': _selectedGrade,
      'status': _selectedStatus,
    };

    final Map<String, dynamic> result;
    if (widget.existingProduct != null) {
      result = await ApiService.updateRetailerProduct(
        widget.existingProduct!['id'],
        data,
        thumbnailPath: _thumbnailPath,
        imagesPaths: _imagesPaths.isEmpty ? null : _imagesPaths,
      );
    } else {
      result = await ApiService.createRetailerProduct(
        data,
        thumbnailPath: _thumbnailPath,
        imagesPaths: _imagesPaths.isEmpty ? null : _imagesPaths,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved successfully.')),
      );
      widget.onSaved();
    } else {
      final msg = result['message'] ?? 'Failed to save product.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enteredPrice = double.tryParse(_priceController.text) ?? 0.0;
    final isPriceTooHigh = _marketMax != null && enteredPrice > _marketMax!;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.softGray,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: _isSaving
            ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
            : Form(
                key: _formKey,
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
                        widget.existingProduct != null ? 'Edit Product details' : 'Add New Product to Shop',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                      ),
                      const SizedBox(height: 24),

                      // Category Crop Picker
                      _buildSectionLabel('Crop Category'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickCrop,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.pureWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.spa_rounded, color: _selectedCrop != null ? AppTheme.deepLeafGreen : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedCrop != null ? _selectedCrop!['cropname'] : 'Tap to Choose Crop Category',
                                  style: TextStyle(
                                    fontWeight: _selectedCrop != null ? FontWeight.bold : FontWeight.normal,
                                    color: _selectedCrop != null ? const Color(0xFF0F172A) : Colors.grey,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Product Name
                      _buildInputField(
                        label: 'Product Name',
                        controller: _nameController,
                        hint: 'e.g. Premium Local Red Tomatoes',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required.' : null,
                      ),
                      const SizedBox(height: 20),

                      // Grade, Unit, Status in row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Grade',
                              value: _selectedGrade,
                              items: ['A', 'B', 'C'],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedGrade = val);
                                  _fetchRateLimits();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Unit',
                              value: _selectedUnit,
                              items: ['kg', 'g', 'liter', 'ml'],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedUnit = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Stock Quantity & Status
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'Stock Quantity',
                              controller: _stockController,
                              hint: 'e.g. 50',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required.' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Status',
                              value: _selectedStatus,
                              items: ['active', 'inactive', 'out_of_stock'],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedStatus = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // RATE LIMIT ENGINE REAL-TIME GUIDANCE CARD
                      if (_selectedCrop != null) ...[
                        _buildRateLimitEngineCard(enteredPrice, isPriceTooHigh),
                        const SizedBox(height: 20),
                      ],

                      // Price and Discount Price
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'Price per Unit (LKR)',
                              controller: _priceController,
                              hint: 'e.g. 350.00',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (val) {
                                setState(() {}); // trigger rebuild to recalculate alerts
                              },
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required.';
                                final val = double.tryParse(v);
                                if (val == null || val <= 0) return 'Invalid price.';
                                if (_marketMax != null && val > _marketMax!) {
                                  return 'Limit is LKR ${_marketMax!.toStringAsFixed(2)}';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              label: 'Discount Price (Opt)',
                              controller: _discountController,
                              hint: 'e.g. 320.00',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                if (v != null && v.trim().isNotEmpty) {
                                  final val = double.tryParse(v);
                                  if (val == null || val <= 0) return 'Invalid price.';
                                  final currentPrice = double.tryParse(_priceController.text) ?? 0.0;
                                  if (val >= currentPrice) return 'Must be lower than price.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      _buildInputField(
                        label: 'Description / Details',
                        controller: _descController,
                        hint: 'Explain packaging, freshness, source...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      // Product Images
                      _buildSectionLabel('Product Image Assets'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: _pickThumbnail,
                              icon: const Icon(Icons.photo_library_rounded, color: AppTheme.deepLeafGreen),
                              label: Text(
                                _thumbnailPath == null ? 'Thumbnail Image' : 'Thumbnail Selected',
                                style: const TextStyle(color: AppTheme.darkGreen, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: _pickImages,
                              icon: const Icon(Icons.collections_rounded, color: AppTheme.deepLeafGreen),
                              label: Text(
                                _imagesPaths.isEmpty ? 'More Images' : '${_imagesPaths.length} Selected',
                                style: const TextStyle(color: AppTheme.darkGreen, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Image Previews
                      // 1. Thumbnail Preview
                      if (_thumbnailPath != null || widget.existingProduct?['thumbnail_path'] != null) ...[
                        const SizedBox(height: 16),
                        _buildSectionLabel('Selected Thumbnail'),
                        const SizedBox(height: 8),
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.softGray),
                            image: _thumbnailPath != null
                                ? DecorationImage(image: FileImage(File(_thumbnailPath!)), fit: BoxFit.cover)
                                : DecorationImage(
                                    image: NetworkImage(ApiService.fileUrl(widget.existingProduct!['thumbnail_path']) ?? ''),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ],

                      // 2. Extra Images Preview
                      if (_imagesPaths.isNotEmpty || (widget.existingProduct?['image_paths'] != null && (widget.existingProduct!['image_paths'] as List).isNotEmpty)) ...[
                        const SizedBox(height: 16),
                        _buildSectionLabel('Product Gallery'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imagesPaths.isNotEmpty 
                                ? _imagesPaths.length 
                                : (widget.existingProduct!['image_paths'] as List).length,
                            itemBuilder: (context, idx) {
                              final String imagePath = _imagesPaths.isNotEmpty 
                                  ? _imagesPaths[idx] 
                                  : (widget.existingProduct!['image_paths'] as List)[idx].toString();
                              final bool isLocal = _imagesPaths.isNotEmpty;

                              return Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.softGray),
                                  image: DecorationImage(
                                    image: isLocal 
                                        ? FileImage(File(imagePath)) as ImageProvider
                                        : NetworkImage(ApiService.fileUrl(imagePath) ?? '') as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Save Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPriceTooHigh ? Colors.grey : AppTheme.deepLeafGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isPriceTooHigh ? null : _save,
                        child: const Text('Save Product Listing'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            fillColor: AppTheme.pureWhite,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.freshGreen)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.pureWhite,
              onChanged: onChanged,
              items: items
                  .map((val) => DropdownMenuItem(
                        value: val,
                        child: Text(
                          val.toUpperCase().replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateLimitEngineCard(double enteredPrice, bool isPriceTooHigh) {
    if (_isLoadingLimits) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen)),
      );
    }

    if (_marketAvg == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No Market Average Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                  const SizedBox(height: 4),
                  Text(
                    'No buyer rate logs are recorded today for ${_selectedCrop!['cropname']} (Grade $_selectedGrade). You can price this product freely.',
                    style: const TextStyle(fontSize: 11, color: Colors.brown),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPriceTooHigh ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPriceTooHigh ? Colors.red.withOpacity(0.3) : AppTheme.deepLeafGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPriceTooHigh ? Icons.error_outline_rounded : Icons.verified_user_outlined,
                color: isPriceTooHigh ? Colors.red : AppTheme.deepLeafGreen,
              ),
              const SizedBox(width: 12),
              Text(
                isPriceTooHigh ? 'Price Too High (Max +30%)' : 'Price Engine Compliant',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isPriceTooHigh ? Colors.red : AppTheme.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isFallback
                ? 'Using latest available rates from $_rateDate:'
                : 'Today\'s dynamic rates for ${_selectedCrop!['cropname']}:',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Market Average:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text('LKR ${_marketAvg!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Max Allowed (+30% limit):', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text(
                'LKR ${_marketMax!.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
              ),
            ],
          ),
          if (isPriceTooHigh) ...[
            const Divider(color: Colors.red, height: 16),
            Text(
              'Your current entered price LKR ${enteredPrice.toStringAsFixed(2)} is above the maximum allowed limit of LKR ${_marketMax!.toStringAsFixed(2)}. Please reduce your price to save.',
              style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ]
        ],
      ),
    );
  }
}
