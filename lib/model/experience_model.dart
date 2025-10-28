class ExperienceModel {
  final int experienceId;
  final String experienceType;

  ExperienceModel({required this.experienceId, required this.experienceType});

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      experienceId: json['experienceId'],
      experienceType: json['experienceType'],
    );
  }

  Map<String, dynamic> toJson() => {
    'experienceId': experienceId,
    'experienceType': experienceType,
  };
}
