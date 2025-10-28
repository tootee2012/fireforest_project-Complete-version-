import 'package:fireforest_project/utils.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import '../model/user_model.dart';
import '../service.dart';
import 'volunteer_home.dart';

class VolunteerStatusPage extends StatefulWidget {
  final String userEmail;
  const VolunteerStatusPage({super.key, required this.userEmail});

  @override
  State<VolunteerStatusPage> createState() => _VolunteerStatusPageState();
}

class _VolunteerStatusPageState extends State<VolunteerStatusPage> {
  Service service = Service();
  UserModel? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    try {
      print("Load user email: ${widget.userEmail}");
      final fetchedUser = await service.getUserByEmailJson(widget.userEmail);
      print("Fetched user: $fetchedUser");
      setState(() {
        user = fetchedUser;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading user: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      var day = date.day + 1;
      return "${day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, // สีพื้นหลังเขียวอ่อน
      appBar: AppBar(
        title: const Text(
          "สถานะอาสาสมัคร",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor, // สี AppBar เขียวมะกอก
        centerTitle: true,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : user == null
              ? const Center(child: Text("ไม่พบข้อมูลผู้ใช้"))
              : Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  margin: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 8,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "ข้อมูลส่วนตัว",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "ชื่อ: ${user!.userFname} ${user!.userLname}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text("อีเมล: ${user!.userEmail}"),
                      const SizedBox(height: 8),
                      Text("เพศ: ${user!.userGender}"),
                      const SizedBox(height: 8),
                      Text(
                        "วันเกิด: ${Utils.formatDateTime(user!.userBirthDay)}",
                      ), // ใช้ formatDateTime
                      const SizedBox(height: 8),
                      Text("ที่อยู่: ${user!.userAddress ?? '-'}"),
                      const SizedBox(height: 8),
                      Text("เบอร์โทร: ${user!.userTel ?? '-'}"),
                      const SizedBox(height: 16),
                      Text(
                        "สถานะอาสาสมัคร: ${user!.volunteerStatus}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              user!.volunteerStatus == "ผ่านการคัดเลือก"
                                  ? AppTheme.primaryColor
                                  : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                user!.volunteerStatus == "ผ่านการคัดเลือก"
                                    ? AppTheme.primaryLight
                                    : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed:
                              user!.volunteerStatus == "ผ่านการคัดเลือก"
                                  ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => HomeVolunteer(
                                              userEmail: widget.userEmail,
                                            ),
                                      ),
                                    );
                                  }
                                  : null,
                          child: const Text(
                            "ไปยังหน้าจออาสาสมัคร",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
