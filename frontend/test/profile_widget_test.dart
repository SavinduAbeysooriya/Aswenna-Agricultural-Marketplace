import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aswenna/screens/dashboards/delivery_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MockHttpOverrides();

  testWidgets('Render DeliveryProfileScreen and catch layout/runtime errors on success data', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_token_123',
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: DeliveryProfileScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(DeliveryProfileScreen), findsOneWidget);
  });
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => MockHttpClientRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => MockHttpClientRequest(url);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null; // fallback for set/get fields
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  final Uri url;
  MockHttpClientRequest(this.url);

  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #done) return Future.value(null);
    return null;
  }
}

class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final data = utf8.encode(jsonEncode({
      "success": true,
      "profile": {
        "user": {
          "id": 5,
          "full_name": "Nuwara Courier Express",
          "email": "nuwara@courier.com",
          "phone_number": "0777456789",
          "phone_number_2": null,
          "national_id": null,
          "address": "Nuwara Eliya",
          "city": "Nuwara Eliya",
          "district": "Nuwara Eliya",
          "province": "Central",
          "latitude": null,
          "longitude": null,
          "profile_picture_path": null
        },
        "verification_data": {
          "id": 1,
          "user_id": 5,
          "status": "verified",
          "driving_license_expiry_date": "2029-06-03",
          "vehicle_type": "motorcycle",
          "vehicle_make": null,
          "model": null,
          "year": null,
          "color": null,
          "registration_number": null,
          "insurance_image_path": null,
          "revenue_license_image_path": null,
          "insurance_expiry": null,
          "revenue_license_expiry": null,
          "vehicle_front_image": null,
          "vehicle_back_image": null,
          "max_weight": null
        },
        "documents": []
      }
    }));
    return Stream<List<int>>.fromIterable([data]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}
