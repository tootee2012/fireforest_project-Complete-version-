class HistoryModel {
  final int id;
  final int fireForestId;
  final String location;
  final String date;
  final String status;
  final bool isCompleted;

  HistoryModel({
    required this.id,
    required this.fireForestId,
    required this.location,
    required this.date,
    required this.status,
    required this.isCompleted,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id'] as int,
      fireForestId: json['fireForestId'] as int,
      location: json['location'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      isCompleted: json['completed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fireForestId': fireForestId,
      'location': location,
      'date': date,
      'status': status,
      'completed': isCompleted,
    };
  }

  @override
  String toString() {
    return 'HistoryModel(id: $id, fireForestId: $fireForestId, location: $location, date: $date, status: $status, isCompleted: $isCompleted)';
  }
}
