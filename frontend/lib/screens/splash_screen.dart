import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/get_started_screen.dart';
import 'package:aswenna/services/api_service.dart';
import 'package:aswenna/screens/dashboards/farmer_dashboard.dart';
import 'package:aswenna/screens/dashboards/buyer_dashboard.dart';
import 'package:aswenna/screens/dashboards/retailer_dashboard.dart';
import 'package:aswenna/screens/dashboards/delivery_dashboard.dart';
import 'package:aswenna/screens/dashboards/customer_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _logoOpacity;

  late Animation<double> _textSlideUp;
  late Animation<double> _textOpacity;

  late Animation<double> _sloganSlideUp;
  late Animation<double> _sloganOpacity;
  
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main entrance animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Looping pulse animation controller for glowing aura
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Staggered Entrance Animations Setup
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoRotate = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    _textSlideUp = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.75, curve: Curves.fastOutSlowIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.65, curve: Curves.easeIn),
      ),
    );

    _sloganSlideUp = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.95, curve: Curves.fastOutSlowIn),
      ),
    );

    _sloganOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeIn),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    // Check for saved session after splash animation
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Wait for the splash animation to show completely
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final token = await ApiService.getToken();
    final role = await ApiService.getUserRole();

    Widget destination;

    if (token != null && token.isNotEmpty && role != null && role.isNotEmpty) {
      // User has a saved session — route to their dashboard
      switch (role) {
        case 'farmer':
          destination = const FarmerDashboard();
          break;
        case 'buyer':
          destination = const BuyerDashboard();
          break;
        case 'retail_seller':
          destination = const RetailerDashboard();
          break;
        case 'delivery_partner':
          destination = const DeliveryDashboard();
          break;
        case 'customer':
        default:
          destination = const CustomerDashboard();
          break;
      }
    } else {
      // No saved session — go to onboarding
      destination = const GetStartedScreen();
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.darkGreen,
        child: Stack(
          children: [
            // Farmer work field background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
            // Cinematic gradient overlay with soft blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.darkGreen.withOpacity(0.4),
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Decorative background patterns
            Positioned.fill(
              child: Opacity(
                opacity: 0.06,
                child: CustomPaint(
                  painter: PatternPainter(),
                ),
              ),
            ),
            // Center Logo & Text Contents
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Pulsing brand logo container
                  AnimatedBuilder(
                    animation: Listenable.merge([_controller, _pulseController]),
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _logoRotate.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulse aura glow behind logo
                                Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: AppTheme.freshGreen.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.freshGreen.withOpacity(0.1),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Logo Card container
                                Container(
                                  width: 125,
                                  height: 125,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.freshGreen.withOpacity(0.35),
                                        blurRadius: 40,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          fit: BoxFit.contain,
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
                  const SizedBox(height: 36),
                  // Title and Subtitle with slide-up fade transition
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlideUp.value),
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: child,
                        ),
                      );
                    },
                    child: const Column(
                      children: [
                        Text(
                          'Aswenna',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'අස්වැන්න',
                          style: TextStyle(
                            color: AppTheme.lightMint,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer Slogan and progress bar at the bottom
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _sloganSlideUp.value),
                    child: Opacity(
                      opacity: _sloganOpacity.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    // Premium thin circular progress indicator
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.freshGreen.withOpacity(0.85),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Smart Agriculture Marketplace'.toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.lightMint.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Direct Farmer-to-Buyer Ecosystem',
                      style: TextStyle(
                        color: AppTheme.lightMint.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Leaf background patterns
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.lightMint
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(20, -5, 30, 20);
    path.quadraticBezierTo(5, 30, 0, 0);

    canvas.save();
    canvas.translate(size.width * 0.15, size.height * 0.2);
    canvas.rotate(0.5);
    canvas.scale(2.0);
    canvas.drawPath(path, paint);
    canvas.restore();

    canvas.save();
    canvas.translate(size.width * 0.8, size.height * 0.15);
    canvas.rotate(-0.8);
    canvas.scale(2.5);
    canvas.drawPath(path, paint);
    canvas.restore();

    canvas.save();
    canvas.translate(size.width * 0.2, size.height * 0.75);
    canvas.rotate(2.1);
    canvas.scale(3.0);
    canvas.drawPath(path, paint);
    canvas.restore();

    canvas.save();
    canvas.translate(size.width * 0.85, size.height * 0.8);
    canvas.rotate(1.2);
    canvas.scale(2.2);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
