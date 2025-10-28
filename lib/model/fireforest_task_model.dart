class FireforestTaskModel {
  final int fireForestId;
  final String location;
  final String time; // String เพราะ backend ส่งเป็น "yyyy-MM-dd HH:mm"
  final String workStatus;

  FireforestTaskModel({
    required this.fireForestId,
    required this.location,
    required this.time,
    required this.workStatus,
  });

  factory FireforestTaskModel.fromJson(Map<String, dynamic> json) {
    return FireforestTaskModel(
      fireForestId: json['fireForestId'],
      location: json['location'] ?? '-',
      time: json['time'] ?? '-',
      workStatus: json['workStatus'] ?? '-',
    );
  }
}
