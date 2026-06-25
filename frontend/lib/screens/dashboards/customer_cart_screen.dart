import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/map_location_picker.dart';
import 'package:aswenna/screens/payment/retail_payment_screen.dart';

class CartItem {
  final Map<String, dynamic> product;
  double quantity;

  CartItem({required this.product, this.quantity = 1.0});
}

class Cart {
  static final List<CartItem> items = [];

  static void add(Map<String, dynamic> product, {double qty = 1.0}) {
    final existingIndex = items.indexWhere((item) => item.product['id'] == product['id']);
    if (existingIndex != -1) {
      items[existingIndex].quantity += qty;
    } else {
      items.add(CartItem(product: product, quantity: qty));
    }
  }

  static void remove(int productId) {
    items.removeWhere((item) => item.product['id'] == productId);
  }

  static void clear() {
    items.clear();
  }

  static double get total {
    double sum = 0.0;
    for (var item in items) {
      final price = item.product['discount_price_per_unit'] != null
          ? double.parse(item.product['discount_price_per_unit'].toString())
          : double.parse(item.product['price_per_unit'].toString());
      sum += price * item.quantity;
    }
    return sum;
  }
}

class CustomerCartScreen extends StatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  final _addressController = TextEditingController();
  bool _isCheckingOut = false;
  bool _isLocating = false;

  double? _latitude;
  double? _longitude;
  GoogleMapController? _mapController;

  double? _deliveryFee;
  double? _deliveryDistance;
  double? _deliveryWeight;
  double? _ratePerKm;
  bool _isCalculatingDelivery = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerProfileLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerProfileLocation() async {
    try {
      final response = await ApiService.getBuyerProfile();
      if (response['success'] == true && response['profile'] != null) {
        final u = response['profile']['user'];
        setState(() {
          _addressController.text = (u['address'] ?? '').toString();
          _latitude = u['latitude'] != null ? double.tryParse(u['latitude'].toString()) : null;
          _longitude = u['longitude'] != null ? double.tryParse(u['longitude'].toString()) : null;
        });

        if (_latitude != null && _longitude != null) {
          try {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(_latitude!, _longitude!), 15),
            );
          } catch (e) {
            // Fail silently if map is disposed
          }
          _updateDeliveryFee();
        }
      }
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> _updateDeliveryFee() async {
    if (Cart.items.isEmpty) return;
    if (_latitude == null || _longitude == null) return;

    setState(() {
      _isCalculatingDelivery = true;
    });

    final cartList = Cart.items.map((item) => {
      'retailer_product_id': item.product['id'],
      'quantity': item.quantity,
    }).toList();

    try {
      final res = await ApiService.calculateDelivery(
        lat: _latitude!,
        lng: _longitude!,
        cartItems: cartList,
      );
      if (res['success'] == true) {
        setState(() {
          _deliveryFee = double.tryParse(res['delivery_fee']?.toString() ?? '0');
          _deliveryDistance = double.tryParse(res['distance_km']?.toString() ?? '0');
          _deliveryWeight = double.tryParse(res['total_weight_kg']?.toString() ?? '0');
          _ratePerKm = double.tryParse(res['rate_per_km']?.toString() ?? '0');
        });
      }
    } catch (e) {
      // Fail silently
    } finally {
      setState(() {
        _isCalculatingDelivery = false;
      });
    }
  }

  Future<void> _useGPS() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable GPS location services.')),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are required.')),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        try {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15),
          );
        } catch (e) {
          // Fail silently
        }
        _updateDeliveryFee();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _openMapPicker() async {
    final picked = await Navigator.of(context).push<Map<String, double>>(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          title: 'Select Delivery Spot',
        ),
      ),
    );

    if (picked != null && picked['latitude'] != null && picked['longitude'] != null && mounted) {
      setState(() {
        _latitude = picked['latitude']!;
        _longitude = picked['longitude']!;
      });
      try {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(_latitude!, _longitude!), 15),
        );
      } catch (e) {
        // Fail silently
      }
      _updateDeliveryFee();
    }
  }

  Future<void> _checkout() async {
    if (Cart.items.isEmpty) return;
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery address.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isCheckingOut = true);

    final cartList = Cart.items.map((item) => {
      'retailer_product_id': item.product['id'],
      'quantity': item.quantity,
    }).toList();

    final data = {
      'delivery_address': _addressController.text.trim(),
      'delivery_latitude': _latitude,
      'delivery_longitude': _longitude,
      'cart_items': cartList,
    };

    try {
      final response = await ApiService.placeCustomerOrder(data);
      if (response['success'] == true) {
        final orderData = (response['orders'] != null && response['orders'].isNotEmpty) ? response['orders'][0] : null;
        setState(() {
          Cart.clear();
        });

        if (orderData != null) {
          final orderId = orderData['id'];
          // Navigate to retail payment screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RetailPaymentScreen(
                orderId: orderId,
                order: orderData,
              ),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.deepLeafGreen),
                  SizedBox(width: 8),
                  Text('Order Placed!'),
                ],
              ),
              content: Text(response['message'] ?? 'Your order has been split by retailer and placed successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, true); // Return to dashboard, notify checkout success
                  },
                  child: const Text('OK', style: TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to place order.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group items by retailer
    final Map<String, List<CartItem>> groupedItems = {};
    for (var item in Cart.items) {
      final sellerName = item.product['seller']?['full_name'] ?? 'Unknown Retailer';
      if (!groupedItems.containsKey(sellerName)) {
        groupedItems[sellerName] = [];
      }
      groupedItems[sellerName]!.add(item);
    }

    final LatLng initialTarget = _latitude != null && _longitude != null
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(6.9271, 79.8612);

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('My Retail Cart'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isCheckingOut
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
          : Cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, color: AppTheme.deepLeafGreen.withOpacity(0.4), size: 100),
                      const SizedBox(height: 16),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Shopping'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cart Items list grouped by retailer
                      const Text(
                        'Order Items',
                        style: TextStyle(color: AppTheme.darkGreen, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: groupedItems.keys.map((retailerName) {
                          final items = groupedItems[retailerName]!;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.store_rounded, color: AppTheme.deepLeafGreen, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      retailerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGreen),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20, color: AppTheme.softGray),
                                ...items.map((item) {
                                  final price = item.product['discount_price_per_unit'] != null
                                      ? double.parse(item.product['discount_price_per_unit'].toString())
                                      : double.parse(item.product['price_per_unit'].toString());
                                  final String? thumb = item.product['thumbnail_path'];
                                  final imageUrl = thumb != null ? ApiService.fileUrl(thumb) : null;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
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
                                                item.product['product_name'] ?? 'Product',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              _CartQuantitySelector(
                                                stockQuantity: double.tryParse(item.product['stock_quantity']?.toString() ?? '0') ?? 0.0,
                                                unitType: item.product['unit_type'] ?? 'kg',
                                                initialValue: item.quantity,
                                                onChanged: (newQty) {
                                                  setState(() {
                                                    item.quantity = newQty;
                                                  });
                                                  _updateDeliveryFee();
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'LKR ${(price * item.quantity).toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGreen),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              Cart.remove(item.product['id']);
                                            });
                                            _updateDeliveryFee();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      // Delivery Address Form
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.local_shipping_rounded, color: AppTheme.deepLeafGreen, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Delivery Shipping Details',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: AppTheme.softGray),
                            const Text('Delivery Address', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Enter street name, city, apartment details...',
                                fillColor: AppTheme.softGray,
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _latitude != null && _longitude != null
                                      ? 'Pinned: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                                      : 'No pin pinned. Default delivery fee will apply.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _latitude != null ? AppTheme.darkGreen : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: _isLocating
                                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.gps_fixed_rounded, color: AppTheme.deepLeafGreen, size: 18),
                                      onPressed: _isLocating ? null : _useGPS,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.map_rounded, color: AppTheme.deepLeafGreen, size: 18),
                                      onPressed: _openMapPicker,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 120,
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey[200] ?? Colors.grey)),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(target: initialTarget, zoom: _latitude != null ? 15 : 7),
                                  markers: _latitude != null && _longitude != null
                                      ? {
                                          Marker(
                                            markerId: const MarkerId('checkout_delivery_loc'),
                                            position: LatLng(_latitude!, _longitude!),
                                          )
                                        }
                                      : {},
                                  onMapCreated: (controller) {
                                    _mapController = controller;
                                  },
                                  onTap: (coords) {
                                    if (!mounted) return;
                                    setState(() {
                                      _latitude = coords.latitude;
                                      _longitude = coords.longitude;
                                    });
                                    try {
                                      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(coords, 15));
                                    } catch (e) {
                                      // Fail silently
                                    }
                                    _updateDeliveryFee();
                                  },
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Order Summary card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Cart Subtotal', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                Text('LKR ${Cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (_isCalculatingDelivery)
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Delivery Fee', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.deepLeafGreen),
                                  ),
                                ],
                              )
                            else if (_deliveryFee != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Delivery Fee (${_deliveryDistance?.toStringAsFixed(1) ?? '0'} km @ LKR ${_ratePerKm?.toStringAsFixed(0) ?? '100'}/km)',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  Text('LKR ${_deliveryFee!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (_deliveryWeight != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Order Weight', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text('${_deliveryWeight!.toStringAsFixed(2)} kg', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                            ] else
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Delivery Fee', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  Text('Pin location to calculate', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.orange)),
                                ],
                              ),
                            const Divider(height: 20, color: AppTheme.softGray),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _deliveryFee != null ? 'Grand Total' : 'Total Cost (excl. delivery)',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                                ),
                                Text(
                                  'LKR ${(Cart.total + (_deliveryFee ?? 0.0)).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Checkout button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        onPressed: _checkout,
                        child: const Text('Place Split Orders Now'),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}

class _CartQuantitySelector extends StatefulWidget {
  final double stockQuantity;
  final String unitType;
  final double initialValue;
  final ValueChanged<double> onChanged;

  const _CartQuantitySelector({
    required this.stockQuantity,
    required this.unitType,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_CartQuantitySelector> createState() => _CartQuantitySelectorState();
}

class _CartQuantitySelectorState extends State<_CartQuantitySelector> {
  late TextEditingController _controller;
  late double _currentVal;

  @override
  void initState() {
    super.initState();
    _currentVal = widget.initialValue;
    _controller = TextEditingController(text: _formatValue(_currentVal));
  }

  @override
  void didUpdateWidget(_CartQuantitySelector oldWidget) {
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
          icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.deepLeafGreen, size: 18),
          onPressed: () {
            _updateVal(_currentVal - 1.0);
          },
        ),
        const SizedBox(width: 4),
        Container(
          width: 38,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300] ?? Colors.grey),
          ),
          child: Text(
            _formatValue(_currentVal),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.deepLeafGreen, size: 18),
          onPressed: () {
            _updateVal(_currentVal + 1.0);
          },
        ),
        const SizedBox(width: 4),
        Text(
          widget.unitType,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}

