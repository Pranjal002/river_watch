import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://riverapi-00ta.onrender.com/api";

  static const String loginEndpoint = "$baseUrl/Auth/sign-in";
  static const String stationsEndpoint = "$baseUrl/station-user";
  static const String gaugeReadingEndpoint = "$baseUrl/gauge-reading";

  String? _accessToken;

  Future<void> saveToken(String accessToken) async {
    _accessToken = accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    print("✅ Token Saved Successfully");
  }

  Future<String?> getToken() async {
    if (_accessToken != null) return _accessToken;
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    print(_accessToken != null
        ? "✅ Token loaded from storage"
        : "❌ No token in storage");
    return _accessToken;
  }

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

  Future<void> login(String userName, String password) async {
    print("🔄 Attempting login...");
    final response = await http.post(
      Uri.parse(loginEndpoint),
      headers: {"Content-Type": "application/json", "accept": "*/*"},
      body: jsonEncode({"userName": userName, "password": password}),
    );

    print("📥 Login Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['statusCode'] == 200 && data['data'] != null) {
        await saveToken(data['data']['accessToken']);
        print("🎉 Login Successful - Token Saved");
      } else {
        throw Exception(data['errors']?.toString() ?? "Login failed");
      }
    } else {
      throw Exception("Login Failed: ${response.statusCode}");
    }
  }

  Future<List<dynamic>> getUserStations() async {
    print('🔄 Starting getUserStations()');
    await getToken();
    final userId = getUserIdFromToken();
    print('👤 User ID: $userId');
    if (userId == null) throw Exception("User ID not found in token");

    final token = await getToken();
    if (token == null) throw Exception("No token found");

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
      if (data is Map<String, dynamic>) {
        return [data];
      } else if (data is List) {
        return data;
      } else {
        return [];
      }
    } else {
      throw Exception("Failed to load stations: ${response.statusCode}");
    }
  }

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

  /// ✅ uploadOn added: "2026-03-31" string sent as UploadOn field
  Future<void> submitGaugeReading({
    required String stationUserId,
    required double gaugeReading,
    required int readingTime,
    required String remarks,
    required String uploadOn, // ✅ new: e.g. "2026-03-31"
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
    request.fields['UploadOn'] = uploadOn; // ✅ new field

    if (imageFile != null) {
      if (!await imageFile.exists()) {
        throw Exception("Image file does not exist");
      }
      final fileSize = await imageFile.length();
      if (fileSize == 0) throw Exception("Image file is empty");

      print("📸 Adding image: ${imageFile.path}, Size: $fileSize bytes");

      request.files.add(
        await http.MultipartFile.fromPath(
          'Image',
          imageFile.path,
          contentType: MediaType('image', 'png'),
        ),
      );
    }

    print("===== FINAL REQUEST DATA =====");
    print("GaugeReading: $gaugeReading");
    print("StationUserId: $stationUserId");
    print("ReadingTime: $readingTime");
    print("Remarks: $remarks");
    print("UploadOn: $uploadOn"); // ✅ log it
    print("Image: ${imageFile?.path ?? 'No image'}");
    print("==============================");

    try {
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
    } catch (e) {
      print("❌ Error submitting reading: $e");
      throw Exception("Error submitting reading: ${e.toString()}");
    }
  }

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

  Future<Map<String, dynamic>> getPendingUploads(String stationUserId) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found");

    final url = "$baseUrl/gauge-reading/pending/$stationUserId";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      print(response.body);
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load pending uploads");
    }
  }

  Future<Map<String, dynamic>> getReadingTimeStatus(
      String stationUserId) async {
    print(stationUserId);
    final token = await getToken();
    if (token == null) throw Exception("No token found");

    final fullUrl = "$baseUrl/gauge-reading/reading-time-status/$stationUserId";
    print('🌐 Hitting Reading Status URL: $fullUrl');

    final response = await http.get(
      Uri.parse(fullUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print('📥 Reading Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Reading Status Response: $data');
      return data['data'] ?? {};
    } else {
      throw Exception("Failed to load reading status: ${response.statusCode}");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _accessToken = null;
  }
}
