class AssignDTO {
  final int fireForestId;
  final List<String> userEmails;

  AssignDTO({required this.fireForestId, required this.userEmails});

  Map<String, dynamic> toJson() {
    return {"fireForestId": fireForestId, "userEmails": userEmails};
  }
}
