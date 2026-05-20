import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/role_selection_screen.dart';
import 'package:aswenna/screens/dashboards/farmer_dashboard.dart';
import 'package:aswenna/screens/dashboards/buyer_dashboard.dart';
import 'package:aswenna/screens/dashboards/retailer_dashboard.dart';
import 'package:aswenna/screens/dashboards/delivery_dashboard.dart';
import 'package:aswenna/screens/dashboards/customer_dashboard.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/password_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      body: Stack(
        children: [
          // Background organic blurs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.lightMint.withOpacity(0.5),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 24),
                  // Logo + Greeting
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.lightMint,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.eco_rounded,
                              size: 44,
                              color: AppTheme.deepLeafGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: AppTheme.darkGreen,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in to manage your marketplace',
                          style: TextStyle(
                            color: Color(0xFF64748B), // Slate-500 equivalent
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Login Inputs
                  TextFormField(
                    controller: _identifierController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number or Email',
                      prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppTheme.deepLeafGreen),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.deepLeafGreen),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.deepLeafGreen.withOpacity(0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppTheme.deepLeafGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Google Sign In Button
                  ElevatedButton(
                    onPressed: _handleGoogleSignIn,
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
                        // A simple text "G" for google logo if asset doesn't exist, or use a basic icon
                        Text('G', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(width: 12),
                        const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Sign In Action
                  ElevatedButton(
                    onPressed: _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepLeafGreen,
                      shadowColor: AppTheme.deepLeafGreen.withOpacity(0.3),
                      elevation: 8,
                    ),
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RoleSelectionScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Register',
                              style: TextStyle(
                                color: AppTheme.deepLeafGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSignIn() async {
    final phoneOrEmail = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (phoneOrEmail.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number and password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    // Call Sanctum API
    final result = await ApiService.loginUser(
      phoneNumber: phoneOrEmail,
      password: password,
    );

    // Dismiss spinner
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (result['success'] == true) {
      final user = result['user'];
      final List<dynamic> roles = user['role'] ?? [];
      final primaryRole = roles.isNotEmpty ? roles[0].toString() : 'customer';

      Widget targetDashboard;
      switch (primaryRole) {
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

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => targetDashboard),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.lock_person_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Auth Failure'),
              ],
            ),
            content: Text(result['message'] ?? 'Invalid phone/password credential combination.'),
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

  void _handleGoogleSignIn() async {
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

    // Mock Google OAuth delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop(); // dismiss spinner
      
      // Navigate to the Password Setup / Registration flow
      // passing the "mock" email from Google
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PasswordSetupScreen(email: 'user@gmail.com'),
        ),
      );
    }
  }
}
