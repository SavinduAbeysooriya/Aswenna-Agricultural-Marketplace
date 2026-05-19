import 'dart:convert';
import 'package:http/http.dart' as http;

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
}
