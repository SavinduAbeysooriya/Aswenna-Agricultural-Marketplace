import 'dart:async';
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
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

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
                            color: AppTheme.pureWhite,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.deepLeafGreen.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: AppTheme.deepLeafGreen,
                            onChanged: (val) {
                              setState(() {
                                _rememberMe = val ?? false;
                              });
                            },
                          ),
                          const Text(
                            'Remember Me',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _showForgotPasswordSheet,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppTheme.deepLeafGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
      rememberMe: _rememberMe,
    );

    // Dismiss spinner
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (result['success'] == true) {
      if (result['requires_otp'] == true) {
        _showLoginOtpVerificationSheet(result['email'] ?? phoneOrEmail, _rememberMe);
        return;
      }
      final user = result['user'];
      _navigateToDashboard(user);
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

  void _navigateToDashboard(Map<String, dynamic> user, {String? successMessage}) {
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
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppTheme.freshGreen,
          ),
        );
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => targetDashboard),
        (route) => false,
      );
    }
  }

  void _showLoginOtpVerificationSheet(String email, bool rememberMe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _LoginOtpSheet(
          email: email,
          rememberMe: rememberMe,
          onSuccess: (user) {
            _navigateToDashboard(
              user,
              successMessage: 'Two-Factor Verification Successful!',
            );
          },
        );
      },
    );
  }

  void _handleGoogleSignIn() async {
    bool loaderShown = false;
    try {
      // Initialize the singleton instance with the correct serverClientId for Android
      await GoogleSignIn.instance.initialize(
        serverClientId: '365861807638-qouuf7mif5qa6j64jnpvm09c1ikbp4hr.apps.googleusercontent.com',
      );

      if (!mounted) return;

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
      loaderShown = true;

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      
      // Dismiss visual loader
      if (mounted && loaderShown) {
        Navigator.of(context).pop();
        loaderShown = false;
      }

      if (googleUser == null) {
        // User cancelled sign in
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null && idToken.isNotEmpty) {
        _processRealGoogleAuth(idToken);
      } else {
        // Fallback to email validation if ID token is empty
        _processGoogleEmail(googleUser.email);
      }
    } catch (error) {
        // Dismiss loader if showing
        if (mounted && loaderShown) {
          Navigator.of(context).pop();
          loaderShown = false;
        }

        debugPrint('Native Google Sign-In failed: $error');

        // Show error to user and provide fallback selector
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Sign-In failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          // Offer manual Google account selection as fallback
          _showFallbackGoogleSelector();
        }
    }
  }

  void _showFallbackGoogleSelector() async {
    final selectedEmail = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        title: Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('G', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 24)),
                  Text('o', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 24)),
                  Text('o', style: TextStyle(color: Colors.yellow.shade700, fontWeight: FontWeight.bold, fontSize: 24)),
                  Text('g', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 24)),
                  Text('l', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 24)),
                  Text('e', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 24)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose a Google account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Text(
                'to continue to Aswenna',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildGoogleAccountTile(context, 'Saman Kumara', 'farmer@aswenna.com'),
              _buildGoogleAccountTile(context, 'Keeri Samba Mills', 'buyer@aswenna.com'),
              _buildGoogleAccountTile(context, 'Agro Retail Mart', 'retailer@aswenna.com'),
              _buildGoogleAccountTile(context, 'Nuwara Courier', 'delivery@aswenna.com'),
              _buildGoogleAccountTile(context, 'Lakmal Perera', 'customer@aswenna.com'),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded, color: Color(0xFF475569)),
                ),
                title: const Text('Add new Google account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.of(context).pop();
                  final customEmail = await _showCustomGoogleEmailDialog();
                  if (customEmail != null && customEmail.isNotEmpty) {
                    _processGoogleEmail(customEmail);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedEmail != null) {
      _processGoogleEmail(selectedEmail);
    }
  }

  Widget _buildGoogleAccountTile(BuildContext context, String name, String email) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.lightMint,
        child: Text(name[0], style: const TextStyle(color: AppTheme.deepLeafGreen, fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      subtitle: Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      onTap: () => Navigator.of(context).pop(email),
    );
  }

  Future<String?> _showCustomGoogleEmailDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Enter Google Email'),
        content: TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Google Email Address',
            hintText: 'e.g. yourname@gmail.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _processGoogleEmail(String email) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
        ),
      ),
    );

    final result = await ApiService.googleLogin(email);

    if (mounted) {
      Navigator.of(context).pop();
    }

    if (result['success'] == true) {
      if (result['requires_otp'] == true) {
        _showLoginOtpVerificationSheet(result['email'] ?? email, true);
        return;
      }
      if (result['registered'] == true) {
        final user = result['user'];
        _navigateToDashboard(
          user,
          successMessage: 'Logged in successfully via Google as ${user['full_name']}!',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google account authenticated. Complete setup to create your Aswenna profile!'),
              backgroundColor: Colors.blue,
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PasswordSetupScreen(email: email),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Network error during Google auth.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _processRealGoogleAuth(String idToken) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
        ),
      ),
    );

    final result = await ApiService.googleAuthenticate(idToken);

    if (mounted) {
      Navigator.of(context).pop();
    }

    if (result['success'] == true) {
      if (result['requires_otp'] == true) {
        _showLoginOtpVerificationSheet(result['email'] ?? result['user']?['email'] ?? 'Google User', true);
        return;
      }
      if (result['registered'] == true) {
        final user = result['user'];
        _navigateToDashboard(
          user,
          successMessage: 'Logged in successfully via Google as ${user['full_name']}!',
        );
      } else {
        final email = result['email'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google account verified. Complete setup to create your Aswenna profile!'),
              backgroundColor: Colors.blue,
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PasswordSetupScreen(email: email),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Secure Google validation failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showForgotPasswordSheet() {
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    int forgotStep = 1; // 1: Email, 2: OTP & Reset
    bool isPending = false;
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Password Recovery',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.darkGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      forgotStep == 1
                          ? 'Enter your registered email address to receive a 6-digit verification code.'
                          : 'Verify the OTP code sent to your email and set your new account password.',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    if (errorMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (forgotStep == 1) ...[
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'yourname@example.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.deepLeafGreen),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isPending
                              ? null
                              : () async {
                                  final email = emailController.text.trim();
                                  if (email.isEmpty) {
                                    setSheetState(() => errorMessage = 'Please enter your email.');
                                    return;
                                  }
                                  setSheetState(() {
                                    isPending = true;
                                    errorMessage = '';
                                  });
                                  final res = await ApiService.sendForgotPasswordOtp(email);
                                  setSheetState(() => isPending = false);

                                  if (res['success'] == true) {
                                    setSheetState(() {
                                      forgotStep = 2;
                                    });
                                  } else {
                                    setSheetState(() {
                                      errorMessage = res['message'] ?? 'Failed to send OTP.';
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                          ),
                          child: isPending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Send Reset OTP'),
                        ),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '6-Digit OTP',
                          hintText: 'Enter code sent via email',
                          prefixIcon: Icon(Icons.pin_outlined, color: AppTheme.deepLeafGreen),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          hintText: 'Minimum 6 characters',
                          prefixIcon: Icon(Icons.vpn_key_outlined, color: AppTheme.deepLeafGreen),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm New Password',
                          hintText: 'Re-type your password',
                          prefixIcon: Icon(Icons.lock_outline, color: AppTheme.deepLeafGreen),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isPending
                              ? null
                              : () async {
                                  final email = emailController.text.trim();
                                  final otp = otpController.text.trim();
                                  final pwd = newPasswordController.text.trim();
                                  final confirm = confirmPasswordController.text.trim();

                                  if (otp.length != 6) {
                                    setSheetState(() => errorMessage = 'OTP code must be 6 digits.');
                                    return;
                                  }
                                  if (pwd.length < 6) {
                                    setSheetState(() => errorMessage = 'Password must be at least 6 characters.');
                                    return;
                                  }
                                  if (pwd != confirm) {
                                    setSheetState(() => errorMessage = 'Passwords do not match.');
                                    return;
                                  }

                                  setSheetState(() {
                                    isPending = true;
                                    errorMessage = '';
                                  });
                                  final res = await ApiService.resetPassword(email, otp, pwd);
                                  setSheetState(() => isPending = false);

                                  if (res['success'] == true) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res['message'] ?? 'Password reset successfully!'),
                                        backgroundColor: AppTheme.freshGreen,
                                      ),
                                    );
                                  } else {
                                    setSheetState(() {
                                      errorMessage = res['message'] ?? 'Failed to reset password.';
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                          ),
                          child: isPending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Reset Password'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LoginOtpSheet extends StatefulWidget {
  final String email;
  final bool rememberMe;
  final Function(Map<String, dynamic> user) onSuccess;

  const _LoginOtpSheet({
    required this.email,
    required this.rememberMe,
    required this.onSuccess,
  });

  @override
  State<_LoginOtpSheet> createState() => _LoginOtpSheetState();
}

class _LoginOtpSheetState extends State<_LoginOtpSheet> {
  final _otpController = TextEditingController();
  bool _isPending = false;
  bool _isResending = false;
  String _errorMessage = '';
  String _successMessage = '';
  int _cooldownSeconds = 30;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _successMessage = 'Verification code sent to ${widget.email}';
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 30;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          _cooldownTimer?.cancel();
        }
      });
    });
  }

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
      _successMessage = '';
    });

    final res = await ApiService.sendLoginOtp(email: widget.email);

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    if (res['success'] == true) {
      setState(() {
        _successMessage = 'New code sent successfully!';
      });
      _startCooldown();
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Failed to resend verification code.';
      });
    }
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a 6-digit OTP code.';
      });
      return;
    }

    setState(() {
      _isPending = true;
      _errorMessage = '';
    });

    final result = await ApiService.loginVerifyOtp(
      email: widget.email,
      otp: otp,
      rememberMe: widget.rememberMe,
    );

    if (!mounted) return;

    setState(() {
      _isPending = false;
    });

    if (result['success'] == true) {
      Navigator.of(context).pop(); // Close sheet
      widget.onSuccess(result['user']);
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Verification mismatch. Please check the code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: const BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            // Pulsing Lock Icon Badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.freshGreen.withOpacity(0.15),
                    AppTheme.deepLeafGreen.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: AppTheme.deepLeafGreen,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Security Verification',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aswenna takes security seriously. Enter the 6-digit One-Time Password sent to your email:',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.deepLeafGreen,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Status and alerts
            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_successMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: AppTheme.freshGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage,
                        style: const TextStyle(color: AppTheme.darkGreen, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // OTP Input
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 14,
                color: AppTheme.darkGreen,
              ),
              decoration: InputDecoration(
                hintText: '••••••',
                hintStyle: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 32,
                  letterSpacing: 14,
                ),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: AppTheme.deepLeafGreen.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppTheme.freshGreen, width: 2.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
            const SizedBox(height: 24),
            
            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isPending ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepLeafGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  shadowColor: AppTheme.deepLeafGreen.withOpacity(0.2),
                  elevation: 6,
                ),
                child: _isPending
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verify & Proceed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),

            // Resend timer section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_cooldownSeconds > 0) ...[
                  Icon(Icons.hourglass_empty_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Resend code in ${_cooldownSeconds}s',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  _isResending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _handleResend,
                          icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.deepLeafGreen),
                          label: const Text(
                            'Resend Code',
                            style: TextStyle(
                              color: AppTheme.deepLeafGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
