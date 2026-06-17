import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/registration_screen.dart';

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

  Widget _buildRoleCard(Map<String, dynamic> role, {bool isFullWidth = false}) {
    final isSelected = _selectedRole == role['id'];
    
    if (isFullWidth) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role['id'];
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppTheme.freshGreen
                  : AppTheme.deepLeafGreen.withOpacity(0.08),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppTheme.freshGreen.withOpacity(0.08)
                    : Colors.black.withOpacity(0.02),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: role['bgColor'],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role['icon'],
                  color: role['color'],
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
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
                        size: 12,
                        color: AppTheme.pureWhite,
                      )
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role['id'];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.freshGreen
                : AppTheme.deepLeafGreen.withOpacity(0.08),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.freshGreen.withOpacity(0.08)
                  : Colors.black.withOpacity(0.02),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: role['bgColor'],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    role['icon'],
                    color: role['color'],
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  role['title'],
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.deepLeafGreen
                        : const Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
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
                        size: 12,
                        color: AppTheme.pureWhite,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.30;

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
                'assets/images/role_selection_bg.jpg',
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
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32.0,
                      ),
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
                                        'Step 1 of 2',
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
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
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
                              const SizedBox(height: 8),
                              const Text(
                                'Select your active workspace profile to continue. This configuration customizes your workflow dashboards.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Redesigned Grid Layout
                              Row(
                                children: [
                                  Expanded(child: _buildRoleCard(_roles[0])),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildRoleCard(_roles[1])),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildRoleCard(_roles[2])),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildRoleCard(_roles[3])),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildRoleCard(_roles[4], isFullWidth: true),
                              
                              const SizedBox(height: 24),
                              
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
                                  elevation: _selectedRole == null ? 0 : 4,
                                  shadowColor: AppTheme.deepLeafGreen.withOpacity(0.3),
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Continue'),
                              ),
                            ],
                          ),
                        ],
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
