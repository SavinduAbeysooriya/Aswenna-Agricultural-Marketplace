import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';

class RetailerCampaignsScreen extends StatefulWidget {
  const RetailerCampaignsScreen({super.key});

  @override
  State<RetailerCampaignsScreen> createState() => _RetailerCampaignsScreenState();
}

class _RetailerCampaignsScreenState extends State<RetailerCampaignsScreen> {
  List<dynamic> _campaigns = [];
  bool _isLoading = true;

  final _titleController = TextEditingController(text: 'Weekend Harvest Festival');
  final _discountController = TextEditingController(text: '15');
  final _categoryController = TextEditingController(text: 'Fresh Vegetables');
  final _durationController = TextEditingController(text: '3');
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _discountController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCampaigns() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getRetailerCampaigns();
      if (res['success'] == true && mounted) {
        setState(() {
          _campaigns = List<dynamic>.from(res['campaigns'] ?? []);
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitNewCampaign() async {
    final title = _titleController.text.trim();
    final discount = double.tryParse(_discountController.text.trim()) ?? 15.0;
    final category = _categoryController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 3;

    setState(() => _isCreating = true);

    try {
      final res = await ApiService.createRetailerCampaign(
        title: title.isEmpty ? 'Weekend Harvest Festival' : title,
        discountPercentage: discount,
        targetCategory: category.isEmpty ? 'Fresh Vegetables' : category,
        durationDays: duration,
      );

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Campaign recorded with status pending_admin_approval and a scheduled promotional banner preview displayed.'),
              backgroundColor: AppTheme.deepLeafGreen,
            ),
          );
          _fetchCampaigns();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to create campaign.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Flash Sales & Promos'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.deepLeafGreen),
            tooltip: 'Refresh',
            onPressed: _fetchCampaigns,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.deepLeafGreen,
        onRefresh: _fetchCampaigns,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Create Campaign Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.deepLeafGreen.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_circle_outline_rounded, color: AppTheme.deepLeafGreen, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Create Flash Sale Promo (RET-002)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Campaign Title',
                        hintText: 'e.g. Weekend Harvest Festival',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Discount %',
                              suffixText: '% OFF',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Duration (Days)',
                              suffixText: 'Days',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: 'Target Category',
                        hintText: 'e.g. Fresh Vegetables',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deepLeafGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                        ),
                        onPressed: _isCreating ? null : _submitNewCampaign,
                        child: _isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Create Flash Sale Campaign',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Promotional Campaigns List',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                  ),
                  Text(
                    '${_campaigns.length} Campaigns',
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppTheme.deepLeafGreen),
                  ),
                )
              else if (_campaigns.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Center(
                    child: Text('No promotional offer campaigns recorded yet.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ),
                )
              else
                ..._campaigns.map((c) {
                  final title = c['title']?.toString() ?? 'Weekend Harvest Festival';
                  final discount = c['discount_percentage']?.toString() ?? '15';
                  final category = c['target_category']?.toString() ?? 'Fresh Vegetables';
                  final status = c['status']?.toString() ?? 'pending_admin_approval';
                  final code = c['code']?.toString() ?? 'WEEKEND-HARVEST-15';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.deepLeafGreen.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(color: AppTheme.deepLeafGreen.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.lightMint, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.local_offer_rounded, color: AppTheme.deepLeafGreen, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Code: #$code • Category: $category', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Text(
                                '$discount% OFF Flash Sale • Scheduled Preview',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.deepLeafGreen),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
