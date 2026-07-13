import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';

class RetailerWalletScreen extends StatefulWidget {
  const RetailerWalletScreen({Key? key}) : super(key: key);

  @override
  State<RetailerWalletScreen> createState() => _RetailerWalletScreenState();
}

class _RetailerWalletScreenState extends State<RetailerWalletScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _wallet;
  List<dynamic> _walletTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletDetails();
  }

  Future<void> _loadWalletDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getWalletDetails();
      if (result['success'] == true) {
        setState(() {
          _wallet = Map<String, dynamic>.from(result['wallet'] ?? {});
          _walletTransactions = List<dynamic>.from(result['transactions'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load wallet data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String availableBalance = double.tryParse(_wallet?['available_balance']?.toString() ?? '0')
            ?.toStringAsFixed(2) ?? '0.00';
    final String pendingBalance = double.tryParse(_wallet?['pending_balance']?.toString() ?? '0')
            ?.toStringAsFixed(2) ?? '0.00';
    final String totalEarned = double.tryParse(_wallet?['total_earned']?.toString() ?? '0')
            ?.toStringAsFixed(2) ?? '0.00';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Retail Wallet',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: AppTheme.deepLeafGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWalletDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadWalletDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWalletDetails,
                  color: AppTheme.deepLeafGreen,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AVAILABLE BALANCE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'LKR $availableBalance',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PENDING ESCROW',
                                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'LKR $pendingBalance',
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TOTAL EARNED',
                                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'LKR $totalEarned',
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: double.parse(availableBalance) >= 100
                              ? () => _showWithdrawalSheet(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.account_balance_rounded, color: Colors.white),
                          label: const Text(
                            'Request Payout Payout',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Transactions List Title
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_walletTransactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No transactions yet',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _walletTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = _walletTransactions[index];
                            final double amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
                            final String desc = tx['description']?.toString() ?? 'Transaction';
                            final String dateStr = tx['created_at']?.toString() ?? '';
                            final isIncome = amount > 0;
                            final displayAmount = (isIncome ? '+' : '') + ' LKR ' + amount.abs().toStringAsFixed(2);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isIncome ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                      color: isIncome ? AppTheme.deepLeafGreen : Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          desc,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dateStr.split(' ')[0],
                                          style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    displayAmount,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: isIncome ? AppTheme.deepLeafGreen : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }

  void _showWithdrawalSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final bankNameController = TextEditingController();
    final bankBranchController = TextEditingController();
    final holderController = TextEditingController();
    final numberController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
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
                      const Text(
                        'Request Bank Withdrawal',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Funds will be transferred to your bank account upon approval.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),

                      // Amount Field
                      const Text(
                        'AMOUNT (LKR)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Minimum LKR 100.00',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter amount';
                          final amt = double.tryParse(val.trim());
                          if (amt == null) return 'Enter a valid number';
                          if (amt < 100) return 'Minimum withdrawal is LKR 100.00';
                          final avail = double.tryParse(_wallet?['available_balance']?.toString() ?? '0') ?? 0.0;
                          if (amt > avail) return 'Insufficient available balance';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Bank Name Field
                      const Text(
                        'BANK NAME',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: bankNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'e.g. Bank of Ceylon',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter bank name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Bank Branch Field
                      const Text(
                        'BANK BRANCH',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: bankBranchController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'e.g. Maharagama',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter bank branch' : null,
                      ),
                      const SizedBox(height: 16),

                      // Account Holder Name Field
                      const Text(
                        'ACCOUNT HOLDER NAME',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: holderController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Name as in bank account',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter account holder name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Account Number Field
                      const Text(
                        'ACCOUNT NUMBER',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter account number',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter account number' : null,
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    setSheetState(() => isSubmitting = true);
                                    
                                    final amt = double.parse(amountController.text.trim());
                                    final result = await ApiService.requestWithdrawal(
                                      amount: amt,
                                      bankName: bankNameController.text.trim(),
                                      bankBranch: bankBranchController.text.trim(),
                                      bankAccountHolderName: holderController.text.trim(),
                                      bankAccountNumber: numberController.text.trim(),
                                    );

                                    if (mounted) {
                                      Navigator.pop(context); // close bottom sheet
                                      
                                      if (result['success'] == true) {
                                        _loadWalletDetails();
                                        
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            title: const Text('✅ Payout Requested', style: TextStyle(fontWeight: FontWeight.w800)),
                                            content: const Text(
                                              'Your withdrawal request has been submitted and is pending review by administrators.',
                                              style: TextStyle(color: Color(0xFF475569)),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('OK', style: TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('❌ ${result['message'] ?? 'Failed to submit withdrawal request.'}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Submit Payout Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        },
      );
    },
  );
  }
}
