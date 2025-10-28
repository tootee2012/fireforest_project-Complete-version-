import 'package:fireforest_project/model/join_member_model.dart';

import 'fireforest_model.dart';
import 'agency_model.dart';

class FireForestDetail {
  int fireForestId;
  String? fireStatus;
  String? assessDamage;
  String? summarize;
  int? requiredVolunteers;
  bool? openForVolunteer;
  FireforestModel? fireForest;
  AgencyModel? agency;
  JoinMemberModel? joinMember; // <-- มี field นี้

  FireForestDetail({
    required this.fireForestId,
    this.fireStatus,
    this.assessDamage,
    this.summarize,
    this.requiredVolunteers,
    this.openForVolunteer,
    this.fireForest,
    this.agency,
    this.joinMember, // <-- เพิ่มใน constructor
  });

  factory FireForestDetail.fromJson(Map<String, dynamic> json) {
    return FireForestDetail(
      fireForestId: json['fireForestId'],
      fireStatus: json['fireStatus'],
      assessDamage: json['assessDamage'],
      summarize: json['summarize'],
      requiredVolunteers: json['requiredVolunteers'],
      openForVolunteer: json['openForVolunteer'],
      fireForest:
          json['fireForest'] != null
              ? FireforestModel.fromJson(json['fireForest'])
              : null,
      agency:
          json['agency'] != null ? AgencyModel.fromJson(json['agency']) : null,
      joinMember:
          json['joinMember'] != null
              ? JoinMemberModel.fromJson(json['joinMember'])
              : null, // <-- เพิ่ม map joinMember
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fireForestId': fireForestId,
      'fireStatus': fireStatus,
      'assessDamage': assessDamage,
      'summarize': summarize,
      'requiredVolunteers': requiredVolunteers,
      'openForVolunteer': openForVolunteer,
      'fireForest': fireForest?.toJson(),
      'agency': agency?.agencyEmail,
      'joinMember': joinMember?.toJson(), // <-- เพิ่ม map joinMember
    };
  }
}
