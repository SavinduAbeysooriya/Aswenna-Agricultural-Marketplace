import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryProfileViewScreen extends StatefulWidget {
  final int partnerId;
  final String partnerName;

  const DeliveryProfileViewScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<DeliveryProfileViewScreen> createState() => _DeliveryProfileViewScreenState();
}

class _DeliveryProfileViewScreenState extends State<DeliveryProfileViewScreen> {
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
      final res = await ApiService.getUserProfilePublic(widget.partnerId);
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
    final deliveryVerification = _profileData['delivery_verification'] ?? {};
    final List<dynamic> reviews = _profileData['reviews'] ?? [];
    final avgRating = _profileData['avg_rating'] ?? 5.0;
    final totalCount = _profileData['total_count'] ?? 0;

    final profilePic = user['profile_picture_path']?.toString();
    final profilePicUrl = profilePic != null && profilePic.isNotEmpty
        ? (profilePic.startsWith('http') ? profilePic : '${ApiService.appUrl}/storage/$profilePic')
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: Text('${widget.partnerName}\'s Profile', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                              user['full_name'] ?? widget.partnerName,
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
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ...List.generate(5, (index) {
                                  final double starVal = index + 1.0;
                                  return Icon(
                                    starVal <= avgRating
                                        ? Icons.star_rounded
                                        : (starVal - 0.5 <= avgRating
                                            ? Icons.star_half_rounded
                                            : Icons.star_outline_rounded),
                                    color: AppTheme.accentGold,
                                    size: 20,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  '$avgRating ($totalCount Reviews)',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                            if (user['phone_number'] != null) ...[
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 180,
                                height: 40,
                                child: ElevatedButton.icon(
                                  onPressed: () => _makeCall(user['phone_number']),
                                  icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                                  label: const Text('Call Rider Courier', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
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

                      // Verification Details Card
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
                            const Text('Verification & Courier Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.description_rounded, 'Driving License No.', deliveryVerification['driving_license_number'] ?? 'Verified'),
                            _buildInfoRow(Icons.motorcycle_rounded, 'Vehicle Type', deliveryVerification['vehicle_type'] ?? 'Motorbike'),
                            _buildInfoRow(Icons.local_shipping_rounded, 'Vehicle Plate No.', deliveryVerification['vehicle_plate_number'] ?? 'Registered'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                       // Reviews List Section
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           const Text(
                             'Rider Reviews',
                             style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                           ),
                           Row(
                             children: [
                               const Icon(Icons.star_rounded, color: AppTheme.accentGold, size: 18),
                               const SizedBox(width: 4),
                               Text(
                                 avgRating.toStringAsFixed(1),
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                               ),
                               Text(
                                 ' ($totalCount)',
                                 style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                               ),
                             ],
                           ),
                         ],
                       ),
                       const SizedBox(height: 10),
                       // Quick Direct Review Form
                       Builder(
                         builder: (context) {
                           final eligibleList = _profileData['eligible_orders'] as List? ?? [];
                           final reviewedIds = _profileData['reviewed_order_ids'] as List? ?? [];
                           // Filter orders that haven't been reviewed yet
                           final pendingOrders = eligibleList.where((o) => !reviewedIds.contains(o['id'])).toList();

                           if (pendingOrders.isEmpty) {
                             return const Padding(
                               padding: EdgeInsets.only(bottom: 20),
                               child: Text(
                                 'You can only review this rider after placing an order delivered by them.',
                                 style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                               ),
                             );
                           }

                           int localRating = 5;
                           int? selectedOrderId = pendingOrders.first['id'] as int?;
                           final localFeedbackController = TextEditingController();

                           return StatefulBuilder(
                             builder: (context, setReviewState) {
                               return Container(
                                 margin: const EdgeInsets.only(bottom: 20),
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   color: Colors.white,
                                   borderRadius: BorderRadius.circular(16),
                                   border: Border.all(color: const Color(0xFFE2E8F0)),
                                 ),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     const Text('Write a Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                     const SizedBox(height: 10),
                                     const Text('Select Order:', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                     const SizedBox(height: 4),
                                     Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 10),
                                       decoration: BoxDecoration(
                                         color: Colors.white,
                                         borderRadius: BorderRadius.circular(8),
                                         border: Border.all(color: Colors.grey[300] ?? Colors.grey),
                                       ),
                                       child: DropdownButtonHideUnderline(
                                         child: DropdownButton<int>(
                                           value: selectedOrderId,
                                           isExpanded: true,
                                           style: const TextStyle(fontSize: 12, color: Colors.black87),
                                           items: pendingOrders.map((o) {
                                             return DropdownMenuItem<int>(
                                               value: o['id'] as int,
                                               child: Text(o['order_number']?.toString() ?? 'Order #${o['id']}'),
                                             );
                                           }).toList(),
                                           onChanged: (val) {
                                             setReviewState(() {
                                               selectedOrderId = val;
                                             });
                                           },
                                         ),
                                       ),
                                     ),
                                     const SizedBox(height: 10),
                                     Row(
                                       children: List.generate(5, (index) {
                                         final star = index + 1;
                                         return GestureDetector(
                                           onTap: () {
                                             setReviewState(() {
                                               localRating = star;
                                             });
                                           },
                                           child: Padding(
                                             padding: const EdgeInsets.only(right: 4.0),
                                             child: Icon(
                                               Icons.star_rounded,
                                               color: star <= localRating ? AppTheme.accentGold : Colors.grey[300],
                                               size: 24,
                                             ),
                                           ),
                                         );
                                       }),
                                     ),
                                     const SizedBox(height: 8),
                                     TextField(
                                       controller: localFeedbackController,
                                       decoration: const InputDecoration(
                                         hintText: 'Share your experience with this rider...',
                                         hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                                         border: InputBorder.none,
                                       ),
                                       maxLines: 2,
                                       style: const TextStyle(fontSize: 12),
                                     ),
                                     const SizedBox(height: 8),
                                     Align(
                                       alignment: Alignment.bottomRight,
                                       child: ElevatedButton(
                                         onPressed: () async {
                                           if (localFeedbackController.text.trim().isEmpty) {
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               const SnackBar(content: Text('Please enter your feedback text.')),
                                             );
                                             return;
                                           }
                                           if (selectedOrderId == null) return;

                                           final res = await ApiService.submitOrderReview(
                                             orderId: selectedOrderId!,
                                             reviewedTo: widget.partnerId,
                                             ratings: localRating,
                                             feedback: localFeedbackController.text.trim(),
                                           );
                                           if (res['success'] == true) {
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               const SnackBar(content: Text('Review submitted successfully!')),
                                             );
                                             localFeedbackController.clear();
                                             _fetchProfile();
                                           } else {
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(content: Text(res['message'] ?? 'Failed to submit review.')),
                                             );
                                           }
                                         },
                                         style: ElevatedButton.styleFrom(
                                           backgroundColor: AppTheme.deepLeafGreen,
                                           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                           minimumSize: const Size(0, 0),
                                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                         ),
                                         child: const Text('Submit', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                       ),
                                     ),
                                   ],
                                 ),
                               );
                             },
                           );
                         }
                       ),
                       const Divider(height: 8),

                      if (reviews.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_outlined, color: Colors.grey[300], size: 40),
                              const SizedBox(height: 12),
                              Text('No reviews yet for this delivery partner.', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            final double rating = double.tryParse(review['ratings']?.toString() ?? '5.0') ?? 5.0;
                            final reviewerName = review['reviewer_name']?.toString() ?? 'Aswenna User';
                            final photo = review['reviewer_photo']?.toString();
                            final photoUrl = photo != null && photo.isNotEmpty
                                ? (photo.startsWith('http') ? photo : '${ApiService.appUrl}/storage/$photo')
                                : null;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.01),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppTheme.lightMint,
                                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                        child: photoUrl == null
                                            ? Text(
                                                reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'U',
                                                style: const TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold, fontSize: 11),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(reviewerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: List.generate(5, (starIdx) {
                                                return Icon(
                                                  starIdx < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                                  color: AppTheme.accentGold,
                                                  size: 14,
                                                );
                                              }),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (review['feedback'] != null && review['feedback'].toString().trim().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      review['feedback'],
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                                    ),
                                  ]
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
        children: [
          Icon(icon, size: 16, color: AppTheme.deepLeafGreen),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
