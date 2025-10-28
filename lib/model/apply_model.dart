class ApplyFormModel {
  final int applyFormId;
  final String congenitalDiseases; // โรคประจำตัว
  final String
  allergicFood; // ✅ เปลี่ยนจาก allergicFoods เป็น allergicFood (ไม่มี s)

  ApplyFormModel({
    required this.applyFormId,
    required this.congenitalDiseases,
    required this.allergicFood, // ✅ เปลี่ยนชื่อฟิลด์
  });

  factory ApplyFormModel.fromJson(Map<String, dynamic> json) {
    return ApplyFormModel(
      applyFormId: json['applyFormId'] ?? 0,
      congenitalDiseases: json['congenitalDiseases'] ?? '',
      allergicFood: json['allergicFood'] ?? '', // ✅ เปลี่ยนชื่อฟิลด์
    );
  }

  Map<String, dynamic> toJson() => {
    'applyFormId': applyFormId,
    'congenitalDiseases': congenitalDiseases,
    'allergicFood': allergicFood, // ✅ เปลี่ยนชื่อฟิลด์
  };
}
