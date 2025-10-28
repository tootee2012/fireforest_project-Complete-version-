class UserModel {
  final String userEmail;
  final String userFname;
  final String userLname;
  final String userGender;
  final String userBirthDay; // แปลงเป็น String แล้ว
  final String? userAddress;
  final String? userTel;
  final String volunteerStatus; // สถานะอาสาสมัคร

  UserModel({
    required this.userEmail,
    required this.userFname,
    required this.userLname,
    required this.userGender,
    required this.userBirthDay,
    this.userAddress,
    this.userTel,
    required this.volunteerStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userEmail: json['userEmail'] ?? "",
      userFname: json['userFname'] ?? "",
      userLname: json['userLname'] ?? "",
      userGender: json['userGender'] ?? "",
      userBirthDay: json['userBirthDay'] ?? "",
      userAddress: json['userAddress'],
      userTel: json['userTel'],
      volunteerStatus:
          json['volunteer'] != null
              ? (json['volunteer']['volunteerStatus'] ?? "ยังไม่ได้สมัคร")
              : "ยังไม่ได้สมัคร",
    );
  }
}
