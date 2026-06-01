import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/services/api_service.dart';

class ReviewScreen extends StatefulWidget {
  final int confirmedBidId;
  final Map<String, dynamic> confirmedBid;

  const ReviewScreen({
    super.key,
    required this.confirmedBidId,
    required this.confirmedBid,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ApiService.submitReview(
      widget.confirmedBidId,
      _rating,
      _feedbackController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      setState(() => _submitted = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit review.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text('Leave a Review'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _submitted ? _buildThankYou() : _buildReviewForm(),
    );
  }

  Widget _buildReviewForm() {
    final cropname = widget.confirmedBid['cropname'] ?? 'Crop';
    final farmerName = widget.confirmedBid['farmer_name'] ?? 'Farmer';
    final totalAmount = widget.confirmedBid['total_amount'] ?? '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deal summary header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.deepLeafGreen, AppTheme.darkGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rate Your Experience',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  cropname,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'From $farmerName · LKR $totalAmount',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Star rating card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'How was your experience?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  _rating == 0
                      ? 'Tap a star to rate'
                      : _ratingLabel(_rating),
                  style: TextStyle(
                    fontSize: 13,
                    color: _rating == 0 ? Colors.grey[400] : AppTheme.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIdx = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = starIdx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          starIdx <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: starIdx <= _rating ? AppTheme.accentGold : Colors.grey[300],
                          size: starIdx <= _rating ? 48 : 42,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Feedback text card
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
                const Text(
                  'Write Your Review (Optional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText:
                        'Share details about the crop quality, communication, delivery, etc.',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF4F6F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          _isSubmitting
              ? const Center(child: CircularProgressIndicator(color: AppTheme.deepLeafGreen))
              : SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _submitReview,
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: const Text(
                      'Submit Review',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rating == 0 ? Colors.grey : AppTheme.deepLeafGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return '⭐ Poor';
      case 2:
        return '⭐⭐ Fair';
      case 3:
        return '⭐⭐⭐ Good';
      case 4:
        return '⭐⭐⭐⭐ Very Good';
      case 5:
        return '⭐⭐⭐⭐⭐ Excellent!';
      default:
        return '';
    }
  }

  Widget _buildThankYou() {
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
                  colors: [AppTheme.accentGold, const Color(0xFFFF8F00)],
                ),
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'Thank You!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Text(
              'Your review has been submitted successfully. It helps build trust in the Aswenna marketplace!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
            ),
            const SizedBox(height: 32),
            // Star display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppTheme.accentGold,
                  size: 36,
                ),
              ),
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
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
