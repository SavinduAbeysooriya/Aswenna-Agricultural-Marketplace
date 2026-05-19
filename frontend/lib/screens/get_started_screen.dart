import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/role_selection_screen.dart';
import 'package:aswenna/screens/login_screen.dart';
import 'package:aswenna/screens/splash_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top half: Decorative organic artwork & farming graphics
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.lightMint,
                      AppTheme.pureWhite,
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Leaf pattern backdrop
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.05,
                        child: CustomPaint(
                          painter: PatternPainter(),
                        ),
                      ),
                    ),
                    // High-end startup-inspired illustration card
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.deepLeafGreen.withOpacity(0.06),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                        border: Border.all(
                          color: AppTheme.deepLeafGreen.withOpacity(0.04),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Inner icons & tractor motif
                          const Icon(
                            Icons.agriculture_rounded,
                            size: 100,
                            color: AppTheme.deepLeafGreen,
                          ),
                          // Floating seed badge
                          Positioned(
                            top: -15,
                            left: -15,
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(
                                color: AppTheme.lightMint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.spa_rounded,
                                color: AppTheme.deepLeafGreen,
                                size: 28,
                              ),
                            ),
                          ),
                          // Floating money/trade badge
                          Positioned(
                            bottom: -10,
                            right: -15,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E6),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.accentGold.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: AppTheme.accentGold,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom half: Typography, welcome context and CTAs
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Welcome to Aswenna',
                          style: TextStyle(
                            color: AppTheme.darkGreen,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Buy, Sell, and Grow Together',
                          style: TextStyle(
                            color: Color(0xFF334155), // Slate-700
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Connect directly with verified farmers, buyers, retailers, and couriers islandwide.',
                          style: TextStyle(
                            color: Color(0xFF64748B), // Slate-500
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        // Get Started CTA
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RoleSelectionScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepLeafGreen,
                            shadowColor: AppTheme.deepLeafGreen.withOpacity(0.3),
                            elevation: 8,
                          ),
                          child: const Text('Get Started'),
                        ),
                        const SizedBox(height: 8),
                        // Already have an account Login
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: 'Already have an account? ',
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
                      ],
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
