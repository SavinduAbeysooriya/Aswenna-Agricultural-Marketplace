import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyerProfileViewScreen extends StatefulWidget {
  final int buyerId;
  final String buyerName;

  const BuyerProfileViewScreen({
    super.key,
    required this.buyerId,
    required this.buyerName,
  });

  @override
  State<BuyerProfileViewScreen> createState() => _BuyerProfileViewScreenState();
}

class _BuyerProfileViewScreenState extends State<BuyerProfileViewScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await ApiService.getUserProfilePublic(widget.buyerId);
      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _profileData = Map<String, dynamic>.from(res['profile'] ?? {});
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = res['message'] ?? 'Failed to load profile details.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _profileData['user'] ?? {};
    final List<dynamic> reviews = _profileData['reviews'] ?? [];
    final avgRating = _profileData['avg_rating'] ?? 5.0;
    final totalCount = _profileData['total_count'] ?? 0;
    final List<dynamic> roles = user['roles'] is List ? user['roles'] : [];

    final profilePic = user['profile_picture_path']?.toString();
    final profilePicUrl = profilePic != null && profilePic.isNotEmpty
        ? (profilePic.startsWith('http') ? profilePic : '${ApiService.appUrl}/storage/$profilePic')
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: Text('${widget.buyerName}\'s Profile', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchProfile,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLeafGreen),
                          child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header info card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.lightMint, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.deepLeafGreen.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: profilePicUrl != null
                                    ? Image.network(profilePicUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildDefaultAvatar())
                                    : _buildDefaultAvatar(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user['full_name'] ?? widget.buyerName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppTheme.deepLeafGreen, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${user['city'] ?? 'Aswenna District'}, ${user['province'] ?? 'Sri Lanka'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.lightMint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                roles.contains('customer')
                                    ? 'CUSTOMER ACCOUNT'
                                    : (roles.contains('buyer') ? 'BUYER ACCOUNT' : 'USER ACCOUNT'),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.deepLeafGreen),
                              ),
                            ),
                            if (user['phone_number'] != null) ...[
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 160,
                                height: 40,
                                child: ElevatedButton.icon(
                                  onPressed: () => _makeCall(user['phone_number']),
                                  icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                                  label: const Text('Call Customer', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.deepLeafGreen,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Contact Info details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Contact Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.email_rounded, 'Email', user['email'] ?? 'Not Provided'),
                            _buildInfoRow(Icons.phone_rounded, 'Primary Contact', user['phone_number'] ?? 'Not Provided'),
                            _buildInfoRow(Icons.phone_android_rounded, 'Alternative Contact', user['phone_number_2'] ?? 'None'),
                            _buildInfoRow(Icons.map_rounded, 'Registered Address', user['address'] ?? 'Not Specified'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppTheme.lightMint,
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, color: AppTheme.deepLeafGreen, size: 48),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.deepLeafGreen),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
