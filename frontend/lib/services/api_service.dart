import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use http://10.0.2.2:8000/api for Android Emulator to access local host
  // Use http://127.0.0.1:8000/api for iOS Simulator / Web / Desktop
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  /**
   * Register a new user on the Laravel backend.
   */
  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required String province,
    required String district,
    required String role,
    // Optional role specific fields
    String? farmingLicense,
    String? brNumber,
    String? shopAddress,
    String? vehicleType,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    final Map<String, dynamic> requestBody = {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email.isEmpty ? null : email,
      'password': password,
      'province': province,
      'district': district,
      'role': role,
      if (farmingLicense != null) 'farming_license_number': farmingLicense,
      if (brNumber != null) 'br_number': brNumber,
      if (shopAddress != null) 'shop_address': shopAddress,
      if (vehicleType != null) 'vehicle_type': vehicleType,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        await _saveSession(
          responseData['token'], 
          responseData['user']['role'] != null && responseData['user']['role'].isNotEmpty 
              ? responseData['user']['role'][0].toString() 
              : 'customer',
          rememberMe: true, // Default to persistent for new registrations
        );

        return {
          'success': true,
          'message': responseData['message'] ?? 'Registration successful!',
          'token': responseData['token'],
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to register.',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network connection error: Failed to connect to $baseUrl. Make sure the Laravel server is running.',
        'error': e.toString(),
      };
    }
  }

  /**
   * Log in an existing user.
   */
  static Future<Map<String, dynamic>> loginUser({
    required String phoneNumber,
    required String password,
    bool rememberMe = false,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveSession(
          responseData['token'], 
          responseData['user']['role'] != null && responseData['user']['role'].isNotEmpty 
              ? responseData['user']['role'][0].toString() 
              : 'customer',
          rememberMe: rememberMe,
        );

        return {
          'success': true,
          'message': responseData['message'] ?? 'Login successful!',
          'token': responseData['token'],
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Invalid credentials.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network connection error. Failed to reach $baseUrl.',
        'error': e.toString(),
      };
    }
  }

  /**
   * Complete Google OAuth registration.
   */
  static Future<Map<String, dynamic>> googleRegisterUser({
    required String email,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/google-register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _saveSession(
          responseData['token'], 
          responseData['user']['role'] != null && responseData['user']['role'].isNotEmpty 
              ? responseData['user']['role'][0].toString() 
              : 'customer',
          rememberMe: true,
        );

        return {
          'success': true,
          'message': responseData['message'] ?? 'Google registration successful!',
          'token': responseData['token'],
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to register via Google.',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network connection error: Failed to connect to $baseUrl.',
        'error': e.toString(),
      };
    }
  }

  /**
   * Send verification OTP to email.
   */
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    final url = Uri.parse('$baseUrl/send-otp');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /**
   * Verify registration email OTP.
   */
  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /**
   * Check if user email is registered via Google and log in directly (Legacy/Bypass method).
   */
  static Future<Map<String, dynamic>> googleLogin(String email) async {
    final url = Uri.parse('$baseUrl/google-login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['registered'] == true) {
        await _saveSession(
          responseData['token'],
          responseData['user']['role'] != null && responseData['user']['role'].isNotEmpty
              ? responseData['user']['role'][0].toString()
              : 'customer',
          rememberMe: true, // Google login is persistently remembered
        );
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /**
   * Authenticate securely using a real Google ID Token retrieved from Google SDK.
   */
  static Future<Map<String, dynamic>> googleAuthenticate(String idToken) async {
    final url = Uri.parse('$baseUrl/google-authenticate');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id_token': idToken}),
      );
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['registered'] == true) {
        await _saveSession(
          responseData['token'],
          responseData['user']['role'] != null && responseData['user']['role'].isNotEmpty
              ? responseData['user']['role'][0].toString()
              : 'customer',
          rememberMe: true,
        );
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /**
   * Send a secure password recovery OTP code.
   */
  static Future<Map<String, dynamic>> sendForgotPasswordOtp(String email) async {
    final url = Uri.parse('$baseUrl/forgot-password/send-otp');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /**
   * Reset password securely using recovery OTP code.
   */
  static Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    final url = Uri.parse('$baseUrl/forgot-password/reset');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password': newPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Session Management Helpers ---

  static Future<void> _saveSession(String token, String role, {bool rememberMe = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aswenna_auth_token', token);
    await prefs.setString('aswenna_user_role', role);
    
    // Remember me stores session for 30 days, else 1 day session
    final days = rememberMe ? 30 : 1;
    final expiry = DateTime.now().add(Duration(days: days));
    await prefs.setString('aswenna_session_expiry', expiry.toIso8601String());
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString('aswenna_session_expiry');
    if (expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now().isAfter(expiry)) {
        await logout();
        return null;
      }
    }
    return prefs.getString('aswenna_auth_token');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('aswenna_user_role');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('aswenna_auth_token');
    await prefs.remove('aswenna_user_role');
    await prefs.remove('aswenna_session_expiry');
  }
}
