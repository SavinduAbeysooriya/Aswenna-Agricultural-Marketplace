import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';

class RetailPaymentScreen extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> order;

  const RetailPaymentScreen({
    super.key,
    required this.orderId,
    required this.order,
  });

  @override
  State<RetailPaymentScreen> createState() => _RetailPaymentScreenState();
}

class _RetailPaymentScreenState extends State<RetailPaymentScreen> {
  bool _isInitiating = false;
  bool _showWebView = false;
  bool _paymentDone = false;
  Map<String, dynamic> _paymentParams = {};
  WebViewController? _webViewController;

  double get _baseAmount => double.tryParse(widget.order['total_amount']?.toString() ?? '0') ?? 0;
  double get _subtotal => double.tryParse(widget.order['subtotal_amount']?.toString() ?? '0') ?? 0;
  double get _deliveryFee => double.tryParse(widget.order['delivery_fee']?.toString() ?? '0') ?? 0;

  double get _serviceCharge => double.parse((_baseAmount * 0.02).toStringAsFixed(2));
  double get _tax => double.parse((_baseAmount * 0.015).toStringAsFixed(2));
  double get _grandTotal => _baseAmount + _serviceCharge + _tax;

  @override
  Widget build(BuildContext context) {
    if (_showWebView && _paymentParams.isNotEmpty) {
      return _buildPayHereWebView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text('Complete Order Payment'),
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
    final orderNumber = widget.order['order_number'] ?? 'Order';
    final paymentStatus = widget.order['payment_status'] ?? 'pending';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (paymentStatus == 'paid')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
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
                const Text('Retail Order Summary',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                _summaryRow(Icons.receipt_rounded, 'Order Reference', orderNumber),
                _summaryRow(Icons.shopping_bag_rounded, 'Items Subtotal', 'LKR ${_subtotal.toStringAsFixed(2)}'),
                _summaryRow(Icons.local_shipping_rounded, 'Delivery Fee', 'LKR ${_deliveryFee.toStringAsFixed(2)}'),
                _summaryRow(Icons.percent_rounded, 'Processing Fee (2%)', 'LKR ${_serviceCharge.toStringAsFixed(2)}'),
                _summaryRow(Icons.gavel_rounded, 'Tax (1.5%)', 'LKR ${_tax.toStringAsFixed(2)}'),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Text(
                      'LKR ${_grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.deepLeafGreen),
                    ),
                  ],
                ),
              ],
            ),
          ),


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
        border: Border.all(color: Colors.grey[300] ?? Colors.grey),
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFF8F8F8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
    );
  }

  Future<void> _initiatePayment() async {
    setState(() => _isInitiating = true);
    final result = await ApiService.initiateRetailOrderPayment(widget.orderId);
    if (!mounted) return;
    setState(() => _isInitiating = false);

    if (result['success'] == true) {
      final backendParams = Map<String, dynamic>.from(result['payment_params'] ?? {});
      final pricingBreakdown = result['pricing_breakdown'] ?? {};

      // Hardcoded sandbox credentials
      const String merchantId = '1236086';
      const String merchantSecret = 'MzYxNDQ1ODY3MjM2NTc4MDk3MDkyNDIyMDI0MTE5MzA0NTMxNjQxOQ==';
      const String currency = 'LKR';

      final String orderId = backendParams['order_id'] ?? 'RETAIL-${widget.orderId}-${DateTime.now().millisecondsSinceEpoch}';
      final double finalAmount = double.tryParse(pricingBreakdown['final_amount']?.toString() ?? backendParams['amount']?.toString() ?? '0') ?? _grandTotal;
      final String amountStr = finalAmount.toStringAsFixed(2);

      final Map<String, dynamic> paymentObject = {
        "sandbox": true,
        "merchant_id": backendParams['merchant_id'] ?? merchantId,
        "hash": backendParams['hash'],   // Secure backend-generated hash
        "notify_url": backendParams['notify_url'] ?? '',
        "order_id": backendParams['order_id'] ?? orderId,
        "items": backendParams['items'] ?? 'Retail Order',
        "amount": backendParams['amount'] ?? amountStr,
        "currency": backendParams['currency'] ?? currency,
        "first_name": backendParams['first_name'] ?? 'Customer',
        "last_name": backendParams['last_name'] ?? 'Aswenna',
        "email": backendParams['email'] ?? 'customer@aswenna.lk',
        "phone": backendParams['phone'] ?? '0771234567',
        "address": backendParams['address'] ?? 'Sri Lanka',
        "city": backendParams['city'] ?? 'Colombo',
        "country": 'Sri Lanka',
      };

      PayHere.startPayment(
        paymentObject,
        (paymentId) async {
          setState(() => _isInitiating = true);
          final recordResult = await ApiService.confirmRetailOrderPaymentSuccess(widget.orderId, paymentId);
          if (!mounted) return;
          setState(() => _isInitiating = false);

          if (recordResult['success'] == true) {
            _handlePaymentCallback(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(recordResult['message'] ?? 'Failed to record transaction.'),
                backgroundColor: Colors.red,
              ),
            );
            _handlePaymentCallback(false);
          }
        },
        (error) {
          debugPrint("One Time Payment Failed. Error: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('One Time Payment Failed. Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
          _handlePaymentCallback(false);
        },
        () {
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
    final Map<String, dynamic> params = Map<String, dynamic>.from(_paymentParams);
    params.remove('sandbox');
    params.remove('customer_order_id');
    
    if (params['last_name'] == null || params['last_name'].toString().trim().isEmpty) {
      params['last_name'] = 'Customer';
    }

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
          content: Text('Payment failed or cancelled.'),
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
              decoration: const BoxDecoration(
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
              'Your payment of LKR ${_grandTotal.toStringAsFixed(2)} has been processed. Wallet records have been updated.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepLeafGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Proceed',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
