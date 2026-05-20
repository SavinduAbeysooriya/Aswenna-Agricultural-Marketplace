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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Check for saved session after splash animation
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Wait for the splash animation to play
    await Future.delayed(const Duration(seconds: 3));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkGreen,
              AppTheme.deepLeafGreen,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle leaf pattern background accents using CustomPaint
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: CustomPaint(
                  painter: PatternPainter(),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppTheme.pureWhite,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.eco_rounded,
                                size: 64,
                                color: AppTheme.deepLeafGreen,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _opacityAnimation.value,
                        child: child,
                      );
                    },
                    child: const Column(
                      children: [
                        Text(
                          'Aswenna',
                          style: TextStyle(
                            color: AppTheme.pureWhite,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'අස්වැන්න',
                          style: TextStyle(
                            color: AppTheme.lightMint,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    const Text(
                      'Smart Agriculture Marketplace',
                      style: TextStyle(
                        color: AppTheme.lightMint,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Direct Farmer-to-Buyer Ecosystem',
                      style: TextStyle(
                        color: AppTheme.lightMint.withOpacity(0.8),
                        fontSize: 12,
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

// Beautiful leaf background illustrator
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.lightMint
      ..style = PaintingStyle.fill;

    // Draw small leaves decoration randomly
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
