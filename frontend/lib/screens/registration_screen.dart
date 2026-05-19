import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String role;

  const RegistrationScreen({super.key, required this.role});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 1;
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedProvince;
  String? _selectedDistrict;

  // Role-Specific Fields
  // Farmer
  final _farmNameController = TextEditingController();
  final _cropCategoriesController = TextEditingController();
  final _landSizeController = TextEditingController();
  final _experienceController = TextEditingController();

  // Buyer
  final _deliveryAddressController = TextEditingController();
  final _favCategoriesController = TextEditingController();

  // Retail Seller
  final _businessNameController = TextEditingController();
  final _bizRegController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _productCatsController = TextEditingController();

  // Delivery
  String? _selectedVehicleType;
  final _nicController = TextEditingController();

  final List<String> _provinces = ['Central', 'North Central', 'Southern', 'Uva', 'Western'];
  final List<String> _districts = ['Nuwara Eliya', 'Anuradhapura', 'Badulla', 'Colombo', 'Galle'];
  final List<String> _vehicles = ['Motorcycle', 'Three-Wheeler', 'Mini Truck (Dimo Batta)', 'Light Truck'];

  @override
  Widget build(BuildContext context) {
    String roleLabel = widget.role.replaceAll('_', ' ').toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('Register Account'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Progress Header
            Container(
              color: AppTheme.pureWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step $_currentStep of 2',
                        style: const TextStyle(
                          color: AppTheme.freshGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.lightMint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            color: AppTheme.deepLeafGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress indicator bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _currentStep / 2,
                      minHeight: 8,
                      backgroundColor: AppTheme.softGray,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.freshGreen),
                    ),
                  ),
                ],
              ),
            ),
            // Form viewport scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 1 ? _buildCommonFields() : _buildRoleFields(),
                  ),
                ),
              ),
            ),
            // Bottom Action control button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  shadowColor: AppTheme.deepLeafGreen.withOpacity(0.3),
                  elevation: 6,
                ),
                child: Text(_currentStep == 1 ? 'Continue' : 'Complete Registration'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: General fields for all users
  Widget _buildCommonFields() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'General Information',
          style: TextStyle(
            color: AppTheme.darkGreen,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Provide your primary personal contact details.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 20),
        // Profile Photo Uploader Mockup
        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.deepLeafGreen.withOpacity(0.1),
                    width: 4,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    color: AppTheme.deepLeafGreen,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload Profile Photo',
                style: TextStyle(
                  color: AppTheme.deepLeafGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.deepLeafGreen),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
            hintText: 'e.g. 0771234567',
            prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppTheme.deepLeafGreen),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'yourname@example.com',
            prefixIcon: Icon(Icons.mail_outline_rounded, color: AppTheme.deepLeafGreen),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Create secure password',
            prefixIcon: Icon(Icons.lock_open_rounded, color: AppTheme.deepLeafGreen),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedProvince,
                hint: const Text('Province'),
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14)),
                items: _provinces.map((prov) {
                  return DropdownMenuItem(value: prov, child: Text(prov));
                }).toList(),
                onChanged: (val) => setState(() => _selectedProvince = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDistrict,
                hint: const Text('District'),
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14)),
                items: _districts.map((dist) {
                  return DropdownMenuItem(value: dist, child: Text(dist));
                }).toList(),
                onChanged: (val) => setState(() => _selectedDistrict = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 2: Custom fields depending on user role
  Widget _buildRoleFields() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workspace Verification',
          style: TextStyle(
            color: AppTheme.darkGreen,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Provide specific credentials matching your user group.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 24),
        if (widget.role == 'farmer') ...[
          TextFormField(
            controller: _farmNameController,
            decoration: const InputDecoration(
              labelText: 'Farm Name',
              hintText: 'e.g. Nuwara Eliya Organic Fields',
              prefixIcon: Icon(Icons.landscape_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cropCategoriesController,
            decoration: const InputDecoration(
              labelText: 'Crop Categories',
              hintText: 'e.g. Potato, Carrot, Beetroot',
              prefixIcon: Icon(Icons.grass_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _landSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Land Size (Acres)',
                    hintText: 'e.g. 2.5',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Farming Experience',
                    hintText: 'e.g. 5 Years',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCertUploader('Upload GAP / Organic Certifications'),
        ] else if (widget.role == 'buyer') ...[
          TextFormField(
            controller: _deliveryAddressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Default Delivery Address',
              hintText: 'Enter your office or factory address',
              prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _favCategoriesController,
            decoration: const InputDecoration(
              labelText: 'Favorite Purchasing Categories',
              hintText: 'e.g. Grains, Vegetables, Spices',
              prefixIcon: Icon(Icons.favorite_outline_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
        ] else if (widget.role == 'retail_seller') ...[
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Registered Business Name',
              hintText: 'e.g. Agro Lanka Supermarkets',
              prefixIcon: Icon(Icons.store_mall_directory_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bizRegController,
            decoration: const InputDecoration(
              labelText: 'Business Registration (BR) Number',
              hintText: 'e.g. PV/12345/LK',
              prefixIcon: Icon(Icons.badge_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _storeAddressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Physical Store Address',
              hintText: 'Where customers pick up orders',
              prefixIcon: Icon(Icons.pin_drop_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _productCatsController,
            decoration: const InputDecoration(
              labelText: 'Product Categories',
              hintText: 'e.g. Seedlings, Fertilizers, Pots',
              prefixIcon: Icon(Icons.category_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
        ] else if (widget.role == 'delivery_partner') ...[
          DropdownButtonFormField<String>(
            value: _selectedVehicleType,
            hint: const Text('Select Vehicle Type'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.delivery_dining_rounded, color: AppTheme.deepLeafGreen),
            ),
            items: _vehicles.map((v) {
              return DropdownMenuItem(value: v, child: Text(v));
            }).toList(),
            onChanged: (val) => setState(() => _selectedVehicleType = val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nicController,
            decoration: const InputDecoration(
              labelText: 'National Identity Card (NIC)',
              hintText: 'e.g. 199012345678 or 901234567V',
              prefixIcon: Icon(Icons.perm_identity_rounded, color: AppTheme.deepLeafGreen),
            ),
          ),
          const SizedBox(height: 20),
          _buildCertUploader('Upload Driving License Photo'),
        ] else ...[
          // Default Customer options
          const Text(
            'Preferred Categories',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPrefChip('Fresh Veggies'),
              _buildPrefChip('Organic Fruits'),
              _buildPrefChip('Grains & Rice'),
              _buildPrefChip('Farming Tools'),
              _buildPrefChip('Seeds & Plants'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPrefChip(String label) {
    return FilterChip(
      label: Text(label),
      selectedColor: AppTheme.lightMint,
      checkmarkColor: AppTheme.deepLeafGreen,
      onSelected: (val) {},
    );
  }

  Widget _buildCertUploader(String label) {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.deepLeafGreen.withOpacity(0.15),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.upload_file_rounded,
              color: AppTheme.deepLeafGreen,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.deepLeafGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    if (_currentStep == 1) {
      setState(() {
        _currentStep = 2;
      });
    } else {
      // Complete workflow successfully
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.freshGreen, size: 28),
              SizedBox(width: 8),
              Text('Registration Sent'),
            ],
          ),
          content: const Text(
            'Your account setup has been submitted successfully. If verification is required, a system administrator will approve your workspace shortly.',
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
  }
}
