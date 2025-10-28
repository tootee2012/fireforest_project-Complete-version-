class JoinRequest {
  final int fireForestId;
  final String volunteerEmail;

  JoinRequest({required this.fireForestId, required this.volunteerEmail});

  Map<String, dynamic> toJson() {
    return {"fireForestId": fireForestId, "volunteerEmail": volunteerEmail};
  }
}
