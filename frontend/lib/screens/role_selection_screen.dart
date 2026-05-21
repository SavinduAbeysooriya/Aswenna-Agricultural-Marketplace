import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/registration_screen.dart';
import 'package:aswenna/screens/password_setup_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

const String _googleServerClientId =
    '365861807638-qouuf7mif5qa6j64jnpvm09c1ikbp4hr.apps.googleusercontent.com';
const String _googleIosClientId = _googleServerClientId;

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
      'description':
          'Purchase agricultural items directly for household consumption.',
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
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
                            color: isSelected
                                ? AppTheme.freshGreen
                                : Colors.transparent,
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
                                      color: isSelected
                                          ? AppTheme.deepLeafGreen
                                          : const Color(0xFF0F172A),
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
                                color: isSelected
                                    ? AppTheme.freshGreen
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.freshGreen
                                      : const Color(0xFFCBD5E1),
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RegistrationScreen(
                              role: _selectedRole!,
                              registrationData: widget.registrationData,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedRole == null
                      ? const Color(0xFFCBD5E1)
                      : AppTheme.deepLeafGreen,
                  foregroundColor: _selectedRole == null
                      ? const Color(0xFF94A3B8)
                      : AppTheme.pureWhite,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  elevation: _selectedRole == null ? 0 : 6,
                  shadowColor: AppTheme.deepLeafGreen.withOpacity(0.3),
                ),
                child: const Text('Continue'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _handleGoogleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shadowColor: Colors.black12,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'G',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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
  }

  void _handleGoogleSignUp() async {
    bool loaderShown = false;
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: Platform.isIOS ? _googleIosClientId : null,
        serverClientId: _googleServerClientId,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
          ),
        ),
      );
      loaderShown = true;

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      if (mounted && loaderShown) {
        Navigator.of(context).pop();
        loaderShown = false;
      }

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PasswordSetupScreen(
              email: googleUser.email,
              googleName: googleUser.displayName ?? '',
            ),
          ),
        );
      }
    } on GoogleSignInException catch (error) {
      if (mounted && loaderShown) {
        Navigator.of(context).pop();
        loaderShown = false;
      }
      debugPrint('Google Sign-Up failed: $error');
      if (error.code == GoogleSignInExceptionCode.canceled) {
        if (mounted && _looksLikeAndroidReauthFailure(error)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Google Sign-In is not configured correctly for this Android app. Check the SHA fingerprint and google-services.json.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_googleSignInMessage(error)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted && loaderShown) {
        Navigator.of(context).pop();
        loaderShown = false;
      }
      debugPrint('Google Sign-Up failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _googleSignInMessage(GoogleSignInException error) {
    if (error.code == GoogleSignInExceptionCode.clientConfigurationError) {
      return 'Google Sign-In is not configured for this device yet.';
    }
    return 'Google Sign-In failed. Please try again.';
  }

  bool _looksLikeAndroidReauthFailure(GoogleSignInException error) {
    return Platform.isAndroid &&
        (error.description?.contains('Account reauth failed') ?? false);
  }
}
