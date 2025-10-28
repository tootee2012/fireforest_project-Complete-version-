class AgencyModel {
  final String agencyEmail;
  final String agencyName;

  AgencyModel({required this.agencyEmail, required this.agencyName});

  factory AgencyModel.fromJson(Map<String, dynamic> json) {
    return AgencyModel(
      agencyEmail: json['agencyEmail'],
      agencyName: json['agencyName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'agencyEmail': agencyEmail,
    'agencyName': agencyName,
  };
}
