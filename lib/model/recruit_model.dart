class RecruitModel {
  final int id;
  final String description;
  final String recruitLocation;
  final DateTime startDate;
  final DateTime endDate;
  final int max;
  bool isVisible; // 👈 เพิ่ม

  RecruitModel({
    required this.id,
    required this.description,
    required this.recruitLocation,
    required this.startDate,
    required this.endDate,
    required this.max,
    this.isVisible = true,
  });

  factory RecruitModel.fromJson(Map<String, dynamic> json) {
    return RecruitModel(
      id: json['recruitId'],
      description: json['description'] ?? '',
      recruitLocation: json['recruitLocation'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      max: json['max'] ?? 0,
      isVisible: json['visible'] ?? true, // 👈 map ค่า
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "recruitId": id,
      "description": description,
      "recruitLocation": recruitLocation,
      "startDate": startDate.toIso8601String(),
      "endDate": endDate.toIso8601String(),
      "max": max,
      "visible": isVisible,
    };
  }
}
