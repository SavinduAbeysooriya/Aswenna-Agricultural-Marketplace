import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/review/review_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int confirmedBidId;
  final Map<String, dynamic> confirmedBid;

  const PaymentScreen({
    super.key,
    required this.confirmedBidId,
    required this.confirmedBid,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isInitiating = false;
  bool _showWebView = false;
  bool _paymentDone = false;
  Map<String, dynamic> _paymentParams = {};
  WebViewController? _webViewController;

  double get _totalAmount =>
      double.tryParse(widget.confirmedBid['total_amount']?.toString() ?? '0') ?? 0;

  @override
  Widget build(BuildContext context) {
    if (_showWebView && _paymentParams.isNotEmpty) {
      return _buildPayHereWebView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text('Complete Payment'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _paymentDone ? _buildPaymentSuccess() : _buildPaymentDetails(),
    );
  }

  Widget _buildPaymentDetails() {
    final cropname = widget.confirmedBid['cropname'] ?? 'Crop';
    final qty = widget.confirmedBid['bid_quantity_unit'] ?? '0';
    final unit = widget.confirmedBid['unit'] ?? 'kg';
    final rate = double.tryParse(widget.confirmedBid['bid_amount_per_unit']?.toString() ?? '0') ?? 0;
    final farmerName = widget.confirmedBid['farmer_name'] ?? 'Farmer';
    final paymentStatus = widget.confirmedBid['payment_status'] ?? 'unpaid';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Status Banner
          if (paymentStatus == 'paid')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.deepLeafGreen, AppTheme.darkGreen],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Payment Completed',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),

          // Order Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Summary',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                _summaryRow(Icons.local_florist_rounded, 'Crop', cropname),
                _summaryRow(Icons.person_rounded, 'Farmer', farmerName),
                _summaryRow(Icons.scale_rounded, 'Quantity', '$qty $unit'),
                _summaryRow(Icons.currency_rupee_rounded, 'Rate per unit', 'LKR ${rate.toStringAsFixed(2)}'),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Text(
                      'LKR ${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.deepLeafGreen),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Developer Sandbox Test Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bug_report_rounded, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('Developer Sandbox Simulator',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Launch a static test payment natively using default PayHere test credentials to verify SDK links work perfectly.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      final Map<String, dynamic> testObject = {
                        "sandbox": true,
                        "merchant_id": "1236086", // Your Merchant ID
                        "merchant_secret": "MjcwOTkzNTQ3Njk2NTU0MTIwNjQ4OTgwMzA0NjI4NDI0NzE4Njk=", // Your Mobile App Secret
                        "notify_url": "https://aswenna.lk/api/payment/notify",
                        "order_id": "TEST-${DateTime.now().millisecondsSinceEpoch}",
                        "items": "Direct Farm Purchase SDK Test",
                        "amount": "100.00",
                        "currency": "LKR",
                        "first_name": "Saman",
                        "last_name": "Perera",
                        "email": "samanp@gmail.com",
                        "phone": "0771234567",
                        "address": "No.1, Galle Road",
                        "city": "Colombo",
                        "country": "Sri Lanka",
                      };

                      PayHere.startPayment(
                        testObject,
                        (paymentId) async {
                          debugPrint("Static Test Success! Payment ID: $paymentId");
                          final recordResult = await ApiService.confirmPaymentSuccess(widget.confirmedBidId, paymentId);
                          if (recordResult['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Static Test Success & DB Recorded! ID: $paymentId'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _handlePaymentCallback(true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Static Test Success but DB failed: ' + (recordResult['message'] ?? '')),
                                backgroundColor: Colors.red,
                              ),
                            );
                            _handlePaymentCallback(false);
                          }
                        },
                        (error) {
                          debugPrint("Static Test Failed: $error");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Static Test Failed: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        () {
                          debugPrint("Static Test Dismissed");
                        }
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Launch Native SDK Sandbox Test'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PayHere Info Card
          Container(

            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: AppTheme.deepLeafGreen, size: 20),
                    SizedBox(width: 8),
                    Text('Secure Payment via PayHere',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your payment is secured by PayHere, Sri Lanka\'s leading payment gateway. Supports Visa, Mastercard, Amex, and online banking.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.5),
                ),
                const SizedBox(height: 16),
                // Payment method icons
                Row(
                  children: [
                    _payMethodChip('VISA'),
                    const SizedBox(width: 8),
                    _payMethodChip('MASTER'),
                    const SizedBox(width: 8),
                    _payMethodChip('AMEX'),
                    const SizedBox(width: 8),
                    _payMethodChip('eZCash'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Pay Now button
          if (paymentStatus != 'paid')
            _isInitiating
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
                : SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _initiatePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepLeafGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment_rounded, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Pay Now with PayHere',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  )
          else
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewScreen(
                      confirmedBidId: widget.confirmedBidId,
                      confirmedBid: widget.confirmedBid,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Leave a Review',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.deepLeafGreen),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _payMethodChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFF8F8F8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
    );
  }

  Future<void> _initiatePayment() async {
    setState(() => _isInitiating = true);
    final result = await ApiService.initiatePayment(widget.confirmedBidId);
    if (!mounted) return;
    setState(() => _isInitiating = false);

    if (result['success'] == true) {
      final backendParams = Map<String, dynamic>.from(result['payment_params'] ?? {});
      final pricingBreakdown = result['pricing_breakdown'] ?? {};

      // Hardcoded mobile App credentials
      const String merchantId = '1236086';
      const String merchantSecret = 'MjcwOTkzNTQ3Njk2NTU0MTIwNjQ4OTgwMzA0NjI4NDI0NzE4Njk=';
      const String currency = 'LKR';

      final String orderId = backendParams['order_id'] ?? 'ASWENNA-${widget.confirmedBidId}-${DateTime.now().millisecondsSinceEpoch}';
      
      // Calculate amount including service charge and tax
      final double finalAmount = double.tryParse(pricingBreakdown['final_amount']?.toString() ?? backendParams['amount']?.toString() ?? '0') ?? _totalAmount;
      final String amountStr = finalAmount.toStringAsFixed(2);

      final Map<String, dynamic> paymentObject = {
        "sandbox": true,                 // Use sandbox for testing
        "merchant_id": merchantId,
        "merchant_secret": merchantSecret,
        "notify_url": backendParams['notify_url'] ?? '',
        "order_id": orderId,
        "items": backendParams['items'] ?? 'Hello from Flutter!',
        "amount": amountStr,
        "currency": currency,
        "first_name": backendParams['first_name'] ?? 'Buyer',
        "last_name": backendParams['last_name'] ?? 'Aswenna',
        "email": backendParams['email'] ?? 'buyer@aswenna.lk',
        "phone": backendParams['phone'] ?? '0771234567',
        "address": backendParams['address'] ?? 'Sri Lanka',
        "city": backendParams['city'] ?? 'Colombo',
        "country": 'Sri Lanka',
      };

      // Trigger the official native PayHere Flutter Mobile SDK
      PayHere.startPayment(
        paymentObject,
        (paymentId) async {
          debugPrint("One Time Payment Success. Payment Id: $paymentId");
          setState(() {
            _isInitiating = true;
          });
          
          final recordResult = await ApiService.confirmPaymentSuccess(widget.confirmedBidId, paymentId);
          
          setState(() {
            _isInitiating = false;
          });

          if (recordResult['success'] == true) {
            _handlePaymentCallback(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(recordResult['message'] ?? 'Failed to record transaction in local database.'),
                backgroundColor: Colors.red,
              ),
            );
            _handlePaymentCallback(false);
          }
        },
        (error) {
          debugPrint("One Time Payment Failed. Error: $error");
          _handlePaymentCallback(false);
        },
        () {
          debugPrint("One Time Payment Dismissed");
          _handlePaymentCallback(false);
        }
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to initiate payment.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPayHereWebView() {
    // Build PayHere hosted checkout parameters, keeping only strict PayHere parameters
    final Map<String, dynamic> params = Map<String, dynamic>.from(_paymentParams);
    params.remove('sandbox');
    params.remove('confirmed_bid_id');
    
    // PayHere requires a non-empty last_name parameter
    if (params['last_name'] == null || params['last_name'].toString().trim().isEmpty) {
      params['last_name'] = 'Buyer';
    }

    // Generate an auto-submitting HTML form to execute a browser-level POST request
    final String htmlContent = '''
    <!DOCTYPE html>
    <html>
      <head>
        <title>Redirecting to PayHere...</title>
      </head>
      <body onload="document.forms['payhere_form'].submit();">
        <form name="payhere_form" action="https://sandbox.payhere.lk/pay/checkout" method="POST">
          ${params.entries.map((e) => '<input type="hidden" name="${e.key}" value="${e.value.toString().replaceAll('"', '&quot;')}" />').join('\n')}
        </form>
      </body>
    </html>
    ''';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (nav) {
          // Detect PayHere return URLs
          if (nav.url.contains('payment/return') || nav.url.contains('payment/cancel')) {
            final isSuccess = nav.url.contains('payment/return') && !nav.url.contains('cancel');
            _handlePaymentCallback(isSuccess);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadHtmlString(htmlContent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PayHere Checkout'),
        backgroundColor: AppTheme.deepLeafGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => setState(() => _showWebView = false),
        ),
      ),
      body: WebViewWidget(controller: controller),
    );
  }

  void _handlePaymentCallback(bool isSuccess) {
    setState(() => _showWebView = false);
    if (isSuccess) {
      setState(() => _paymentDone = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment was cancelled or failed. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildPaymentSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.deepLeafGreen, AppTheme.darkGreen],
                ),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Text(
              'Your payment of LKR ${_totalAmount.toStringAsFixed(2)} has been processed. The farmer will be notified.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewScreen(
                      confirmedBidId: widget.confirmedBidId,
                      confirmedBid: widget.confirmedBid,
                    ),
                  ),
                ),
                icon: const Icon(Icons.star_rounded, color: Colors.white),
                label: const Text('Leave a Review',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Back to Listings',
                  style: TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
