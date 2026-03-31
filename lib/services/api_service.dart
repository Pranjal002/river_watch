import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://riverapi-00ta.onrender.com/api";

  static const String loginEndpoint = "$baseUrl/Auth/sign-in";
  static const String stationsEndpoint = "$baseUrl/station-user";
  static const String gaugeReadingEndpoint =
      "$baseUrl/gauge-reading"; // New endpoint

  String? _accessToken;

  // Save Token
  Future<void> saveToken(String accessToken) async {
    _accessToken = accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    print("✅ Token Saved Successfully");
  }

  // Get Token (with force reload from storage)
  Future<String?> getToken() async {
    if (_accessToken != null) return _accessToken;
    print(_accessToken);
    print('fsaf');
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');

    print(_accessToken != null
        ? "✅ Token loaded from storage"
        : "❌ No token in storage");
    return _accessToken;
  }

  // ====================== JWT DECODE ======================
  String? getUserIdFromToken() {
    final token = _accessToken;
    if (token == null) {
      print("❌ No token available for decoding");
      return null;
    }

    try {
      final parts = token.split('.');
      final payloadString =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payload = jsonDecode(payloadString);

      print("🔍 JWT Payload: $payload");

      final userId = payload['id']?.toString();
      print("✅ Extracted User ID: $userId");

      return userId;
    } catch (e) {
      print("❌ JWT Decode Error: $e");
      return null;
    }
  }

  // ====================== LOGIN ======================
  Future<void> login(String userName, String password) async {
    print("🔄 Attempting login...");
    final response = await http.post(
      Uri.parse(loginEndpoint),
      headers: {"Content-Type": "application/json", "accept": "*/*"},
      body: jsonEncode({"userName": userName, "password": password}),
    );

    print("📥 Login Response: ${response.body}");

    if (response.statusCode == 200) {
      print('gfb ssssd');

      final data = jsonDecode(response.body);
      print('gfb2222 sd');
      print(data);

      if (data['statusCode'] == 200 && data['data'] != null) {
        print('gfb sd');
        await saveToken(data['data']['accessToken']);
        print("🎉 Login Successful - Token Saved");
      } else {
        throw Exception(data['errors']?.toString() ?? "Login failed");
      }
    } else {
      throw Exception("Login Failed: ${response.statusCode}");
    }
  }

  // ====================== GET USER STATIONS ======================
  Future<List<dynamic>> getUserStations() async {
    print('🔄 Starting getUserStations()');

    await getToken();

    final userId = getUserIdFromToken();
    print('👤 User ID: $userId');

    if (userId == null) {
      throw Exception("User ID not found in token");
    }

    final token = await getToken();
    if (token == null) {
      throw Exception("No token found");
    }

    final fullUrl = "$stationsEndpoint/user/$userId";
    print('🌐 Hitting URL: $fullUrl');

    final response = await http.get(
      Uri.parse(fullUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print('📥 Response Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Stations Response: $data');

      // FIXED: Your API returns a single object, not wrapped in 'data' array
      // So we wrap it in a list so the rest of the app works smoothly
      if (data is Map<String, dynamic>) {
        return [data]; // ← Convert single object to List with one item
      } else if (data is List) {
        return data;
      } else {
        return [];
      }
    } else {
      print('❌ Failed with status: ${response.statusCode} - ${response.body}');
      throw Exception("Failed to load stations: ${response.statusCode}");
    }
  }

  // ====================== GET READINGS ======================
  Future<List<dynamic>> getReadings(String stationId) async {
    final token = await getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("$baseUrl/readings/$stationId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    }
    return [];
  }

  /// ====================== SUBMIT GAUGE READING (Clean & Fixed) ======================
  Future<void> submitGaugeReading({
    required String stationUserId,
    required double gaugeReading,
    required int readingTime, // 1=Morning, 2=Evening, 3=Night
    required String remarks,
    File? imageFile,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found");

    var request =
        http.MultipartRequest('POST', Uri.parse(gaugeReadingEndpoint));
    request.headers['Authorization'] = "Bearer $token";

    // Form fields
    request.fields['GaugeReading'] = gaugeReading.toString();
    request.fields['StationUserId'] = stationUserId;
    request.fields['ReadingTime'] = readingTime.toString();
    request.fields['Remarks'] = remarks;

    // Image (if provided)
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'Image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'), // 🔥 FORCE TYPE
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("📤 Submit Status: ${response.statusCode}");
    print("📥 Response Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Gauge Reading Submitted Successfully");
    } else {
      throw Exception(
          "Failed to submit gauge reading: ${response.statusCode} - ${response.body}");
    }
  }

  // ====================== UPLOAD PHOTO (Keep if needed elsewhere) ======================
  Future<String> uploadPhoto(File file, String stationId) async {
    final token = await getToken();
    if (token == null) throw Exception("No token");

    var request =
        http.MultipartRequest('POST', Uri.parse("$baseUrl/upload/photo"));
    request.headers['Authorization'] = "Bearer $token";
    request.files.add(await http.MultipartFile.fromPath('photo', file.path));
    request.fields['stationId'] = stationId;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['photoUrl'] ?? '';
    } else {
      throw Exception("Photo upload failed");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _accessToken = null;
  }
}
