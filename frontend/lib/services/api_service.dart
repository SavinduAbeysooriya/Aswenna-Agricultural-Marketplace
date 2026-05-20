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
              : 'customer'
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
              : 'customer'
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
              : 'customer'
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

  // --- Session Management Helpers ---

  static Future<void> _saveSession(String token, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aswenna_auth_token', token);
    await prefs.setString('aswenna_user_role', role);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
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
  }
}
