import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/role_selection_screen.dart';

class PasswordSetupScreen extends StatefulWidget {
  final String email;

  const PasswordSetupScreen({super.key, required this.email});

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secure Your Account',
              style: TextStyle(
                color: AppTheme.darkGreen,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set a password for your account linked to\n${widget.email}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            
            TextFormField(
              initialValue: widget.email,
              readOnly: true,
              style: const TextStyle(color: Colors.black54),
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_rounded, color: Colors.grey),
                filled: true,
                fillColor: Color(0xFFF1F5F9), // slate-100
              ),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
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
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline_rounded, color: AppTheme.deepLeafGreen),
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _continueToRoleSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepLeafGreen,
                  shadowColor: AppTheme.deepLeafGreen.withOpacity(0.3),
                  elevation: 8,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Continue to Role Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueToRoleSelection() {
    // Basic validation
    if (_passwordController.text.isEmpty || _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match or are empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to role selection screen passing email and password
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoleSelectionScreen(
          registrationData: {
            'email': widget.email,
            'password': _passwordController.text,
            'auth_provider': 'google',
          },
        ),
      ),
    );
  }
}
