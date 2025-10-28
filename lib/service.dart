import 'dart:io';

import 'package:fireforest_project/model/%E0%B9%8Bjoin_model.dart';
import 'package:fireforest_project/model/assign_dto.dart';
import 'package:fireforest_project/model/fire_forest_detail_request.dart';
import 'package:fireforest_project/model/fireforest_model.dart';
import 'package:fireforest_project/model/firepicture_model.dart';
import 'package:fireforest_project/model/history_model.dart';
import 'package:fireforest_project/model/join_member_model.dart';
import 'package:fireforest_project/model/recruit_model.dart';
import 'package:fireforest_project/model/user_model.dart';
import 'package:fireforest_project/model/volunteer_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class Service {
  //static const String baseUrl = "http://25.28.30.17:8080";
  static const String baseUrl = "http://192.168.1.37:8080";
  //static const String baseUrl = "http://172.16.1.29:8080";

  //login
  Future<http.Response> loginUser(String email, String password) async {
    var uri = Uri.parse("$baseUrl/login"); // เปลี่ยนตาม IP ของคุณ

    Map<String, String> headers = {"Content-Type": "application/json"};
    Map<String, String> data = {'email': email, 'password': password};

    var body = json.encode(data);
    print("Login Body: $body");

    try {
      var response = await http.post(uri, headers: headers, body: body);
      print("Login Response: ${response.body}");
      return response;
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  Future<http.Response> loginAgency(String email, String password) async {
    var uri = Uri.parse("$baseUrl/loginagency"); // เปลี่ยนตาม IP ของคุณ
    Map<String, String> headers = {"Content-Type": "application/json"};
    Map<String, String> data = {'email': email, 'password': password};

    var body = json.encode(data);
    print("Login Body: $body");

    try {
      var response = await http.post(uri, headers: headers, body: body);
      print("Login Response: ${response.body}");
      return response;
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  Future<http.Response> saveUser(
    String email,
    String fname,
    String lname,
    String gender,
    String birthday,
    String address,
    String password,
    String tel,
  ) async {
    var uri = Uri.parse("$baseUrl/register"); // use internet ipconfig
    Map<String, String> headers = {"Content-Type": "application/json"};

    Map<String, dynamic> data = {
      'userEmail': email,
      'userFname': fname,
      'userLname': lname,
      'userGender': gender,
      'userBirthDay': birthday,
      'userAddress': address,
      'userPassword': password,
      'userTel': tel,
    };

    var body = json.encode(data);

    print("URI: $uri");
    print("HEADERS: $headers");
    print("BODY: $body");

    try {
      var response = await http.post(uri, headers: headers, body: body);
      print("STATUS: ${response.statusCode}");
      print("RESPONSE: ${response.body}");
      return response;
    } catch (e) {
      print("ERROR: $e");
      rethrow;
    }
  }

  static Future<UserModel?> fetchUser(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/user/$id"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserModel.fromJson(data);
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      var uri = Uri.parse("$baseUrl/user/$email");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // แปลง JSON เป็น Map
        return jsonDecode(response.body);
      } else {
        print("Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }

  // ใน service.dart
  Future<UserModel> getUserByEmailJson(String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return UserModel.fromJson(json); // ✅ return UserModel แทน Map
      } else {
        throw Exception('Failed to load user');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    try {
      var uri = Uri.parse("$baseUrl/edit/$id");
      final response = await http.put(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      print("Update user id: $id");
      print("Update user data: $data");

      return response.statusCode == 200;
    } catch (e) {
      print("Update error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> saveFireForest(
    FireforestModel report,
    List<String> pictureUrls,
    String userEmail,
  ) async {
    var uri = Uri.parse("$baseUrl/fireforest");

    Map<String, String> headers = {"Content-Type": "application/json"};

    Map<String, dynamic> data = {
      "fireForest": report.toJson(),
      "pictures": pictureUrls,
      "userEmail": userEmail,
    };

    print("📤 JSON ที่ส่ง: ${jsonEncode(data)}");

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      print("✅ Response: $resData");
      return resData;
    } else {
      print("❌ Error: ${response.body}");
      throw Exception("Failed to save fire forest: ${response.body}");
    }
  }

  Future<String> uploadImage(File file) async {
    final uri = Uri.parse("$baseUrl/upload");
    final request = http.MultipartRequest('POST', uri);

    String filename = file.path.split('/').last;
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path, filename: filename),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // ✅ ใช้ 'filename' ที่ backend ส่งกลับ
      return data['filename'];
    } else {
      throw Exception('Failed to upload image: ${response.body}');
    }
  }

  Future<List<FirePictureModel>> getFirePictures(int fireForestId) async {
    final uri = Uri.parse("$baseUrl/firepicture/$fireForestId");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List jsonData = json.decode(response.body);
      return jsonData.map((e) => FirePictureModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load pictures');
    }
  }

  // ดึง thumbnail
  Future<List<FirePictureModel>> getFirePicturesThumbnails(
    int fireForestId,
  ) async {
    final uri = Uri.parse(
      "$baseUrl/fireforest/$fireForestId/pictures/thumbnails",
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => FirePictureModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load thumbnails');
  }

  static Future<String?> getAddressFromLatLng(double lat, double lng) async {
    try {
      final url = Uri.parse("$baseUrl/fireforest/reverse?lat=$lat&lng=$lng");
      final response = await http.post(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["address"] ?? "ไม่พบที่อยู่";
      } else {
        print("Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception in getAddressFromLatLng: $e");
      return null;
    }
  }

  Future<List<FireforestModel>> getAllFireForests() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/fireforest'));

      if (response.statusCode == 200) {
        final dynamic rawResponse = json.decode(response.body);

        if (rawResponse is Map) {
          final Map<String, dynamic> jsonResponse = Map<String, dynamic>.from(
            rawResponse,
          );
          final List<dynamic> data = jsonResponse['data'];
          return data
              .map(
                (json) =>
                    FireforestModel.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load fire forests');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<FireforestModel>> getFireForestByEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fireforest/user/$email'),
      );

      if (response.statusCode == 200) {
        final dynamic rawResponse = jsonDecode(response.body);

        // ตรวจสอบว่าเป็น List หรือมี key data
        final List<dynamic> rawList;

        if (rawResponse is Map) {
          final Map<String, dynamic> jsonResponse = Map<String, dynamic>.from(
            rawResponse,
          );
          rawList =
              jsonResponse.containsKey('data') ? jsonResponse['data'] : [];
        } else if (rawResponse is List) {
          rawList = rawResponse;
        } else {
          rawList = [];
        }

        final List<Map<String, dynamic>> validItems =
            rawList
                .where((item) => item is Map)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();

        print(validItems);
        return validItems
            .map((item) => FireforestModel.fromJson(item))
            .toList();
      } else {
        throw Exception(
          'Failed to load data for email $email (status: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Error fetching fire forest by email: $e');
    }
  }

  Future<http.Response> saveRecruitForm(
    String startDate,
    String endDate,
    int max,
    String description,
    String recruitLocation,
    String agencyEmail,
  ) async {
    var uri = Uri.parse("$baseUrl/recruit"); // use internet ipconfig
    Map<String, String> headers = {"Content-Type": "application/json"};

    Map<String, dynamic> data = {
      'startDate': startDate,
      'endDate': endDate,
      'max': max,
      'description': description,
      'recruitLocation': recruitLocation,
      'agencyEmail': {'agencyEmail': agencyEmail},
    };

    var body = json.encode(data);

    print("URI: $uri");
    print("HEADERS: $headers");
    print("BODY: $body");

    try {
      var response = await http.post(uri, headers: headers, body: body);
      print("STATUS: ${response.statusCode}");
      print("RESPONSE: ${response.body}");
      return response;
    } catch (e) {
      print("ERROR: $e");
      rethrow;
    }
  }

  Future<List<RecruitModel>> getAllRecruit() async {
    final response = await http.get(Uri.parse('$baseUrl/recruit'));

    if (response.statusCode == 200) {
      print(response.body);
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.map((e) => RecruitModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch recruit');
    }
  }

  Future<List<RecruitModel>> getVisibleRecruit() async {
    var uri = Uri.parse("$baseUrl/recruit/visible");
    var response = await http.get(uri);

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((e) => RecruitModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load recruit");
    }
  }

  Future<bool> updateRecruitVisibility(int id, bool isVisible) async {
    var uri = Uri.parse("$baseUrl/recruit/$id/visibility");
    var response = await http.put(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"isVisible": isVisible}),
    );
    return response.statusCode == 200;
  }

  Future<int?> saveApplyForm(
    String congenitalDiseases,
    String allergicFood,
    int recruitId,
  ) async {
    var uri = Uri.parse("$baseUrl/applyform");
    Map<String, String> headers = {"Content-Type": "application/json"};

    Map<String, dynamic> data = {
      'congenitalDiseases': congenitalDiseases,
      'allergicFood': allergicFood,
      'recruit_form': {'recruitId': recruitId},
    };

    var body = json.encode(data);

    try {
      var response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = json.decode(response.body);
        int applyId = responseData['applyId'];
        print("Last ApplyForm ID: $applyId");
        return applyId;
      } else {
        print("Save failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("ERROR: $e");
      rethrow;
    }
  }

  Future<void> saveApplyFormWithVolunteer(
    String congenitalDiseases,
    String allergicFood,
    int recruitId,
    String userEmail,
    double weight,
    double height,
    String talent,
    bool isTraining,
  ) async {
    int? applyId = await saveApplyForm(
      congenitalDiseases,
      allergicFood,
      recruitId,
    );

    if (applyId != null) {
      // ตอนส่ง volunteer ก็ส่ง applyId ไปด้วย
      var uri = Uri.parse("$baseUrl/volunteer/$userEmail");
      Map<String, String> headers = {"Content-Type": "application/json"};
      var exp = 1;

      Map<String, dynamic> data = {
        'weight': weight,
        'height': height,
        'talent': talent,
        'isTraining': isTraining,
        'experience': {'experienceId': exp},
        'applyForm': {'applyFormId': applyId},
      };

      var body = json.encode(data);
      var response = await http.post(uri, headers: headers, body: body);

      print("Volunteer STATUS: ${response.statusCode}");
      print("Volunteer RESPONSE: ${response.body}");
    }
  }

  Future<List<VolunteerModel>> getAllVolunteers() async {
    final response = await http.get(Uri.parse("$baseUrl/volunteers"));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => VolunteerModel.fromJson(json)).toList();
    } else if (response.statusCode == 204) {
      return []; // ไม่มีข้อมูล
    } else {
      throw Exception("Failed to load volunteers: ${response.body}");
    }
  }

  Future<List<VolunteerModel>> getVolunteersByRecruitId(int recruitId) async {
    final url = Uri.parse("$baseUrl/volunteer/recruit/$recruitId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);

        // แปลงเป็น VolunteerModel และกรอง volunteerStatus
        List<VolunteerModel> volunteers =
            jsonList
                .map((jsonItem) => VolunteerModel.fromJson(jsonItem))
                .where(
                  (volunteer) => volunteer.volunteerStatus == "รอการตรวจสอบ",
                )
                .toList();

        return volunteers;
      } else {
        print("Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Exception: $e");
      return [];
    }
  }

  Future<bool> updateVolunteerStatus(String userEmail, String status) async {
    final uri = Uri.parse("$baseUrl/volunteer/$userEmail/status");
    final headers = {"Content-Type": "application/json"};
    final body = json.encode({"volunteerStatus": status});

    try {
      final response = await http.put(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("อัปเดต $userEmail เป็น $status สำเร็จ");
        return true;
      } else {
        print("อัปเดตไม่สำเร็จ: ${response.statusCode} ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }

  /// ตัวช่วยอัปเดตหลายคนพร้อมกัน (bulk)
  Future<void> updateMultipleVolunteers(
    List<VolunteerModel> volunteers,
    String status,
  ) async {
    for (var v in volunteers) {
      await updateVolunteerStatus(v.userEmail, status);
    }
  }

  Future<String> getVolunteerStatus(String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/volunteer/status?userEmail=$userEmail"),
      );

      if (response.statusCode == 200) {
        return response.body; // คืนค่าเป็น String เช่น "รอการตรวจสอบ"
      } else {
        return "ไม่มีข้อมูล";
      }
    } catch (e) {
      print("Error fetching volunteer status: $e");
      return "ไม่มีข้อมูล";
    }
  }

  // มอบหมายงานแบบเจาะจง
  Future<String> assignVolunteer(String userEmail, int fireForestId) async {
    final url = Uri.parse(
      "$baseUrl/assign/volunteer?userEmail=$userEmail&fireForestId=$fireForestId",
    );
    final response = await http.post(url);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception("เกิดข้อผิดพลาดในการมอบหมายงาน");
    }
  }

  // มอบหมายงานหลายคนพร้อมกัน

  Future<String> assignMultipleVolunteers(AssignDTO dto) async {
    final url = Uri.parse("$baseUrl/assign/");
    final body = jsonEncode(dto.toJson());

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        print("Response: ${response.body}");
        return response.body;
      } else {
        print("Failed with status: ${response.statusCode}");
        return "Failed with status: ${response.statusCode}";
      }
    } catch (e) {
      print("Error assigning multiple volunteers: $e");
      return "Error: $e";
    } finally {
      print("=== Assign Multiple Finished ===");
    }
  }

  Future<bool> hasActiveJob(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/volunteer/active/$email'),
    );
    if (response.statusCode == 200) {
      return response.body.toLowerCase() == 'true';
    } else {
      throw Exception('Failed to check active job');
    }
  }

  Future<String> acceptTask(JoinRequest req) async {
    final url = Uri.parse("$baseUrl/join/accept");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(req.toJson()),
    );

    if (res.statusCode == 200) {
      return res.body;
    } else {
      throw Exception("รับงานไม่สำเร็จ: ${res.body}");
    }
  }

  Future<FireForestDetail> createFireForestDetail(
    FireForestDetail request,
  ) async {
    try {
      print('🏗️ Creating FireForestDetail...');
      print('📊 Request data: ${request.toJson()}');

      final url = Uri.parse('$baseUrl/fire_detail/create');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );

      print('📥 Create Response Status: ${response.statusCode}');
      print('📥 Create Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final dynamic rawResponseData = json.decode(response.body);

          // ✅ แก้ไข: Cast เป็น Map<String, dynamic>
          if (rawResponseData is Map) {
            final Map<String, dynamic> responseData = Map<String, dynamic>.from(
              rawResponseData,
            );

            // ✅ ตรวจสอบว่า Backend ส่ง object หรือ success message
            if (responseData.containsKey('fireForestId')) {
              // Backend ส่งกลับ FireForestDetail object
              return FireForestDetail.fromJson(responseData);
            } else if (responseData.containsKey('success')) {
              // Backend ส่งกลับ success message พร้อม fireForestId
              return FireForestDetail(
                fireForestId:
                    responseData['fireForestId'] ?? request.fireForestId,
                fireStatus: request.fireStatus,
                assessDamage: request.assessDamage,
                summarize: request.summarize,
                requiredVolunteers: request.requiredVolunteers,
                openForVolunteer: request.openForVolunteer,
                fireForest: request.fireForest,
                agency: request.agency,
              );
            } else {
              throw Exception('Invalid response format: $responseData');
            }
          } else {
            throw Exception('Response is not a Map: $rawResponseData');
          }
        } catch (jsonError) {
          print('⚠️ JSON Parse Error in createFireForestDetail: $jsonError');
          print('📄 Raw Response: ${response.body}');

          // ✅ Fallback: ถ้า parse ไม่ได้แต่ status 200 ให้ return request เดิม
          if (response.body.toLowerCase().contains('สำเร็จ') ||
              response.body.toLowerCase().contains('success')) {
            print('✅ Fallback: Returning original request');
            return request; // ส่งกลับ request เดิมถ้าสำเร็จ
          } else {
            throw Exception('Failed to parse response: $jsonError');
          }
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('💥 Exception in createFireForestDetail: $e');
      throw Exception('Failed to create FireForestDetail: $e');
    }
  }

  Future<List<FireForestDetail>> getAllFireForestDetails() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/fire_detail/list'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body); // แก้ตรงนี้
        return data.map((json) => FireForestDetail.fromJson(json)).toList();
      } else if (response.statusCode == 204) {
        return []; // ไม่มีข้อมูล
      } else {
        throw Exception('Failed to load fire forests');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<VolunteerModel>> getVolunteersByFireForest(
    int fireForestId,
  ) async {
    final url = Uri.parse('$baseUrl/fire_detail/$fireForestId/volunteers');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => VolunteerModel.fromJson(json)).toList();
    } else if (response.statusCode == 204) {
      return []; // ไม่มีข้อมูล
    } else {
      throw Exception('Failed to load volunteers: ${response.body}');
    }
  }

  Future<List<JoinMemberModel>> getAssignedTasksByVolunteer(
    String email,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/join/volunteer/$email/assigned");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((json) => JoinMemberModel.fromJson(json)).toList();
      } else {
        throw Exception("เกิดข้อผิดพลาด: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("เกิดข้อผิดพลาด: $e");
    }
  }

  Future<List<JoinMemberModel>> getPendingTasksByVolunteer(String email) async {
    try {
      final url = Uri.parse("$baseUrl/join/volunteer/$email/pending");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((json) => JoinMemberModel.fromJson(json)).toList();
      } else {
        throw Exception("เกิดข้อผิดพลาด: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("เกิดข้อผิดพลาด: $e");
    }
  }

  Future<List<JoinMemberModel>> getNoPendingTasksByVolunteer(
    String email,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/join/volunteer/$email/no/pending");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((json) => JoinMemberModel.fromJson(json)).toList();
      } else {
        throw Exception("เกิดข้อผิดพลาด: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("เกิดข้อผิดพลาด: $e");
    }
  }

  Future<List<JoinMemberModel>> getAllFireForestDetailsWithNoPending() async {
    try {
      final url = Uri.parse("$baseUrl/fire_detail/list/no/pending");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((json) => JoinMemberModel.fromJson(json)).toList();
      } else {
        throw Exception("เกิดข้อผิดพลาด: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("เกิดข้อผิดพลาด: $e");
    }
  }

  // อัปเดต workStatus จาก "pending" เป็น "accepted" เมื่อ accept งาน
  Future<String> acceptAssignedTask(
    int fireForestId,
    String volunteerEmail,
  ) async {
    final url = Uri.parse("$baseUrl/join/accept");
    final body = json.encode({
      "fireForestId": fireForestId,
      "volunteerEmail": volunteerEmail,
      "workStatus": "assigned",
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Failed to accept assigned task: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error accepting assigned task: $e");
    }
  }

  Future<FireforestModel?> getFireForestById(int fireForestId) async {
    final url = Uri.parse('$baseUrl/fireforest/$fireForestId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return FireforestModel.fromJson(data);
    } else {
      return null;
    }
  }

  Future<FireForestDetail> submitSummaryReport(
    int id,
    FireForestDetail detail,
  ) async {
    final url = Uri.parse("$baseUrl/fire_detail/summary/report/$id");
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(detail.toJson()),
    );

    if (response.statusCode == 200) {
      return FireForestDetail.fromJson(json.decode(response.body));
    } else {
      throw Exception("เกิดข้อผิดพลาด: ${response.statusCode}");
    }
  }

  Future<List<HistoryModel>> getVolunteerHistory(String email) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/history/$email'));

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => HistoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      throw Exception('Error getting history: $e');
    }
  }

  // เพิ่มใน lib/service.dart
  Future<List<Map<String, dynamic>>> getRecentFireReports(
    DateTime? since,
  ) async {
    final uri = Uri.parse(
      "$baseUrl/fireforest/recent${since != null ? '?since=${since.toIso8601String()}' : ''}",
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ...existing code...

  /// ✅ ดึงข้อมูล Volunteer พร้อม Experience
  Future<VolunteerModel?> getVolunteerByEmail(String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/volunteer/id/$userEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔍 Getting volunteer by email: $userEmail');
      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VolunteerModel.fromJson(data);
      } else if (response.statusCode == 404) {
        print('❌ Volunteer not found: $userEmail');
        return null;
      } else {
        print('❌ Failed to get volunteer: ${response.statusCode}');
        throw Exception('Failed to get volunteer: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting volunteer: $e');
      throw Exception('Error getting volunteer: $e');
    }
  }

  /// ✅ อัพเดท Experience Level ใหม่
  Future<Map<String, dynamic>> updateVolunteerExperience(
    String userEmail,
    int experienceId,
  ) async {
    try {
      print(
        '🔄 Updating volunteer experience: $userEmail -> Level $experienceId',
      );

      final response = await http.put(
        Uri.parse('$baseUrl/volunteer/$userEmail/experience'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'experienceId': experienceId}),
      );

      print('📡 Update experience response status: ${response.statusCode}');
      print('📄 Update experience response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Experience updated successfully: $data');
        return data;
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception('Bad Request: ${errorData.toString()}');
      } else if (response.statusCode == 404) {
        throw Exception('Volunteer not found');
      } else {
        final errorBody =
            response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception('Failed to update experience: $errorBody');
      }
    } catch (e) {
      print('❌ Error updating volunteer experience: $e');
      throw Exception('Error updating experience: $e');
    }
  }

  /// ✅ นับจำนวนประวัติการทำงานของอาสาสมัคร
  Future<int> getVolunteerHistoryCount(String userEmail) async {
    try {
      print('📊 Getting history count for: $userEmail');

      final response = await http.get(
        Uri.parse('$baseUrl/history/count/$userEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 History count response status: ${response.statusCode}');
      print('📄 History count response body: ${response.body}');

      if (response.statusCode == 200) {
        // Backend ส่งมาเป็น Long (number) โดยตรง
        final count = int.parse(response.body.trim());
        print('✅ History count: $count');
        return count;
      } else {
        print('❌ Failed to get history count: ${response.statusCode}');
        throw Exception('Failed to get history count: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting history count: $e');
      // Return 0 เป็น fallback แทนการ throw error
      return 0;
    }
  }

  /// ✅ อัพเดท Experience Level อัตโนมัติตาม History
  Future<void> updateVolunteerExperienceLevel(String userEmail) async {
    try {
      print('🤖 Auto-updating experience level for: $userEmail');

      // 1. ดึงจำนวนประวัติการทำงาน
      int historyCount = await getVolunteerHistoryCount(userEmail);
      print('📊 History count: $historyCount');

      // 2. คำนวณ experience level ใหม่
      int newExperienceId = 1; // Default: เริ่มต้น

      if (historyCount > 4) {
        newExperienceId = 3; // มีประสบการณ์สูง
      } else if (historyCount > 2) {
        newExperienceId = 2; // มีประสบการณ์
      }

      print('🎯 Calculated new experience level: $newExperienceId');

      // 3. ตรวจสอบ experience ปัจจุบัน
      VolunteerModel? volunteer = await getVolunteerByEmail(userEmail);
      if (volunteer == null) {
        throw Exception('Volunteer not found: $userEmail');
      }

      int currentExperienceId = volunteer.experience?.experienceId ?? 1;
      print('🔍 Current experience ID: $currentExperienceId');

      // 4. ถ้า experience level เหมือนเดิม ไม่ต้องอัพเดท
      if (newExperienceId == currentExperienceId) {
        print('✅ Experience level unchanged, no update needed');
        return;
      }

      // 5. อัพเดท experience level ใหม่
      final result = await updateVolunteerExperience(
        userEmail,
        newExperienceId,
      );

      print('✅ Experience level updated successfully:');
      print('   - From Level $currentExperienceId to Level $newExperienceId');
      print('   - Based on $historyCount completed tasks');
      print('   - Result: $result');
    } catch (e) {
      print('❌ Error auto-updating experience level: $e');
      throw Exception('Error updating experience level: $e');
    }
  }

  /// ✅ ดึงข้อมูล Experience Level ปัจจุบันพร้อมข้อมูลเพิ่มเติม
  Future<Map<String, dynamic>> getVolunteerExperienceInfo(
    String userEmail,
  ) async {
    try {
      // ดึงข้อมูล volunteer และ history count พร้อมกัน
      final futures = await Future.wait([
        getVolunteerByEmail(userEmail),
        getVolunteerHistoryCount(userEmail),
      ]);

      final volunteer = futures[0] as VolunteerModel?;
      final historyCount = futures[1] as int;

      if (volunteer == null) {
        throw Exception('Volunteer not found');
      }

      // คำนวณ experience level ที่ควรจะเป็น
      int expectedExperienceId = 1;
      if (historyCount > 4) {
        expectedExperienceId = 3;
      } else if (historyCount > 2) {
        expectedExperienceId = 2;
      }

      // ข้อมูล experience ปัจจุบัน
      final currentExperienceId = volunteer.experience?.experienceId ?? 1;
      final experienceName = volunteer.experience?.experienceType ?? 'เริ่มต้น';

      return {
        'volunteer': volunteer,
        'currentExperienceId': currentExperienceId,
        'experienceName': experienceName,
        'historyCount': historyCount,
        'expectedExperienceId': expectedExperienceId,
        'needsUpdate': currentExperienceId != expectedExperienceId,
        'experienceText': _getExperienceText(currentExperienceId),
        'nextLevelRequirement': _getNextLevelRequirement(currentExperienceId),
      };
    } catch (e) {
      print('❌ Error getting volunteer experience info: $e');
      throw Exception('Error getting experience info: $e');
    }
  }

  /// ✅ Helper: แปลง experience ID เป็นข้อความ
  String _getExperienceText(int experienceId) {
    switch (experienceId) {
      case 3:
        return 'มีประสบการณ์สูง';
      case 2:
        return 'มีประสบการณ์';
      case 1:
      default:
        return 'เริ่มต้น';
    }
  }

  /// ✅ Helper: ข้อความความต้องการสำหรับเลเวลถัดไป
  String _getNextLevelRequirement(int currentExperienceId) {
    switch (currentExperienceId) {
      case 1:
        return 'ทำงานให้เสร็จ 3 งานเพื่อขึ้นเป็น "มีประสบการณ์"';
      case 2:
        return 'ทำงานให้เสร็จ 5 งานเพื่อขึ้นเป็น "มีประสบการณ์สูง"';
      case 3:
      default:
        return 'คุณอยู่ในระดับสูงสุดแล้ว';
    }
  }

  // ...existing code...

  //---------------- notification ----------------
  // เพิ่มฟังก์ชันใหม่ใน Service class
  // เพิ่มใน Service class

  Future<void> notifyAgenciesAboutFire(Map<String, dynamic> fireData) async {
    final uri = Uri.parse("$baseUrl/notification/fire-report");

    Map<String, String> headers = {"Content-Type": "application/json"};

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(fireData),
    );

    if (response.statusCode != 200) {
      print("Failed to send notification: ${response.body}");
      throw Exception("Failed to send notification");
    }
  }

  Future<bool> sendNotificationToAllVolunteers({
    required String title,
    required String message,
    required Map<String, Object> data,
  }) async {
    try {
      print('🚀 START: sendNotificationToAllVolunteers');
      print('📡 URL: $baseUrl/notification/volunteers/all');
      print('📋 Title: $title');
      print('💬 Message: $message');
      print('📊 Data: $data');

      // ✅ ตรวจสอบ Network Connection
      print('🌐 Testing network connection...');
      final testResponse = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => http.Response('Timeout', 408),
          );

      if (testResponse.statusCode != 200 && testResponse.statusCode != 404) {
        print('❌ Backend not reachable: ${testResponse.statusCode}');
        return false;
      }
      print('✅ Network connection OK');

      final requestBody = {
        'title': title,
        'message': message,
        'type': 'fire_alert',
        'data': data,
      };

      print('📤 Sending request...');
      print('📤 Body: ${json.encode(requestBody)}');

      // ✅ ส่ง Request
      final response = await http
          .post(
            Uri.parse('$baseUrl/notification/volunteers/all'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('⏰ Request timeout after 30 seconds');
              return http.Response(
                '{"success": false, "error": "Request timeout"}',
                408,
              );
            },
          );

      print('📥 Response received: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // ✅ ตรวจสอบ Response
      if (response.statusCode == 200) {
        try {
          final dynamic rawResponseData = json.decode(response.body);

          if (rawResponseData is Map) {
            final Map<String, dynamic> responseData = Map<String, dynamic>.from(
              rawResponseData,
            );
            bool success = responseData['success'] == true;

            print('✅ JSON parsed successfully');
            print('🎯 Success: $success');

            if (responseData.containsKey('recipientCount')) {
              print('👥 Recipients: ${responseData['recipientCount']}');
            }

            return success;
          } else {
            throw Exception('Response is not a Map');
          }
        } catch (parseError) {
          print('⚠️ JSON parse error: $parseError');
          print('📄 Raw response: ${response.body}');

          // ✅ Fallback check
          String bodyLower = response.body.toLowerCase();
          bool containsSuccess =
              bodyLower.contains('success') ||
              bodyLower.contains('sent') ||
              bodyLower.contains('notifications');

          print('🔍 Fallback check result: $containsSuccess');
          return containsSuccess;
        }
      } else if (response.statusCode == 408) {
        print('⏰ Request timeout');
        return false;
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Error body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('💥 Exception: $e');
      print('📚 Stack trace: $stackTrace');
      return false;
    } finally {
      print('🏁 END: sendNotificationToAllVolunteers');
    }
  }

  Future<bool> sendNotificationToSelectedVolunteers({
    required List<String> volunteerEmails,
    required String title,
    required String message,
    required Map<String, Object> data,
  }) async {
    try {
      print('🎯 START: sendNotificationToSelectedVolunteers');
      print('📡 URL: $baseUrl/notification/volunteers/selected');
      print('👥 Emails (${volunteerEmails.length}): $volunteerEmails');
      print('📋 Title: $title');
      print('💬 Message: $message');
      print('📊 Data: $data');

      final requestBody = {
        'volunteerEmails': volunteerEmails,
        'title': title,
        'message': message,
        'type': 'task_assignment',
        'data': data,
      };

      print('📤 Sending request...');
      print('📤 Body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/notification/volunteers/selected'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('📥 Response received: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          bool success = responseData['success'] == true;

          print('✅ JSON parsed successfully');
          print('🎯 Success: $success');

          return success;
        } catch (parseError) {
          print('⚠️ JSON parse error: $parseError');
          bool containsSuccess = response.body.toLowerCase().contains(
            'success',
          );
          print('🔍 Fallback check result: $containsSuccess');
          return containsSuccess;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Error body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('💥 Exception: $e');
      print('📚 Stack trace: $stackTrace');
      return false;
    } finally {
      print('🏁 END: sendNotificationToSelectedVolunteers');
    }
  }

  /// ดึงรายการ notification ของอาสาสมัคร
  Future<List<Map<String, dynamic>>> getVolunteerNotifications(
    String email,
  ) async {
    try {
      print('📱 Getting notifications for: $email');

      final response = await http.get(
        Uri.parse('$baseUrl/notification/volunteer/$email'),
      );

      print('📥 Notification Response Status: ${response.statusCode}');
      print('📥 Notification Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic rawResponse = json.decode(response.body);

        if (rawResponse is List) {
          final List<Map<String, dynamic>> notifications =
              rawResponse
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();

          print('📊 Parsed ${notifications.length} notifications');

          // ✅ Debug แต่ละ notification
          for (int i = 0; i < notifications.length; i++) {
            final notif = notifications[i];
            print('📋 Notification $i:');
            print('  - ID: ${notif['id']}');
            print('  - Title: ${notif['title']}');
            print('  - Type: ${notif['type']}');
            print('  - Data Type: ${notif['data']?.runtimeType}');
            print('  - Data: ${notif['data']}');
          }

          return notifications;
        } else {
          throw Exception('Response is not a List');
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('💥 Error getting volunteer notifications: $e');
      return [];
    }
  }

  /// อัพเดทสถานะการอ่าน notification
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final url = Uri.parse("$baseUrl/notification/$notificationId/read");
      final response = await http.put(url);
      return response.statusCode == 200;
    } catch (e) {
      print("Error marking notification as read: $e");
      return false;
    }
  }
}
