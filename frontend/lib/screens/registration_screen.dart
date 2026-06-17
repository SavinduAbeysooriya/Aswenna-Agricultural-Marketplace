import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/services/api_service.dart';

// Dashboard imports
import 'package:aswenna/screens/dashboards/farmer_dashboard.dart';
import 'package:aswenna/screens/dashboards/buyer_dashboard.dart';
import 'package:aswenna/screens/dashboards/retailer_dashboard.dart';
import 'package:aswenna/screens/dashboards/delivery_dashboard.dart';
import 'package:aswenna/screens/dashboards/customer_dashboard.dart';

const String _googleServerClientId =
    '365861807638-qouuf7mif5qa6j64jnpvm09c1ikbp4hr.apps.googleusercontent.com';
const String _googleIosClientId = _googleServerClientId;

class RegistrationScreen extends StatefulWidget {
  final String role;
  final Map<String, String>? registrationData;

  const RegistrationScreen({super.key, required this.role, this.registrationData});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Visibility states
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // OTP verification flag
  bool _emailVerified = false;

  // Flag to check if registration is triggered via Google Sign-In
  bool _isGoogleRegister = false;

  bool get _isGoogleSignup => widget.registrationData != null;

  @override
  void initState() {
    super.initState();
    if (widget.registrationData != null) {
      _emailController.text = widget.registrationData!['email'] ?? '';
      _passwordController.text = widget.registrationData!['password'] ?? '';
      if (widget.registrationData!.containsKey('name')) {
        _nameController.text = widget.registrationData!['name'] ?? '';
      }
      // Google users are pre-verified
      _emailVerified = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToDashboard(
    Map<String, dynamic> user, {
    String? successMessage,
  }) {
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

  void _submitRegistration() async {
    // Show sleek loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
        ),
      ),
    );

    // Generate a unique dummy phone number to satisfy backend required validator
    final randomPart = Random().nextInt(9000) + 1000;
    final dummyPhone = 'REG-${DateTime.now().millisecondsSinceEpoch}-$randomPart';

    // Extract details and call registration API
    final result = await ApiService.registerUser(
      fullName: _nameController.text.trim(),
      phoneNumber: dummyPhone,
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      province: '', 
      district: '', 
      role: widget.role,
    );

    // Dismiss loading indicator
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (result['success'] == true) {
      if (_isGoogleRegister) {
        _navigateToDashboard(result['user'], successMessage: 'Google registration successful!');
        return;
      }
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.freshGreen, size: 28),
                SizedBox(width: 8),
                Text('Success!'),
              ],
            ),
            content: const Text(
              'Your Aswenna account has been created successfully. Welcome to the Direct-to-Marketplace digital ecosystem.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss Dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } else {
      // Show validation or network errors
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Failed to Register'),
              ],
            ),
            content: Text(
              result['errors'] != null
                  ? 'Registration validation failed:\n\n${result['errors'].toString()}'
                  : result['message'] ?? 'Unable to connect to the backend server.',
            ),
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

  void _handleRegister() {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    // For standard (non-Google) signups, verify email via OTP first
    if (!_isGoogleSignup && !_emailVerified) {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address to verify.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      _showOtpVerificationSheet();
      return;
    }

    // Google users or already verified: submit registration
    _submitRegistration();
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

      final String email = googleUser.email;
      final String displayName = googleUser.displayName ?? '';

      // Check if email is already registered
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
          ),
        ),
      );

      final checkResult = await ApiService.googleLogin(email);

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss checking loader
      }

      if (checkResult['success'] == true && checkResult['registered'] == true) {
        // User already has an account, log them in directly!
        final user = checkResult['user'];
        _navigateToDashboard(user, successMessage: 'Logged in successfully via Google as ${user['full_name']}!');
      } else {
        // User is not registered. Auto-generate password and pre-fill fields, then submit registration immediately!
        final autoPass = 'GPass@${Random().nextInt(900000) + 100000}';
        setState(() {
          _nameController.text = displayName;
          _emailController.text = email;
          _passwordController.text = autoPass;
          _confirmPasswordController.text = autoPass;
          _emailVerified = true;
          _isGoogleRegister = true;
        });

        // Auto-register
        _submitRegistration();
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

  void _showOtpVerificationSheet() {
    final otpController = TextEditingController();
    bool isPending = false;
    bool isSending = true;
    String errorMessage = '';
    String successMessage = '';

    final email = _emailController.text.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Auto-send OTP on first build
            if (isSending) {
              Future.microtask(() async {
                final res = await ApiService.sendOtp(email);
                if (!context.mounted) return;
                setSheetState(() {
                  isSending = false;
                  if (res['success'] == true) {
                    successMessage = 'Verification code sent to $email';
                  } else {
                    successMessage = 'Using sandbox code 123456 for testing';
                  }
                });
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 68,
                      height: 68,
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
                        Icons.mark_email_read_rounded,
                        color: AppTheme.deepLeafGreen,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSending ? 'Sending code to $email...' : successMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isSending)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepLeafGreen),
                        ),
                      )
                    else ...[
                      TextFormField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                          color: AppTheme.darkGreen,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••',
                          hintStyle: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 28,
                            letterSpacing: 12,
                          ),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.deepLeafGreen.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppTheme.freshGreen, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isPending
                              ? null
                              : () async {
                                  if (otpController.text.length != 6) {
                                    setSheetState(() => errorMessage = 'Enter a 6-digit code');
                                    return;
                                  }
                                  setSheetState(() {
                                    isPending = true;
                                    errorMessage = '';
                                  });

                                  final res = await ApiService.verifyOtp(email, otpController.text);

                                  if (!context.mounted) return;

                                  if (res['success'] == true) {
                                    Navigator.pop(sheetContext);
                                    setState(() {
                                      _emailVerified = true;
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✅ Email verified successfully!'),
                                          backgroundColor: AppTheme.freshGreen,
                                        ),
                                      );
                                    }
                                    _submitRegistration();
                                  } else {
                                    setSheetState(() {
                                      isPending = false;
                                      errorMessage = res['message'] ?? 'Invalid code.';
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                              : const Text(
                                  'Verify & Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: isPending
                            ? null
                            : () async {
                                setSheetState(() {
                                  isSending = true;
                                  errorMessage = '';
                                });
                                final res = await ApiService.sendOtp(email);
                                if (!context.mounted) return;
                                setSheetState(() {
                                  isSending = false;
                                  if (res['success'] == true) {
                                    successMessage = 'New code sent to $email';
                                  } else {
                                    successMessage = 'Using sandbox code 123456';
                                  }
                                });
                              },
                        child: const Text(
                          'Resend Verification Code',
                          style: TextStyle(
                            color: AppTheme.deepLeafGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.30;
    String roleLabel = widget.role.replaceAll('_', ' ').toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Wavy Header Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: ClipPath(
              clipper: WavyHeaderClipper(),
              child: Image.asset(
                'assets/images/register_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.darkGreen,
                  );
                },
              ),
            ),
          ),

          // Back button circular overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: ClipOval(
              child: Material(
                color: Colors.white.withOpacity(0.85),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.darkGreen,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Main content form
          Positioned(
            top: headerHeight - 15,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32.0,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                // Title section with right logo badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            color: AppTheme.darkGreen,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Register as $roleLabel',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.lightMint,
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Image.asset(
                                            'assets/images/logo.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Full Name
                                TextFormField(
                                  controller: _nameController,
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF1F6F2),
                                    labelText: 'Full Name',
                                    labelStyle: TextStyle(
                                      color: AppTheme.darkGreen.withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: AppTheme.deepLeafGreen,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppTheme.freshGreen, width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Email Address
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !_isGoogleSignup,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Please enter your email';
                                    if (!val.contains('@')) return 'Please enter a valid email';
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF1F6F2),
                                    labelText: 'Email Address',
                                    labelStyle: TextStyle(
                                      color: AppTheme.darkGreen.withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.mail_outline_rounded,
                                      color: AppTheme.deepLeafGreen,
                                    ),
                                    suffixIcon: _isGoogleSignup
                                        ? const Icon(Icons.verified_rounded, color: AppTheme.freshGreen, size: 20)
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppTheme.freshGreen, width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  enabled: !_isGoogleSignup,
                                  validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF1F6F2),
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      color: AppTheme.darkGreen.withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppTheme.deepLeafGreen,
                                    ),
                                    suffixIcon: _isGoogleSignup
                                        ? const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 20)
                                        : IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: AppTheme.deepLeafGreen.withOpacity(0.6),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppTheme.freshGreen, width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Confirm Password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  enabled: !_isGoogleSignup,
                                  validator: (val) {
                                    if (_isGoogleSignup) return null;
                                    if (val == null || val.isEmpty) return 'Please confirm your password';
                                    if (val != _passwordController.text) return 'Passwords do not match';
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF1F6F2),
                                    labelText: 'Confirm Password',
                                    labelStyle: TextStyle(
                                      color: AppTheme.darkGreen.withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppTheme.deepLeafGreen,
                                    ),
                                    suffixIcon: _isGoogleSignup
                                        ? const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 20)
                                        : IconButton(
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: AppTheme.deepLeafGreen.withOpacity(0.6),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirmPassword = !_obscureConfirmPassword;
                                              });
                                            },
                                          ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppTheme.freshGreen, width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Register Button
                                ElevatedButton(
                                  onPressed: _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.deepLeafGreen,
                                    foregroundColor: Colors.white,
                                    shadowColor: AppTheme.deepLeafGreen.withOpacity(0.35),
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    minimumSize: const Size(double.infinity, 58),
                                  ),
                                  child: const Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _handleGoogleSignUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    shadowColor: Colors.black12,
                                    elevation: 1,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: BorderSide(color: Colors.grey.shade200),
                                    ),
                                    minimumSize: const Size(double.infinity, 56),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/google_logo.png',
                                        width: 22,
                                        height: 22,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.g_mobiledata_rounded,
                                            color: Colors.blue,
                                            size: 24,
                                          );
                                        },
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

                            // Already have an account text link
                            Padding(
                              padding: const EdgeInsets.only(top: 24.0),
                              child: Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                                      (route) => false,
                                    );
                                  },
                                  child: RichText(
                                    text: const TextSpan(
                                      text: "Already have an account? ",
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Login',
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavyHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
        
    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);
        
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
