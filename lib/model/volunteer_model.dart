import 'package:fireforest_project/model/apply_model.dart';
import 'package:fireforest_project/model/experience_model.dart';
import 'package:fireforest_project/model/join_member_model.dart';

class VolunteerModel {
  final String userEmail;
  final double weight;
  final double height;
  final String talent;
  final bool isTraining;
  final String applicationDate;
  final String entryDate;
  final String volunteerStatus;
  final String volunteerLocation;
  final String name;
  final DateTime? birthDate;
  final int age;
  // ✅ เพิ่มฟิลด์ที่อยู่ของ user
  final String? userAddress;
  final String? userTel;
  final String? userGender;
  final ExperienceModel? experience;
  final ApplyFormModel? applyForm;
  JoinMemberModel? joinMember; // ลบ final ออกเพื่อให้อัพเดทได้

  VolunteerModel({
    required this.userEmail,
    required this.weight,
    required this.height,
    required this.talent,
    required this.isTraining,
    required this.applicationDate,
    required this.entryDate,
    required this.volunteerStatus,
    required this.volunteerLocation,
    required this.name,
    required this.birthDate,
    required this.age,
    // ✅ เพิ่มใน constructor
    this.userAddress,
    this.userTel,
    this.userGender,
    this.experience,
    this.applyForm,
    this.joinMember,
  });

