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

   * Fetch the authenticated buyer's complete profile details.

   */

  static Future<Map<String, dynamic>> getBuyerProfile() async {

    final token = await getToken();

    if (token == null) {

      return {

        'success': false,

        'message': 'Your session has expired. Please sign in again.',

      };

    }



    final url = Uri.parse('$baseUrl/buyer/profile');

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

        'message': responseData['message'] ?? 'Failed to load buyer profile.',

      };

    } catch (e) {

      return {

        'success': false,

        'message': 'Network connection error. Failed to load buyer profile.',

        'error': e.toString(),

      };

    }

  }



  /**

   * Update the authenticated buyer's profile details & verification docs.

   */

  static Future<Map<String, dynamic>> updateBuyerProfile(

    Map<String, dynamic> data, {

    String? frontImagePath,

    String? backImagePath,

    String? profilePicturePath,

  }) async {

    final token = await getToken();

    if (token == null) {

      return {

        'success': false,

        'message': 'Your session has expired. Please sign in again.',

      };

    }



    final url = Uri.parse('$baseUrl/buyer/profile');

    try {

      final request = http.MultipartRequest('POST', url)

        ..headers.addAll({

          'Accept': 'application/json',

          'Authorization': 'Bearer $token',

        });



      data.forEach((key, value) {

        if (value != null) {

          request.fields[key] = value.toString();

        }

      });



      if (frontImagePath != null && frontImagePath.trim().isNotEmpty) {

        request.files.add(await http.MultipartFile.fromPath('front_image', frontImagePath));

      }

      if (backImagePath != null && backImagePath.trim().isNotEmpty) {

        request.files.add(await http.MultipartFile.fromPath('back_image', backImagePath));

      }

      if (profilePicturePath != null && profilePicturePath.trim().isNotEmpty) {

        request.files.add(await http.MultipartFile.fromPath('profile_picture', profilePicturePath));

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

        'message': responseData['message'] ?? 'Failed to update buyer profile.',

        'errors': responseData['errors'],

      };

    } catch (e) {

      return {

        'success': false,

        'message': 'Network connection error. Failed to update buyer profile.',

        'error': e.toString(),

      };

    }

  }

  static Future<Map<String, dynamic>> getDeliveryPartnerProfile() async {
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Your session has expired. Please sign in again.',
      };
    }

    final url = Uri.parse('$baseUrl/delivery/profile');
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
        'message': responseData['message'] ?? 'Failed to load delivery partner profile.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network connection error. Failed to load delivery partner profile.',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> updateDeliveryPartnerProfile(
    Map<String, dynamic> data, {
    String? frontImagePath,
    String? backImagePath,
    String? insuranceImagePath,
    String? revenueLicenseImagePath,
    String? vehicleFrontImagePath,
    String? vehicleBackImagePath,
    String? profilePicturePath,
    List<String>? vehicleOtherImagesPaths,
  }) async {
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Your session has expired. Please sign in again.',
      };
    }

    final url = Uri.parse('$baseUrl/delivery/profile');
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      if (frontImagePath != null && frontImagePath.trim().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('front_image', frontImagePath));
      }
      if (backImagePath != null && backImagePath.trim().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('back_image', backImagePath));
      }
      if (insuranceImagePath != null && insuranceImagePath.trim().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('insurance_image', insuranceImagePath));
      }
      if (revenueLicenseImagePath != null && revenueLicenseImagePath.trim().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('revenue_license_image', revenueLicenseImagePath));
      }
      if (vehicleFrontImagePath != null && vehicleFrontImagePath.trim().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('vehicle_front_image', vehicleFrontImagePath));
      }
      if (vehicleBackImagePath != null && vehicleBackImagePath.trim().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('vehicle_back_image', vehicleBackImagePath));
      }
      if (profilePicturePath != null && profilePicturePath.trim().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('profile_picture', profilePicturePath));
      }
      if (vehicleOtherImagesPaths != null) {
        for (final path in vehicleOtherImagesPaths) {
          if (path.trim().isNotEmpty) {
            request.files.add(await http.MultipartFile.fromPath('vehicle_other_images[]', path));
          }
        }
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final Map<String, dynamic> responseData = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update delivery partner profile.',
        'errors': responseData['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network connection error. Failed to update delivery partner profile.',
        'error': e.toString(),
      };
    }
  }

  /**
   * Fetch the authenticated retail seller's complete profile details.
   */
  static Future<Map<String, dynamic>> getRetailSellerProfile() async {
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Your session has expired. Please sign in again.',
      };
    }

    final url = Uri.parse('$baseUrl/retail-seller/profile');
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
        'message': responseData['message'] ?? 'Failed to load retail seller profile.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network connection error. Failed to load retail seller profile.',
        'error': e.toString(),
      };
    }
  }

  /**
   * Update the authenticated retail seller's profile details & verification docs.
   */
  static Future<Map<String, dynamic>> updateRetailSellerProfile(
    Map<String, dynamic> data, {
    String? brImagePath,
    List<String>? shopPhotosPaths,
    String? profilePicturePath,
  }) async {
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Your session has expired. Please sign in again.',
      };
    }

    final url = Uri.parse('$baseUrl/retail-seller/profile');
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      if (brImagePath != null && brImagePath.trim().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('br_image', brImagePath));
      }

      if (profilePicturePath != null && profilePicturePath.trim().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('profile_picture', profilePicturePath));
      }

      if (shopPhotosPaths != null) {
        for (final path in shopPhotosPaths) {
          if (path.trim().isNotEmpty) {
            request.files.add(await http.MultipartFile.fromPath('shop_photos[]', path));
          }
        }
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final Map<String, dynamic> responseData = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update retail seller profile.',
        'errors': responseData['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network connection error. Failed to update retail seller profile.',
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





  // --- Crop Market Rates ---



  /// Fetch all crops with today's average market rates.

  static Future<Map<String, dynamic>> getCropRates() async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/crop-rates');

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

        'message': data['message'] ?? 'Failed to load crop rates.',

      };

    } catch (e) {

      return {'success': false, 'message': 'Network error: $e'};

    }

  }



  /// Fetch detailed rate info for a single crop.

  static Future<Map<String, dynamic>> getCropRateDetail(int cropId) async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/crop-rates/$cropId');

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

        'message': data['message'] ?? 'Failed to load crop rate details.',

      };

    } catch (e) {

      return {'success': false, 'message': 'Network error: $e'};

    }

  }



  /// Submit or update buyer's today rate for a crop.

  static Future<Map<String, dynamic>> submitCropRate(

      Map<String, dynamic> data) async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/crop-rates');

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

      if ((response.statusCode == 200 || response.statusCode == 201) &&

          responseData['success'] == true) {

        return responseData;

      }

      return {

        'success': false,

        'message': responseData['message'] ?? 'Failed to submit rate.',

        'min_allowed': responseData['min_allowed'],

        'max_allowed': responseData['max_allowed'],

        'current_avg': responseData['current_avg'],

      };

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



  // --- Farmer Harvest Listings ---



  /// Fetch all harvest listings registered by the authenticated farmer.

  static Future<Map<String, dynamic>> getFarmerHarvestListings() async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/farmer/harvest-listings');

    try {

      final response = await http.get(url, headers: {

        'Content-Type': 'application/json',

        'Accept': 'application/json',

        'Authorization': 'Bearer $token',

      });

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) return data;

      return {'success': false, 'message': data['message'] ?? 'Failed to load harvest listings.'};

    } catch (e) {

      return {'success': false, 'message': 'Network error: $e'};

    }

  }



  /// Create a new harvest listing for the farmer.

  static Future<Map<String, dynamic>> createHarvestListing(

    Map<String, dynamic> data, {

    List<String>? images,

  }) async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/farmer/harvest-listings');

    try {

      final request = http.MultipartRequest('POST', url)

        ..headers.addAll({

          'Accept': 'application/json',

          'Authorization': 'Bearer $token',

        });



      data.forEach((key, value) {

        if (value != null) {

          request.fields[key] = value.toString();

        }

      });



      if (images != null) {

        for (int i = 0; i < images.length; i++) {

          final path = images[i];

          if (path.trim().isNotEmpty) {

            request.files.add(await http.MultipartFile.fromPath('image_${i + 1}', path));

          }

        }

      }



      final streamedResponse = await request.send();

      final responseBody = await streamedResponse.stream.bytesToString();

      final Map<String, dynamic> responseData = jsonDecode(responseBody);

      if ((streamedResponse.statusCode == 201 || streamedResponse.statusCode == 200) &&

          responseData['success'] == true) {

        return responseData;

      }

      return {

        'success': false,

        'message': responseData['message'] ?? 'Failed to create listing.',

        'errors': responseData['errors'],

      };

    } catch (e) {

      return {'success': false, 'message': 'Network error: $e'};

    }

  }



  /// Get a single harvest listing.

  static Future<Map<String, dynamic>> getSingleHarvestListing(int id) async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/farmer/harvest-listings/$id');

    try {

      final response = await http.get(url, headers: {

        'Content-Type': 'application/json',

        'Accept': 'application/json',

        'Authorization': 'Bearer $token',

      });

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) return data;

      return {'success': false, 'message': data['message'] ?? 'Failed to load listing.'};

    } catch (e) {

      return {'success': false, 'message': 'Network error: $e'};

    }

  }



  /// Update an existing harvest listing for the farmer.

  static Future<Map<String, dynamic>> updateHarvestListing(

    int id,

    Map<String, dynamic> data, {

    List<String>? images,

    List<String>? keepImages,

  }) async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/farmer/harvest-listings/$id');

    try {

      final request = http.MultipartRequest('POST', url)

        ..headers.addAll({

          'Accept': 'application/json',

          'Authorization': 'Bearer $token',

        });



      data.forEach((key, value) {

        if (value != null) {

          request.fields[key] = value.toString();

        }

      });



      if (keepImages != null) {

        for (int i = 0; i < keepImages.length; i++) {

          request.fields['keep_images[$i]'] = keepImages[i];

        }

      }



      if (images != null) {

        for (int i = 0; i < images.length; i++) {

          final path = images[i];

          if (path.trim().isNotEmpty && !path.startsWith('http') && !path.startsWith('harvest-listings/')) {

            request.files.add(await http.MultipartFile.fromPath('image_${i + 1}', path));

          }

        }

      }



      final streamedResponse = await request.send();

      final responseBody = await streamedResponse.stream.bytesToString();

      final Map<String, dynamic> responseData = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 200 && responseData['success'] == true) {

        return responseData;

      }

      return {

        'success': false,

        'message': responseData['message'] ?? 'Failed to update listing.',

        'errors': responseData['errors'],

      };

    } catch (e) {

      return {'success': false, 'message': 'Network error: $e'};

    }

  }



  /// Get buyer's active harvest listings feed.

  static Future<Map<String, dynamic>> getBuyerHarvestListings() async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/buyer/harvest-listings');

    try {

      final response = await http.get(url, headers: {

        'Content-Type': 'application/json',

        'Accept': 'application/json',

        'Authorization': 'Bearer $token',

      });

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) return data;

      return {'success': false, 'message': data['message'] ?? 'Failed to load harvest listings.'};

    } catch (e) {

      return {'success': false, 'message': 'Network error: $e'};

    }

  }



  /// Place a bid on a harvest listing (Buyer facing).

  static Future<Map<String, dynamic>> placeHarvestBid(int listingId, Map<String, dynamic> data) async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/harvest-listings/$listingId/bids');

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

      if ((response.statusCode == 201 || response.statusCode == 200) && responseData['success'] == true) {

        return responseData;

      }

      return {'success': false, 'message': responseData['message'] ?? 'Failed to place bid.'};

    } catch (e) {

      return {'success': false, 'message': 'Network error: $e'};

    }

  }



  /// Get all incoming bids on the authenticated farmer's harvest listings.

  static Future<Map<String, dynamic>> getFarmerBids() async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/farmer/bids');

    try {

      final response = await http.get(url, headers: {

        'Content-Type': 'application/json',

        'Accept': 'application/json',

        'Authorization': 'Bearer $token',

      });

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) return data;

      return {'success': false, 'message': data['message'] ?? 'Failed to load bids.'};

    } catch (e) {

      return {'success': false, 'message': 'Network error: $e'};

    }

  }



  /// Accept a pending bid (Farmer facing).

  static Future<Map<String, dynamic>> acceptHarvestBid(int bidId) async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/farmer/bids/$bidId/accept');

    try {

      final response = await http.post(url, headers: {

        'Content-Type': 'application/json',

        'Accept': 'application/json',

        'Authorization': 'Bearer $token',

      });

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) return data;

      return {'success': false, 'message': data['message'] ?? 'Failed to accept bid.'};

    } catch (e) {

      return {'success': false, 'message': 'Network error: $e'};

    }

  }



  /// Reject a pending bid (Farmer facing).

  static Future<Map<String, dynamic>> rejectHarvestBid(int bidId) async {

    final token = await getToken();

    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final url = Uri.parse('$baseUrl/farmer/bids/$bidId/reject');

    try {

      final response = await http.post(url, headers: {

        'Content-Type': 'application/json',

        'Accept': 'application/json',

        'Authorization': 'Bearer $token',

      });

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) return data;

      return {'success': false, 'message': data['message'] ?? 'Failed to reject bid.'};

    } catch (e) {

      return {'success': false, 'message': 'Network error: $e'};

    }

  }



  // ===================================================================
  // Chat Methods
  // ===================================================================

  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<Map<String, dynamic>> getChatMessages(int otherUserId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/chats/' + otherUserId.toString());
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ' + (token ?? ''),
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to load messages.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ' + e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendHarvestChatMessage(int receiverId, String message) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/chats/send');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ' + (token ?? ''),
        },
        body: jsonEncode({'receiver_id': receiverId, 'message_text': message}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to send.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ' + e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendHarvestChatMessageWithMedia({
    required int receiverId,
    String? message,
    String? filePath,
    String? mediaType,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/chats/send');
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer ' + (token ?? '');
      request.headers['Accept'] = 'application/json';
      
      request.fields['receiver_id'] = receiverId.toString();
      if (message != null && message.isNotEmpty) {
        request.fields['message_text'] = message;
      }
      if (mediaType != null) {
        request.fields['type'] = mediaType;
      }
      
      if (filePath != null && filePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('media_file', filePath));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        return data;
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to send.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ' + e.toString()};
    }
  }

  // ===================================================================
  // Confirmed Bid Methods
  // ===================================================================

  static Future<Map<String, dynamic>> confirmBid(int bidId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/farmer/confirmed-bids/' + bidId.toString() + '/confirm');
    try {
      final response = await http.post(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ' + (token ?? ''),
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to confirm bid.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ' + e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFarmerConfirmedBids() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/farmer/confirmed-bids');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ' + (token ?? ''),
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ' + e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getBuyerConfirmedBids() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/buyer/confirmed-bids');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ' + (token ?? ''),
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ' + e.toString()};
    }
  }

  // ===================================================================
  // Payment Methods
  // ===================================================================

  static Future<Map<String, dynamic>> initiatePayment(int confirmedBidId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/buyer/confirmed-bids/' + confirmedBidId.toString() + '/initiate-payment');
    try {
      final response = await http.post(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ' + (token ?? ''),
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to initiate payment.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ' + e.toString()};
    }
  }

  static Future<Map<String, dynamic>> confirmPaymentSuccess(int confirmedBidId, String paymentId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/payment/debug-simulate-success');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ' + (token ?? ''),
        },
        body: jsonEncode({
          'confirmed_bid_id': confirmedBidId,
          'payment_id': paymentId,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to record payment.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ' + e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addRole(String role) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/user/add-role');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ' + (token ?? ''),
        },
        body: jsonEncode({'role': role}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to add role.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ' + e.toString()};
    }
  }

  // ===================================================================
  // Review Methods
  // ===================================================================

  static Future<Map<String, dynamic>> submitReview(int confirmedBidId, int rating, String feedback) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/confirmed-bids/' + confirmedBidId.toString() + '/reviews');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ' + (token ?? ''),
        },
        body: jsonEncode({'ratings': rating, 'feedback': feedback}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to submit review.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ' + e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFarmerReviews(int farmerId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/farmers/' + farmerId.toString() + '/reviews');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ' + (token ?? ''),
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to load reviews.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ' + e.toString()};
    }
  }

  // ===================================================================
  // Retailer Product Methods
  // ===================================================================

  static Future<Map<String, dynamic>> getRetailerProducts() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/retailer/products');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to load products.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getRetailerRateLimit(int cropId, String grade) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/retailer/products/rate-limit/$cropId/$grade');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to load rate limits.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createRetailerProduct(
    Map<String, dynamic> data, {
    String? thumbnailPath,
    List<String>? imagesPaths,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/retailer/products');
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      if (thumbnailPath != null && thumbnailPath.trim().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('thumbnail', thumbnailPath));
      }

      if (imagesPaths != null) {
        for (final path in imagesPaths) {
          if (path.trim().isNotEmpty) {
            request.files.add(await http.MultipartFile.fromPath('images[]', path));
          }
        }
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      if (streamedResponse.statusCode == 201 && responseData['success'] == true) {
        return responseData;
      }
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to create product.',
        'errors': responseData['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateRetailerProduct(
    int productId,
    Map<String, dynamic> data, {
    String? thumbnailPath,
    List<String>? imagesPaths,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    // Send POST to the update route with the field mappings to bypass PUT file upload limitations in Laravel
    final url = Uri.parse(baseUrl + '/retailer/products/$productId');
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      if (thumbnailPath != null && thumbnailPath.trim().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('thumbnail', thumbnailPath));
      }

      if (imagesPaths != null) {
        for (final path in imagesPaths) {
          if (path.trim().isNotEmpty) {
            request.files.add(await http.MultipartFile.fromPath('images[]', path));
          }
        }
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      if (streamedResponse.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      }
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update product.',
        'errors': responseData['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteRetailerProduct(int productId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/retailer/products/$productId');
    try {
      final response = await http.delete(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to delete product.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ===================================================================
  // Customer Products & Browsing Methods
  // ===================================================================

  static Future<Map<String, dynamic>> getCustomerProducts({
    double? lat,
    double? lng,
    String? search,
    int? cropId,
    String? grade,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};

    final queryParams = <String, String>{};
    if (lat != null) queryParams['latitude'] = lat.toString();
    if (lng != null) queryParams['longitude'] = lng.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (cropId != null) queryParams['crop_id'] = cropId.toString();
    if (grade != null) queryParams['grade'] = grade;

    final uri = Uri.parse('$baseUrl/customer/products').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to search products.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ===================================================================
  // Customer Orders Checkout & Tracking
  // ===================================================================

  static Future<Map<String, dynamic>> placeCustomerOrder(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/customer/orders');
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
        'message': responseData['message'] ?? 'Failed to place order.',
        'errors': responseData['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCustomerOrders() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/customer/orders');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to load orders.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCustomerOrderDetail(int orderId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse(baseUrl + '/customer/orders/$orderId');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed to load order details.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> calculateDelivery({
    required double lat,
    required double lng,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/customer/orders/calculate-delivery');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'delivery_latitude': lat,
          'delivery_longitude': lng,
          'cart_items': cartItems,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> initiateRetailOrderPayment(int orderId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/customer/orders/$orderId/initiate-payment');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> confirmRetailOrderPaymentSuccess(int orderId, String paymentId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/payment/debug-simulate-retail-order-success');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'payment_id': paymentId,
        }),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ===================================================================
  // Delivery Partner Methods
  // ===================================================================

  static Future<Map<String, dynamic>> updateDeliveryLocation(double lat, double lng) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/delivery/location');
    try {
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'latitude': lat, 'longitude': lng}));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getNearbyDeliveryOrders() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/delivery/nearby-orders');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> acceptDeliveryRequest(int requestId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/delivery/requests/$requestId/accept');
    try {
      final response = await http.post(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> rejectDeliveryRequest(int requestId, {String reason = ''}) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/delivery/requests/$requestId/reject');
    try {
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'reason': reason}));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMyDeliveries() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/delivery/my-deliveries');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateDeliveryStatus(
    int orderId, {
    required String status,
    required double latitude,
    required double longitude,
    String note = '',
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/delivery/orders/$orderId/update-status');
    try {
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'status': status,
            'latitude': latitude,
            'longitude': longitude,
            'note': note,
          }));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDeliveryEarnings() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/delivery/earnings');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ===================================================================
  // Customer Order Tracking
  // ===================================================================

  static Future<Map<String, dynamic>> trackOrder(int orderId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/customer/orders/$orderId/track');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String bankName,
    required String bankBranch,
    required String bankAccountHolderName,
    required String bankAccountNumber,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/delivery/withdraw');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'bank_name': bankName,
          'bank_branch': bankBranch,
          'bank_account_holder_name': bankAccountHolderName,
          'bank_account_number': bankAccountNumber,
        }),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ===================================================================
  // 🧪 DEBUG / TESTING: Create a test nearby delivery request
  // ===================================================================

  static Future<Map<String, dynamic>> debugCreateTestDeliveryRequest() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/delivery/debug-create-test-request');
    try {
      final response = await http.post(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ===================================================================
  // Order Feedback & Reviews
  // ===================================================================

  static Future<Map<String, dynamic>> getRetailerOrders() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/retailer/orders');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitOrderReview({
    required int orderId,
    required int reviewedTo,
    required int ratings,
    required String feedback,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/orders/$orderId/reviews');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reviewed_to': reviewedTo,
          'ratings': ratings,
          'feedback': feedback,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getOrderReviews(int orderId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Session expired.'};
    final url = Uri.parse('$baseUrl/orders/$orderId/reviews');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
