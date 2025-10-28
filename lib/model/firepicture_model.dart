class FirePictureModel {
  final int? id;
  final String? pictureURL; // เก็บชื่อไฟล์จาก DB

  FirePictureModel({this.id, this.pictureURL});

  factory FirePictureModel.fromJson(Map<String, dynamic> json) {
    return FirePictureModel(id: json['id'], pictureURL: json['pictureURL']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'pictureURL': pictureURL};
  }

  // ✅ getter สำหรับ URL เต็ม HTTP
  String? get fullUrl {
    if (pictureURL == null || pictureURL!.isEmpty) return null;
    // แทนด้วย host และ port จริงของคุณ
    //return "http://25.28.30.17:8080/uploads/full/$pictureURL";
    return "http://192.168.1.37:8080/uploads/full/$pictureURL";
  }

  String? get thumbUrl {
    if (pictureURL == null || pictureURL!.isEmpty) return null;
    //return "http://25.28.30.17:8080/uploads/thumb/$pictureURL";
    return "http://192.168.1.37:8080/uploads/thumb/$pictureURL";
  }
}
