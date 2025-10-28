import 'package:intl/intl.dart';

class Utils {
  // ฟังก์ชัน format วันที่-เวลาแบบไทย
  static String formatDateTime(dynamic dt) {
    if (dt == null) return 'ไม่ระบุเวลา';

    DateTime dateTime;

    if (dt is String) {
      dateTime = DateTime.tryParse(dt) ?? DateTime.now();
    } else if (dt is DateTime) {
      dateTime = dt;
    } else {
      return dt.toString();
    }

    final formatter = DateFormat('d MMMM yyyy เวลา HH:mm', 'th');
    return formatter.format(dateTime);
  }
}
