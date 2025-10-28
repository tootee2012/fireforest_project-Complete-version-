import 'fireforest_model.dart';

class JoinMemberModel {
  final int fireForestId;
  final String volunteerEmail;
  final String location;
  final String time;
  String workStatus; // ✅ เอา final ออกเพื่อให้แก้ไขได้
  FireforestModel? fireForest;

  JoinMemberModel({
    required this.fireForestId,
    required this.volunteerEmail,
    this.location = '',
    this.time = '',
    this.workStatus = '', // ✅ เปลี่ยนจาก required เป็น optional
    this.fireForest,
  });

  Map<String, dynamic> toJson() {
    return {
      'fireForestId': fireForestId,
      'volunteerEmail': volunteerEmail,
      'location': location,
      'time': time,
      'workStatus': workStatus,
      'fireForest': fireForest?.toJson(),
    };
  }

  factory JoinMemberModel.fromJson(Map<String, dynamic> json) {
    return JoinMemberModel(
      fireForestId: json['fireForestId'] ?? 0,
      volunteerEmail: json['volunteerEmail'] ?? '',
      location: json['location'] ?? '',
      time: json['time'] ?? '',
      workStatus: json['workStatus'] ?? '',
      fireForest:
          json['fireForest'] != null
              ? FireforestModel.fromJson(json['fireForest'])
              : null,
    );
  }
}