  factory VolunteerModel.fromJson(Map<String, dynamic> json) {
    // ✅ เพิ่ม Debug สำหรับ applyForm
    print('🔍 VolunteerModel.fromJson Debug:');
    print('   userEmail: ${json['userEmail']}');
    print('   applyForm exists: ${json.containsKey('applyForm')}');
    print('   applyForm value: ${json['applyForm']}');
    print('   applyForm type: ${json['applyForm']?.runtimeType}');

    DateTime? birth;
    int calculatedAge = 0;

    // คำนวณอายุ
    if (json['birthDate'] != null) {
      birth = DateTime.tryParse(json['birthDate']);
      if (birth != null) {
        final now = DateTime.now();
        calculatedAge = now.year - birth.year;
        if (now.month < birth.month ||
            (now.month == birth.month && now.day < birth.day)) {
          calculatedAge--;
        }
      }
    }

    // ✅ ดึงข้อมูลจาก user object ถ้ามี
    final userData = json['user'] as Map<String, dynamic>?;

    // ✅ ปรับปรุงการแปลง applyForm
    ApplyFormModel? applyFormModel;
    if (json['applyForm'] != null) {
      try {
        print('🔍 Attempting to parse applyForm...');

        // ตรวจสอบว่าเป็น Map หรือ List
        if (json['applyForm'] is Map<String, dynamic>) {
          print('✅ applyForm is Map');
          applyFormModel = ApplyFormModel.fromJson(json['applyForm']);
          print('✅ Successfully parsed applyForm from Map');
        } else if (json['applyForm'] is List) {
          print(
            '✅ applyForm is List with length: ${(json['applyForm'] as List).length}',
          );
          final applyFormList = json['applyForm'] as List;
          if (applyFormList.isNotEmpty &&
              applyFormList[0] is Map<String, dynamic>) {
            applyFormModel = ApplyFormModel.fromJson(applyFormList[0]);
            print('✅ Successfully parsed applyForm from List[0]');
          }
        } else {
          print(
            '⚠️ applyForm is neither Map nor List: ${json['applyForm'].runtimeType}',
          );
        }

        if (applyFormModel != null) {
          print('✅ Final applyForm data:');
          print('   applyFormId: ${applyFormModel.applyFormId}');
          print(
            '   congenitalDiseases: "${applyFormModel.congenitalDiseases}"',
          );
          print('   allergicFood: "${applyFormModel.allergicFood}"');
        }
      } catch (e, stackTrace) {
        print('❌ Error parsing applyForm: $e');
        print('❌ StackTrace: $stackTrace');
        applyFormModel = null;
      }
    } else {
      print('⚠️ applyForm is null in JSON');
    }

    // แปลงข้อมูลจาก JSON
    return VolunteerModel(
      userEmail: json['userEmail'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      talent: json['talent'] ?? '',
      isTraining: json['isTraining'] ?? false,
      applicationDate: json['applicationDate'] ?? '',
      entryDate: json['entryDate'] ?? '',
      volunteerStatus: json['volunteerStatus'] ?? '',
      volunteerLocation: json['volunteerLocation'] ?? '',
      name:
          userData?['userFname'] != null && userData?['userLname'] != null
              ? "${userData!['userFname']} ${userData['userLname']}"
              : json['name'] ?? '',
      birthDate: birth,
      age: json['age'] ?? calculatedAge,
      // ✅ เพิ่มการดึงข้อมูลจาก user object
      userAddress: userData?['userAddress'],
      userTel: userData?['userTel'],
      userGender: userData?['userGender'],
      experience:
          json['experience'] != null
              ? ExperienceModel.fromJson(json['experience'])
              : null,
      applyForm:
          json['applyForm'] != null
              ? ApplyFormModel.fromJson(json['applyForm'])
              : null,
      joinMember:
          json['joinMember'] != null
              ? JoinMemberModel.fromJson(json['joinMember'])
              : null,
    );
  }

  // เช็คว่ามีงานที่ได้รับมอบหมายหรือไม่
  bool hasAssignedWork() {
    return joinMember?.workStatus == 'assigned' ||
        joinMember?.workStatus == 'pending';
  }

  // เช็คสถานะงาน
  String getWorkStatusText() {
    if (joinMember?.workStatus == 'pending') {
      return 'รองานใหม่';
    } else if (joinMember?.workStatus == 'assigned') {
      return 'ได้รับมอบหมายงานแล้ว';
    }
    return 'ว่าง';
  }

  // ✅ เพิ่มฟังก์ชันสำหรับแสดงที่อยู่แบบเต็ม
  String getFullAddress() {
    if (userAddress != null && userAddress!.isNotEmpty) {
      return userAddress!;
    }
    return 'ไม่ได้ระบุที่อยู่';
  }

  // ✅ เพิ่มฟังก์ชันสำหรับแสดงเบอร์โทร
  String getPhoneNumber() {
    if (userTel != null && userTel!.isNotEmpty) {
      return userTel!;
    }
    return 'ไม่ได้ระบุเบอร์โทร';
  }

  // ✅ เพิ่มฟังก์ชันสำหรับแสดงเพศ
  String getGenderText() {
    switch (userGender) {
      case 'male':
        return 'ชาย';
      case 'female':
        return 'หญิง';
      default:
        return 'ไม่ระบุ';
    }
  }

  // สร้าง object ใหม่พร้อมอัพเดทข้อมูล
  VolunteerModel copyWith({
    String? volunteerStatus,
    String? entryDate,
    double? weight,
    double? height,
    String? talent,
    bool? isTraining,
    String? applicationDate,
    String? volunteerLocation,
    String? name,
    DateTime? birthDate,
    int? age,
    // ✅ เพิ่มใน copyWith
    String? userAddress,
    String? userTel,
    String? userGender,
    JoinMemberModel? joinMember,
  }) {
    return VolunteerModel(
      userEmail: this.userEmail,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      talent: talent ?? this.talent,
      isTraining: isTraining ?? this.isTraining,
      applicationDate: applicationDate ?? this.applicationDate,
      entryDate: entryDate ?? this.entryDate,
      volunteerStatus: volunteerStatus ?? this.volunteerStatus,
      volunteerLocation: volunteerLocation ?? this.volunteerLocation,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      // ✅ เพิ่มใน copyWith
      userAddress: userAddress ?? this.userAddress,
      userTel: userTel ?? this.userTel,
      userGender: userGender ?? this.userGender,
      experience: this.experience,
      applyForm: this.applyForm,
      joinMember: joinMember ?? this.joinMember,
    );
  }

  // แปลง object เป็น Map
  Map<String, dynamic> toJson() {
    return {
      'userEmail': userEmail,
      'weight': weight,
      'height': height,
      'talent': talent,
      'isTraining': isTraining,
      'applicationDate': applicationDate,
      'entryDate': entryDate,
      'volunteerStatus': volunteerStatus,
      'volunteerLocation': volunteerLocation,
      'name': name,
      'birthDate': birthDate?.toIso8601String(),
      'age': age,
      // ✅ เพิ่มใน toJson
      'userAddress': userAddress,
      'userTel': userTel,
      'userGender': userGender,
      'experience': experience?.toJson(),
      'applyForm': applyForm?.toJson(),
      'joinMember': joinMember?.toJson(),
    };
  }
}
