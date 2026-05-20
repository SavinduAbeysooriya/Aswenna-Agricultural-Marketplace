import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/registration_screen.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/dashboards/farmer_dashboard.dart';
import 'package:aswenna/screens/dashboards/buyer_dashboard.dart';
import 'package:aswenna/screens/dashboards/retailer_dashboard.dart';
import 'package:aswenna/screens/dashboards/delivery_dashboard.dart';
import 'package:aswenna/screens/dashboards/customer_dashboard.dart';

class RoleSelectionScreen extends StatefulWidget {
  final Map<String, String>? registrationData;

  const RoleSelectionScreen({super.key, this.registrationData});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'farmer',
      'title': 'Farmer',
      'description': 'Sell fresh crops & bid harvest listings directly.',
      'icon': Icons.agriculture_rounded,
      'color': AppTheme.deepLeafGreen,
      'bgColor': AppTheme.lightMint,
    },
    {
      'id': 'buyer',
      'title': 'Buyer',
      'description': 'Purchase high-quality bulk yields from farmers.',
      'icon': Icons.shopping_basket_rounded,
      'color': Colors.blue[700],
      'bgColor': const Color(0xFFE3F2FD),
    },
    {
      'id': 'retail_seller',
      'title': 'Retail Seller',
      'description': 'List consumer agricultural products & seeds.',
      'icon': Icons.storefront_rounded,
      'color': AppTheme.accentGold,
      'bgColor': const Color(0xFFFFF8E1),
    },
    {
      'id': 'delivery_partner',
      'title': 'Delivery Partner',
      'description': 'Fulfill orders & earn money driving logistics.',
      'icon': Icons.local_shipping_rounded,
      'color': Colors.purple[700],
      'bgColor': const Color(0xFFF3E5F5),
    },
    {
      'id': 'customer',
      'title': 'Customer',
      'description': 'Purchase agricultural items directly for household consumption.',
      'icon': Icons.person_pin_rounded,
      'color': const Color(0xFFBE123C), // Rose-700
      'bgColor': const Color(0xFFFFEBEE),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Account Setup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 1 of 3',
                style: TextStyle(
                  color: AppTheme.freshGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Who are you?',
                style: TextStyle(
                  color: AppTheme.darkGreen,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your active workspace profile to continue. This configuration customizes your workflow dashboards.',
                style: TextStyle(
                  color: Color(0xFF64748B), // Slate-500 equivalent
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // Role List Cards Builder
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _roles.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRole == role['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRole = role['id'];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? AppTheme.freshGreen : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? AppTheme.freshGreen.withOpacity(0.12)
                                  : AppTheme.deepLeafGreen.withOpacity(0.04),
                              blurRadius: isSelected ? 20 : 10,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Beautiful Role Icon circle
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: role['bgColor'],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                role['icon'],
                                color: role['color'],
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 18),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role['title'],
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.deepLeafGreen : const Color(0xFF0F172A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    role['description'],
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Selected Checkmark status indicator
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppTheme.freshGreen : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppTheme.freshGreen : const Color(0xFFCBD5E1),
                                  width: 2.0,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: AppTheme.pureWhite,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Continue button
              ElevatedButton(
                onPressed: _selectedRole == null
                    ? null
                    : () {
                        if (widget.registrationData != null) {
                          _completeGoogleRegistration();
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RegistrationScreen(role: _selectedRole!),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedRole == null ? const Color(0xFFCBD5E1) : AppTheme.deepLeafGreen,
                  foregroundColor: _selectedRole == null ? const Color(0xFF94A3B8) : AppTheme.pureWhite,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  elevation: _selectedRole == null ? 0 : 6,
                  shadowColor: AppTheme.deepLeafGreen.withOpacity(0.3),
                ),
                child: Text(widget.registrationData != null ? 'Complete Registration' : 'Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completeGoogleRegistration() async {
    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
        ),
      ),
    );

    // Call API
    final result = await ApiService.googleRegisterUser(
      email: widget.registrationData!['email']!,
      password: widget.registrationData!['password']!,
      role: _selectedRole!,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss spinner
      
      if (result['success'] == true) {
        Widget targetDashboard;
        switch (_selectedRole) {
          case 'farmer':
            targetDashboard = const FarmerDashboard();
            break;
          case 'buyer':
            targetDashboard = const BuyerDashboard();
            break;
          case 'retail_seller':
            targetDashboard = const RetailerDashboard();
            break;
          case 'delivery_partner':
            targetDashboard = const DeliveryDashboard();
            break;
          case 'customer':
          default:
            targetDashboard = const CustomerDashboard();
            break;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => targetDashboard),
          (route) => false,
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Registration Failed'),
              ],
            ),
            content: Text(result['message'] ?? 'Failed to complete registration.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }
}
