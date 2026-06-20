import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final res = await ApiService.getNotifications();
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _notifications = List<dynamic>.from(res['notifications'] ?? []);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Failed to load notifications.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead({int? id}) async {
    final res = await ApiService.markNotificationsRead(id: id);
    if (res['success'] == true) {
      _fetchNotifications();
    }
  }

  Widget _buildTypeIcon(String type) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'market_rate':
        iconData = Icons.analytics_rounded;
        iconColor = Colors.orange;
        bgColor = Colors.orange.shade50;
        break;
      case 'bid':
        iconData = Icons.gavel_rounded;
        iconColor = Colors.blue;
        bgColor = Colors.blue.shade50;
        break;
      case 'payment':
        iconData = Icons.account_balance_wallet_rounded;
        iconColor = Colors.purple;
        bgColor = Colors.purple.shade50;
        break;
      default:
        iconData = Icons.notifications_rounded;
        iconColor = AppTheme.deepLeafGreen;
        bgColor = AppTheme.lightMint;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => n['read_at'] == null))
            TextButton.icon(
              onPressed: () => _markRead(),
              icon: const Icon(Icons.done_all_rounded, size: 16, color: AppTheme.deepLeafGreen),
              label: const Text(
                'Mark all read',
                style: TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppTheme.deepLeafGreen,
                      onRefresh: _fetchNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final n = Map<String, dynamic>.from(_notifications[index] as Map);
                          final isUnread = n['read_at'] == null;
                          final dateStr = n['created_at']?.toString() ?? '';
                          final formattedDate = dateStr.isNotEmpty
                              ? DateFormat('MMMM dd, hh:mm a').format(DateTime.parse(dateStr))
                              : '';

                          return Container(
                            decoration: BoxDecoration(
                              color: isUnread ? Colors.white : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isUnread ? AppTheme.deepLeafGreen.withOpacity(0.15) : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: isUnread ? () => _markRead(id: n['id']) : null,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTypeIcon(n['type'] ?? 'general'),
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
                                                  n['title'] ?? 'Alert',
                                                  style: TextStyle(
                                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                    fontSize: 14,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              if (isUnread)
                                                Container(
                                                  height: 8,
                                                  width: 8,
                                                  decoration: const BoxDecoration(
                                                    color: AppTheme.deepLeafGreen,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            n['message'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: isUnread ? const Color(0xFF334155) : const Color(0xFF64748B),
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.bold,
                                            ),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.lightMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.deepLeafGreen),
            ),
            const SizedBox(height: 20),
            const Text(
              'No new alerts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'We will notify you about crop rate updates, placed bids, and transaction confirmations here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
