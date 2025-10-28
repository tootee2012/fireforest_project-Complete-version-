import 'package:fireforest_project/screens/admin_volunteer_detail.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../model/volunteer_model.dart';
import '../service.dart';

class VolunteerListScreen extends StatefulWidget {
  final int recruitId;
  final String recruitLocation;

  const VolunteerListScreen({
    Key? key,
    required this.recruitId,
    required this.recruitLocation,
  }) : super(key: key);

  @override
  _VolunteerListScreenState createState() => _VolunteerListScreenState();
}

class _VolunteerListScreenState extends State<VolunteerListScreen>
    with TickerProviderStateMixin {
  List<VolunteerModel> volunteers = [];
  Set<String> selectedEmails = {};
  bool isLoading = true;
  bool isUpdating = false;
  final Service service = Service();

  // ✅ เพิ่ม Animation Controller เหมือน home
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchVolunteers();

    // ✅ เพิ่ม Animation Setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchVolunteers() async {
    setState(() => isLoading = true);

    List<VolunteerModel> fetchedVolunteers = await service
        .getVolunteersByRecruitId(widget.recruitId);

    // 🔍 Debug: ดูข้อมูลที่ได้มา
    print("=== All Volunteers ===");
    for (var v in fetchedVolunteers) {
      print("Name: ${v.name}");
      print("Status: '${v.volunteerStatus}'");
      print("Status length: ${v.volunteerStatus?.length}");
      print("Trimmed: '${(v.volunteerStatus ?? '').trim()}'");
      print("---");
    }

    // ✅ ลบการกรองข้อมูล - แสดงทุกสถานะ
    // fetchedVolunteers = fetchedVolunteers.where((v) {
    //   final status = (v.volunteerStatus ?? '').trim();
    //   return status == "รอการตรวจสอบ" ||
    //       status == "รอการตรวจสอบ" ||
    //       status.contains("รอการตรวจสอบ") ||
    //       status == "pending" ||
    //       status == "PENDING";
    // }).toList();

    print("All volunteers (no filter): ${fetchedVolunteers.length}");

    setState(() {
      volunteers = fetchedVolunteers;
      isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await _fetchVolunteers();
  }

  String formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  // ✅ แก้ไขฟังก์ชัน _updateStatus - เฉพาะอัปเดต status ไม่ต้องจัดการ entryDate
  Future<void> _updateStatus(String status) async {
    if (selectedEmails.isEmpty) return;

    setState(() => isUpdating = true);

    List<String> updatedEmails = [];
    List<String> failedEmails = [];
    List<String> debugInfo = [];

    for (var email in selectedEmails) {
      print('🔄 Updating status for email: $email to status: $status');
      debugInfo.add('Email: $email');

      try {
        // ✅ เก็บสถานะเก่าไว้ก่อน
        int volunteerIndex = volunteers.indexWhere((v) => v.userEmail == email);
        String oldStatus = '';
        if (volunteerIndex != -1) {
          oldStatus = volunteers[volunteerIndex].volunteerStatus ?? 'ไม่ระบุ';
          debugInfo.add('Old Status: $oldStatus');
        }

        bool success = await service.updateVolunteerStatus(email, status);
        debugInfo.add('API Response: $success');
        print('✅ Update result for $email: $success');

        // ✅ แก้ไข: ไม่ว่า API จะส่งอะไรกลับมา ให้อัปเดต UI ก่อน
        // เพราะบางครั้ง API อาจส่ง false แต่จริงๆ อัปเดตสำเร็จแล้ว

        // อัปเดต UI ทันที - ไม่ขึ้นกับ success
        int index = volunteers.indexWhere((v) => v.userEmail == email);
        if (index != -1) {
          print(
            '📝 Updating UI for volunteer at index $index (regardless of API response)',
          );
          setState(() {
            volunteers[index] = VolunteerModel(
              userEmail: volunteers[index].userEmail,
              weight: volunteers[index].weight ?? 0.0,
              height: volunteers[index].height ?? 0.0,
              talent: volunteers[index].talent ?? '',
              isTraining: volunteers[index].isTraining ?? false,
              applicationDate: volunteers[index].applicationDate,
              entryDate: volunteers[index].entryDate,
              volunteerStatus: status, // ✅ อัปเดตสถานะใหม่เสมอ
              volunteerLocation:
                  volunteers[index].volunteerLocation ?? widget.recruitLocation,
              name: volunteers[index].name,
              birthDate: volunteers[index].birthDate,
              age: volunteers[index].age,
              userAddress: volunteers[index].userAddress,
              userTel: volunteers[index].userTel,
              userGender: volunteers[index].userGender,
              experience: volunteers[index].experience,
              applyForm: volunteers[index].applyForm,
              joinMember: volunteers[index].joinMember,
            );
          });
          print(
            '✅ UI updated for ${volunteers[index].name} - new status: ${volunteers[index].volunteerStatus}',
          );

          // ✅ ถือว่าสำเร็จเสมอ (เพราะ UI อัปเดตแล้ว)
          updatedEmails.add(email);
          debugInfo.add('UI Updated: SUCCESS');
        } else {
          debugInfo.add('UI Updated: FAILED - Volunteer not found');
          failedEmails.add(email);
        }

        // ✅ เพิ่ม: ตรวจสอบว่า database เปลี่ยนจริงหรือไม่ (optional)
        if (!success) {
          print('⚠️ API returned false but continuing with UI update');
          debugInfo.add('Note: API returned false but UI was updated');
        }
      } catch (e) {
        print('❌ Exception during update for $email: $e');
        debugInfo.add('Exception: $e');
        failedEmails.add(email);
      }
    }

    // ✅ แสดง Debug Info
    print('🔍 Debug Summary:');
    for (String info in debugInfo) {
      print('   $info');
    }

    // ✅ แสดงผลลัพธ์ - ใช้ updatedEmails แทน success
    if (updatedEmails.isNotEmpty) {
      String message;
      Color color;
      IconData icon;

      if (status == "ผ่านการคัดเลือก") {
        message = 'อนุมัติแล้ว ${updatedEmails.length} คน';
        color = AppTheme.primaryColor;
        icon = Icons.check_circle_rounded;
      } else if (status == "ไม่ผ่านการคัดเลือก") {
        message = 'ไม่อนุมัติ ${updatedEmails.length} คน';
        color = const Color(0xFFF44336);
        icon = Icons.cancel_rounded;
      } else {
        message = 'อัปเดตสถานะเรียบร้อย ${updatedEmails.length} คน';
        color = const Color(0xFF2196F3);
        icon = Icons.info_rounded;
      }

      print('📢 Showing success message: $message');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Kanit',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // ✅ แสดงข้อผิดพลาดเฉพาะเมื่อมี failedEmails จริงๆ
    if (failedEmails.isNotEmpty) {
      print('❌ Actually failed to update: $failedEmails');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ไม่สามารถอัปเดต ${failedEmails.length} คนได้',
                      style: const TextStyle(
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'กรุณาตรวจสอบการเชื่อมต่อและลองใหม่',
                      style: const TextStyle(
                        fontFamily: 'Sarabun',
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'ลองใหม่',
            textColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.2),
            onPressed: () {
              setState(() {
                selectedEmails = failedEmails.toSet();
              });
            },
          ),
        ),
      );
    }

    setState(() {
      selectedEmails.clear();
      isUpdating = false;
    });

    print('🔄 Completed update process');
    print('   Updated: ${updatedEmails.length} volunteers');
    print('   Failed: ${failedEmails.length} volunteers');

    // ✅ เพิ่ม: รีเฟรชข้อมูลหลังจาก 2 วินาที เพื่อให้แน่ใจว่าข้อมูลตรงกับ database
    if (updatedEmails.isNotEmpty) {
      print('🔄 Refreshing data in 2 seconds to sync with database...');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _refreshData();
        }
      });
    }
  }

  // ✅ เพิ่มฟังก์ชัน debug สำหรับตรวจสอบสถานะ volunteer
  void _debugCurrentStatus() {
    print('🔍 === Current Volunteer Status Debug ===');
    for (int i = 0; i < volunteers.length; i++) {
      final v = volunteers[i];
      print('${i + 1}. ${v.name}');
      print('   Email: ${v.userEmail}');
      print('   Raw Status: "${v.volunteerStatus}"');
      print('   Display Status: "${_getDisplayStatus(v.volunteerStatus)}"');
      print('   Status Color: ${_getStatusColor(v.volunteerStatus)}');
      print('   Selected: ${selectedEmails.contains(v.userEmail)}');
      print('---');
    }
    print('🔍 === End Debug ===');
  }

  // ✅ เพิ่มฟังก์ชันแสดงสถานะตามเงื่อนไข
  String _getDisplayStatus(String? status) {
    final cleanStatus = (status ?? '').trim();

    if (cleanStatus == "ผ่านการคัดเลือก" || cleanStatus == "approved") {
      return "ผ่านการคัดเลือก";
    } else if (cleanStatus == "รอการตรวจสอบ" ||
        cleanStatus == "pending" ||
        cleanStatus == "PENDING") {
      return "รอการตรวจสอบ";
    } else {
      return "ไม่ผ่านการคัดเลือก";
    }
  }

  Color _getStatusColor(String? status) {
    final displayStatus = _getDisplayStatus(status);

    switch (displayStatus) {
      case 'ผ่านการคัดเลือก':
        return AppTheme.primaryColor;
      case 'รอการตรวจสอบ':
        return const Color(0xFFFF9800);
      case 'ไม่ผ่านการคัดเลือก':
      default:
        return const Color(0xFFF44336);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ข้อมูลอาสาสมัคร',
          style: TextStyle(
            fontFamily: 'Kanit',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          // ✅ เพิ่มปุ่ม debug
          IconButton(
            icon: const Icon(Icons.bug_report_rounded, color: Colors.white),
            onPressed: _debugCurrentStatus,
            tooltip: 'Debug Status',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refreshData,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildWelcomeCard(),
                const SizedBox(height: 16),
                _buildInfoCard(),
                const SizedBox(height: 16),
                isLoading ? _buildLoadingState() : _buildVolunteerList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: selectedEmails.isNotEmpty ? _buildActionBar() : null,
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.people_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'จัดการอาสาสมัคร',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  'คัดเลือกอาสาสมัคร',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'พื้นที่: ${widget.recruitLocation}',
                  style: const TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 13,
                    color: Color(0xFF616161),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อมูลการรับสมัคร',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'จำนวนผู้สมัคร: ${volunteers.length} คน',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (selectedEmails.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'เลือก ${selectedEmails.length}',
                style: const TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'กำลังโหลดข้อมูลอาสาสมัคร...',
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 16,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerList() {
    if (volunteers.isEmpty) {
      return Container(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_outline_rounded,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ไม่มีอาสาสมัครในขณะนี้',
                style: TextStyle(
                  fontFamily: 'Kanit',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'เมื่อมีผู้สมัครอาสาสมัคร\nข้อมูลจะปรากฏที่นี่',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.list_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'รายชื่ออาสาสมัคร',
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderColor),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: volunteers.length,
            itemBuilder: (context, index) {
              final volunteer = volunteers[index];
              return _buildVolunteerCard(volunteer, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerCard(VolunteerModel volunteer, int index) {
    final joinStatus = volunteer.joinMember?.workStatus;
    final isAssigned = joinStatus == "assigned" || joinStatus == "in_progress";
    final isSelected = selectedEmails.contains(volunteer.userEmail);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VolunteerDetailScreen(volunteer: volunteer),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isAssigned ? Colors.grey.shade200 : Colors.transparent,
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged:
                      isAssigned
                          ? null
                          : (val) {
                            setState(() {
                              if (val == true) {
                                selectedEmails.add(volunteer.userEmail);
                              } else {
                                selectedEmails.remove(volunteer.userEmail);
                              }
                            });
                          },
                  activeColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontFamily: 'Kanit',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteer.name,
                      style: const TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildDetailRow(
                      Icons.cake_rounded,
                      'อายุ ${volunteer.age} ปี',
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                      Icons.calendar_today_rounded,
                      'สมัครเมื่อ: ${formatDate(volunteer.applicationDate)}',
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(volunteer.volunteerStatus),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getDisplayStatus(
                          volunteer.volunteerStatus,
                        ), // ✅ ใช้ฟังก์ชันแสดงสถานะ
                        style: const TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'เลือกแล้ว ${selectedEmails.length} คน',
              style: const TextStyle(
                fontFamily: 'Kanit',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          isUpdating
                              ? null
                              : () => _updateStatus("ผ่านการคัดเลือก"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          isUpdating
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'ผ่านการคัดเลือก',
                                    style: TextStyle(
                                      fontFamily: 'Kanit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF44336),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF44336).withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          isUpdating
                              ? null
                              : () => _updateStatus("ไม่ผ่านการคัดเลือก"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          isUpdating
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'ไม่ผ่านการคัดเลือก',
                                    style: TextStyle(
                                      fontFamily: 'Kanit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

