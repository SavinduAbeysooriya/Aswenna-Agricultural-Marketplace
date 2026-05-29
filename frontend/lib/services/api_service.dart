import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use http://10.0.2.2:8000/api for Android Emulator to access local host
  // Use http://127.0.0.1:8000/api for iOS Simulator / Web / Desktop
  static const String baseUrl = 'http://10.0.2.2:8001/api';
  static const String appUrl = 'http://10.0.2.2:8001';

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
          responseData['user']['role'] != null &&
                  responseData['user']['role'].isNotEmpty
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
        'message':
            'Network connection error: Failed to connect to $baseUrl. Make sure the Laravel server is running.',
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
        body: jsonEncode({'phone_number': phoneNumber, 'password': password}),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['requires_otp'] == true) {
          return {
            'success': true,
            'requires_otp': true,
            'email': responseData['email'],
            'message': responseData['message'] ?? '2FA verification required.',
          };
        }

        await _saveSession(
          responseData['token'],
          responseData['user']['role'] != null &&
                  responseData['user']['role'].isNotEmpty
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
        body: jsonEncode({'email': email, 'password': password, 'role': role}),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _saveSession(
          responseData['token'],
          responseData['user']['role'] != null &&
                  responseData['user']['role'].isNotEmpty
              ? responseData['user']['role'][0].toString()
              : 'customer',
          rememberMe: true,
        );

        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Google registration successful!',
          'token': responseData['token'],
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to register via Google.',
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
  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
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
        if (responseData['requires_otp'] == true) {
          return responseData;
        }
        await _saveSession(
          responseData['token'],
          responseData['user']['role'] != null &&
                  responseData['user']['role'].isNotEmpty
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
        if (responseData['requires_otp'] == true) {
          return responseData;
        }
        await _saveSession(
          responseData['token'],
          responseData['user']['role'] != null &&
                  responseData['user']['role'].isNotEmpty
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
  static Future<Map<String, dynamic>> sendForgotPasswordOtp(
    String email,
  ) async {
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
  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    final url = Uri.parse('$baseUrl/forgot-password/reset');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'otp': otp, 'password': newPassword}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /**
   * Fetch the authenticated farmer's complete profile details.
   */
  static Future<Map<String, dynamic>> getFarmerProfile() async {
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Your session has expired. Please sign in again.',
      };
    }

    final url = Uri.parse('$baseUrl/farmer/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to load farmer profile.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network connection error. Failed to load farmer profile.',
        'error': e.toString(),
      };
    }
  }

  /**
   * Update the authenticated farmer's editable profile details.
   */
  static Future<Map<String, dynamic>> updateFarmerProfile(
    Map<String, dynamic> data, {
    Map<String, String?> files = const {},
    List<Map<String, String?>> otherCertificates = const [],
  }) async {
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Your session has expired. Please sign in again.',
      };
    }

    final url = Uri.parse('$baseUrl/farmer/profile');
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        })
        ..fields['_method'] = 'PUT';

      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      for (final entry in files.entries) {
        final path = entry.value;
        if (path != null && path.trim().isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath(entry.key, path));
        }
      }

      for (var index = 0; index < otherCertificates.length; index++) {
        final certificate = otherCertificates[index];
        request.fields['other_certificates[$index][title]'] =
            certificate['title'] ?? '';
        request.fields['other_certificates[$index][existing_path]'] =
            certificate['existing_path'] ?? '';

        final filePath = certificate['file_path'];
        if (filePath != null && filePath.trim().isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'other_certificate_files[$index]',
              filePath,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final Map<String, dynamic> responseData = jsonDecode(responseBody);
      if (streamedResponse.statusCode == 200 &&
          responseData['success'] == true) {
        return responseData;
      }

      return {
        'success': false,
        'message':
            responseData['message'] ?? 'Failed to update farmer profile.',
        'errors': responseData['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network connection error. Failed to update farmer profile.',
        'error': e.toString(),
      };
    }
  }

  /**
   * Fetch all lands registered by the authenticated farmer.
   */
  static Future<Map<String, dynamic>> getFarmerLands() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/farmer/lands');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to load lands.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /**
   * Fetch approved crops list for selection (farmer-facing).
   */
  static Future<Map<String, dynamic>> getApprovedCrops() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/crops');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to load crops.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCropGrowthStages() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/crop-growth-stages');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to load growth stages.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCultivationLogs() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/farmer/cultivation-logs');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to load logs.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addCultivationLog(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/farmer/cultivation-logs');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 && responseData['success'] == true) return responseData;
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to add log.',
        'errors': responseData['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateCultivationLog(int id, Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/farmer/cultivation-logs/$id');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && responseData['success'] == true) return responseData;
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update log.',
        'errors': responseData['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteCultivationLog(int id) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/farmer/cultivation-logs/$id');
    try {
      final response = await http.delete(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && responseData['success'] == true) return responseData;
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to delete log.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /**
   * Register a new land parcel for the authenticated farmer.
   */
  static Future<Map<String, dynamic>> addFarmerLand(
    Map<String, dynamic> data, {
    List<String> imagePaths = const [],
    List<String> documentPaths = const [],
    List<String> documentTitles = const [],
    List<int> cropIds = const [],
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/farmer/lands');
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });
      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });
      for (var i = 0; i < cropIds.length; i++) {
        request.fields['crop_ids[$i]'] = cropIds[i].toString();
      }
      for (final path in imagePaths) {
        if (path.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath('land_images[]', path));
        }
      }
      for (var i = 0; i < documentPaths.length; i++) {
        final path = documentPaths[i];
        final title = i < documentTitles.length ? documentTitles[i] : '';
        request.fields['land_documents[$i][title]'] = title;
        if (path.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath('land_document_files[$i]', path));
        }
      }
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final responseData = jsonDecode(body) as Map<String, dynamic>;
      if (streamed.statusCode == 201 && responseData['success'] == true) return responseData;
      return {'success': false, 'message': responseData['message'] ?? 'Failed to add land.', 'errors': responseData['errors']};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /**
   * Update an existing land parcel. Any update sets land status back to "pending" for approval.
   */
  static Future<Map<String, dynamic>> updateFarmerLand(
    int landId,
    Map<String, dynamic> data, {
    List<String> imagePaths = const [],
    List<String> documentPaths = const [],
    List<String> documentTitles = const [],
    List<String> keepImagePaths = const [],
    List<Map<String, dynamic>> keepDocuments = const [],
    List<int> cropIds = const [],
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/farmer/lands/$landId');
    try {
      // Use POST + _method=PUT so multipart form fields are parsed reliably on PHP/Laravel.
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

      request.fields['_method'] = 'PUT';

      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      for (var i = 0; i < cropIds.length; i++) {
        request.fields['crop_ids[$i]'] = cropIds[i].toString();
      }

      for (var i = 0; i < keepImagePaths.length; i++) {
        final path = keepImagePaths[i].toString();
        if (path.isNotEmpty) request.fields['keep_land_images[$i]'] = path;
      }
      for (var i = 0; i < keepDocuments.length; i++) {
        final doc = keepDocuments[i];
        final title = (doc['title'] ?? '').toString();
        final path = (doc['path'] ?? '').toString();
        if (path.isEmpty) continue;
        request.fields['keep_land_documents[$i][title]'] = title;
        request.fields['keep_land_documents[$i][path]'] = path;
      }

      for (final path in imagePaths) {
        if (path.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath('land_images[]', path));
        }
      }

      for (var i = 0; i < documentPaths.length; i++) {
        final path = documentPaths[i];
        final title = i < documentTitles.length ? documentTitles[i] : '';
        request.fields['land_documents[$i][title]'] = title;
        if (path.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath('land_document_files[$i]', path));
        }
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final responseData = jsonDecode(body) as Map<String, dynamic>;
      if (streamed.statusCode == 200 && responseData['success'] == true) return responseData;
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update land.',
        'errors': responseData['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static String? fileUrl(dynamic value) {
    if (value == null) return null;
    final path = value.toString().trim();
    if (path.isEmpty) return null;
    if (path.startsWith('http://localhost:8000')) {
      return path.replaceFirst('http://localhost:8000', appUrl);
    }
    if (path.startsWith('http://127.0.0.1:8000')) {
      return path.replaceFirst('http://127.0.0.1:8000', appUrl);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) return '$appUrl$path';
    // Common Laravel patterns:
    // - DB stores "storage/..." already (public URL path)
    // - DB stores "public/..." (storage disk path)
    if (path.startsWith('storage/')) return '$appUrl/$path';
    if (path.startsWith('public/')) {
      final withoutPublic = path.substring('public/'.length);
      return '$appUrl/storage/$withoutPublic';
    }
    return '$appUrl/storage/$path';
  }

  // --- Session Management Helpers ---

  static Future<void> _saveSession(
    String token,
    String role, {
    bool rememberMe = true,
  }) async {
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

  /**
   * Verify login OTP and authenticate user session.
   */
  static Future<Map<String, dynamic>> loginVerifyOtp({
    required String email,
    required String otp,
    bool rememberMe = false,
  }) async {
    final url = Uri.parse('$baseUrl/login/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        await _saveSession(
          responseData['token'],
          responseData['user']['role'] != null &&
                  responseData['user']['role'].isNotEmpty
              ? responseData['user']['role'][0].toString()
              : 'customer',
          rememberMe: rememberMe,
        );
        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP verified successfully!',
          'token': responseData['token'],
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Invalid OTP code.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to verify OTP: $e'};
    }
  }

  // --- Chatbot ---

  static Future<Map<String, dynamic>> createChatSession() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/chat/session');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to create session.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getChatSessionMessages(String sessionId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/chat/session/$sessionId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'session_id': data['session_id'],
          'messages': data['messages'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to fetch messages.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendChatMessage(String sessionId, String message) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/chat/send');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'session_id': sessionId,
          'message': message,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'session_id': data['session_id'],
          'messages': data['messages'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to send message.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }


  /**
   * Resend login 2FA OTP.
   */
  static Future<Map<String, dynamic>> sendLoginOtp({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/login/send-otp');
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
      return {'success': false, 'message': 'Failed to resend OTP: $e'};
    }
  }
}
