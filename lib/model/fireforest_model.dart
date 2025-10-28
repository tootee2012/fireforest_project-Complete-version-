import 'package:fireforest_project/model/fire_forest_detail_request.dart';
import 'package:fireforest_project/model/firepicture_model.dart';

class FireforestModel {
  final int? fireForestId;
  final String? fireForestTime;
  final String? fireForestLocation;
  final String? fireForestDetail;
  final String? status;
  final String? field;
  final String? userEmail;
  final double? fireForestLat;
  final double? fireForestLong;
  final List<FirePictureModel>? pictures;
  FireForestDetail? detail;

  FireforestModel({
    this.fireForestId,
    this.fireForestTime,
    this.fireForestLocation,
    this.fireForestDetail,
    this.status,
    this.field,
    this.userEmail,
    this.fireForestLat,
    this.fireForestLong,
    this.pictures,
    this.detail,
  });

  factory FireforestModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value);
      return null;
    }

    String? parseUserEmail(dynamic value) {
      if (value == null) return null;
      if (value is Map && value.containsKey('userEmail')) {
        return value['userEmail']?.toString();
      }
      return value.toString();
    }

    List<FirePictureModel> parsePictures(dynamic value) {
      if (value == null || value is! List) return [];
      return value
          .map<FirePictureModel>((e) => FirePictureModel.fromJson(e))
          .toList();
    }

    return FireforestModel(
      fireForestId: json['fireForestId'],
      fireForestTime: json['fireForestTime'],
      fireForestLocation: json['fireForestLocation'],
      fireForestDetail: json['fireForestDetail'],
      status: json['status'],
      field: json['field'],
      userEmail: parseUserEmail(json['userEmail']),
      fireForestLat: parseDouble(json['fireForestLat']),
      fireForestLong: parseDouble(json['fireForestLong']),
      pictures: parsePictures(json['pictures']),
      detail:
          json['reportFireForest'] != null
              ? FireForestDetail.fromJson(json['reportFireForest'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fireForestId': fireForestId,
      'fireForestTime': fireForestTime,
      'fireForestLocation': fireForestLocation,
      'fireForestDetail': fireForestDetail,
      'status': status,
      'field': field,
      'userEmail': userEmail,
      'fireForestLat': fireForestLat,
      'fireForestLong': fireForestLong,
      'pictures': pictures?.map((e) => e.toJson()).toList(),
      'detail': detail?.toJson(),
    };
  }
}
