import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../model/volunteer_model.dart';
import '../service.dart';

class VolunteerDetailScreen extends StatefulWidget {
  final VolunteerModel volunteer;
  const VolunteerDetailScreen({super.key, required this.volunteer});

  @override
  State<VolunteerDetailScreen> createState() => _VolunteerDetailScreenState();
}

class _VolunteerDetailScreenState extends State<VolunteerDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  VolunteerModel? detailedVolunteer;
  bool isLoadingDetails = false;
  final Service service = Service();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // ✅ ดึงข้อมูลละเอียดเพิ่มเติม
    _loadDetailedVolunteerData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ✅ ฟังก์ชันดึงข้อมูลแบบละเอียด (เหมือน AssignTaskPage)
  Future<void> _loadDetailedVolunteerData() async {
    setState(() => isLoadingDetails = true);

    try {
      print('🔍 Loading detailed data for: ${widget.volunteer.userEmail}');

      // ดึงข้อมูลจาก getAllVolunteers แล้วหาคนนี้
      final allVolunteers = await service.getAllVolunteers();
      final foundVolunteer = allVolunteers.firstWhere(
        (v) => v.userEmail == widget.volunteer.userEmail,
        orElse: () => widget.volunteer,
      );

      print('🔍 Found volunteer applyForm: ${foundVolunteer.applyForm}');

      if (foundVolunteer.applyForm != null) {
        setState(() {
          detailedVolunteer = foundVolunteer;
        });
        print('✅ Updated volunteer with applyForm data');
        print('   allergicFood: "${foundVolunteer.applyForm!.allergicFood}"');
        print(
          '   congenitalDiseases: "${foundVolunteer.applyForm!.congenitalDiseases}"',
        );
      } else {
        // ลองดึงข้อมูลเพิ่มเติมเหมือน AssignTaskPage
        print('⚠️ No applyForm found, trying additional data loading...');

        try {
          final pendingTasks = await service.getPendingTasksByVolunteer(
            widget.volunteer.userEmail,
          );
          final assignedTasks = await service.getAssignedTasksByVolunteer(
            widget.volunteer.userEmail,
          );

          // อัปเดต joinMember ถ้ามี
          VolunteerModel updatedVolunteer = foundVolunteer;
          if (pendingTasks.isNotEmpty) {
            updatedVolunteer.joinMember = pendingTasks.first;
          } else if (assignedTasks.isNotEmpty) {
            updatedVolunteer.joinMember = assignedTasks.first;
          }

          setState(() {
            detailedVolunteer = updatedVolunteer;
          });
        } catch (e) {
          print('⚠️ Could not load additional data: $e');
          setState(() {
            detailedVolunteer = foundVolunteer;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading detailed volunteer data: $e');
      setState(() {
        detailedVolunteer = widget.volunteer; // ใช้ข้อมูลเดิม
      });
    } finally {
      if (mounted) {
        setState(() => isLoadingDetails = false);
      }
    }
  }

  String formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget infoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget specialInfoRow(
    String label,
    String value,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ฟังก์ชันแสดงข้อมูลอาหารที่แพ้ - แก้ไขเพื่อจัดการ "none"
  String _getAllergicFoodText(VolunteerModel volunteer) {
    if (isLoadingDetails) {
      return 'กำลังโหลดข้อมูล...';
    }

    if (volunteer.applyForm?.allergicFood?.isNotEmpty == true) {
      final allergicFood =
          volunteer.applyForm!.allergicFood.trim().toLowerCase();

      // ✅ เช็คว่าเป็น "none" หรือไม่
      if (allergicFood == 'none' ||
          allergicFood == 'ไม่มี' ||
          allergicFood == '-') {
        return 'ไม่มีอาหารที่แพ้';
      }

      return volunteer.applyForm!.allergicFood;
    }

    return 'ไม่มีข้อมูลอาหารที่แพ้';
  }

  // ✅ ฟังก์ชันแสดงข้อมูลโรคประจำตัว - แก้ไขเพื่อจัดการ "none"
  String _getCongenitalDiseasesText(VolunteerModel volunteer) {
    if (isLoadingDetails) {
      return 'กำลังโหลดข้อมูล...';
    }

    if (volunteer.applyForm?.congenitalDiseases?.isNotEmpty == true) {
      final congenitalDiseases =
          volunteer.applyForm!.congenitalDiseases.trim().toLowerCase();

      // ✅ เช็คว่าเป็น "none" หรือไม่
      if (congenitalDiseases == 'none' ||
          congenitalDiseases == 'ไม่มี' ||
          congenitalDiseases == '-') {
        return 'ไม่มีโรคประจำตัว';
      }

      return volunteer.applyForm!.congenitalDiseases;
    }

    return 'ไม่มีข้อมูลโรคประจำตัว';
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ใช้ detailedVolunteer ถ้ามี ไม่งั้นใช้ widget.volunteer
    final volunteer = detailedVolunteer ?? widget.volunteer;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          volunteer.name,
          style: const TextStyle(
            fontFamily: 'Kanit',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        // ✅ เพิ่มปุ่ม refresh
        actions: [
          IconButton(
            icon:
                isLoadingDetails
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.refresh, color: Colors.white),
            onPressed: isLoadingDetails ? null : _loadDetailedVolunteerData,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),

              // ✅ แสดงสถานะการโหลด
              if (isLoadingDetails)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'กำลังโหลดข้อมูลละเอียด...',
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                width: double.infinity,
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
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'ข้อมูลอาสาสมัคร',
                              style: TextStyle(
                                fontFamily: 'Kanit',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          // Status Badge
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
                              volunteer.volunteerStatus ?? 'ไม่ระบุ',
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

                    Divider(height: 1, color: AppTheme.borderColor),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          infoRow(
                            'ชื่อ-นามสกุล',
                            volunteer.name,
                            Icons.person_rounded,
                          ),
                          infoRow(
                            'อีเมล',
                            volunteer.userEmail,
                            Icons.email_rounded,
                          ),
                          infoRow(
                            'อายุ',
                            '${volunteer.age} ปี',
                            Icons.cake_rounded,
                          ),
                          infoRow(
                            'เพศ',
                            volunteer.getGenderText(),
                            Icons.people_rounded,
                          ),
                          infoRow(
                            'เบอร์โทร',
                            volunteer.getPhoneNumber(),
                            Icons.phone_rounded,
                          ),
                          infoRow(
                            'น้ำหนัก',
                            '${volunteer.weight} กิโลกรัม',
                            Icons.monitor_weight_rounded,
                          ),
                          infoRow(
                            'ส่วนสูง',
                            '${volunteer.height} เซนติเมตร',
                            Icons.height_rounded,
                          ),
                          infoRow(
                            'ความสามารถพิเศษ',
                            volunteer.talent,
                            Icons.star_rounded,
                          ),
                          infoRow(
                            'ประสบการณ์การอบรม',
                            volunteer.isTraining
                                ? 'ไม่เคยเคยผ่านการอบรม'
                                : 'ผ่านการอบรม',
                            volunteer.isTraining
                                ? Icons.cancel_rounded
                                : Icons.check_circle_rounded,
                          ),

                          // ✅ ข้อมูลอาหารที่แพ้และโรคประจำตัว - ปรับปรุงแล้ว
                          specialInfoRow(
                            'อาหารที่แพ้',
                            _getAllergicFoodText(volunteer),
                            Icons.restaurant_menu_rounded,
                            const Color(0xFFFFF3E0),
                            const Color(0xFFF57C00),
                          ),

                          specialInfoRow(
                            'โรคประจำตัว',
                            _getCongenitalDiseasesText(volunteer),
                            Icons.health_and_safety_rounded,
                            const Color(0xFFE3F2FD),
                            const Color(0xFF1976D2),
                          ),

                          infoRow(
                            'วันที่สมัคร',
                            formatDate(volunteer.applicationDate),
                            Icons.calendar_today_rounded,
                          ),
                          infoRow(
                            'วันที่เข้าร่วม',
                            volunteer.entryDate.isNotEmpty
                                ? formatDate(volunteer.entryDate)
                                : 'ยังไม่ได้เข้าร่วม',
                            Icons.event_available_rounded,
                          ),
                          infoRow(
                            'สถานะ',
                            volunteer.volunteerStatus ?? 'ไม่ระบุสถานะ',
                            Icons.info_rounded,
                          ),
                          infoRow(
                            'ที่อยู่',
                            volunteer.getFullAddress(),
                            Icons.location_on_rounded,
                          ),

                          // ✅ แสดงข้อมูล Debug เมื่อไม่มี applyForm
                          if (volunteer.applyForm == null &&
                              !isLoadingDetails) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text(
                                        'ข้อมูลไม่ครบถ้วน',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                          fontFamily: 'Kanit',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('อีเมล: ${volunteer.userEmail}'),
                                  const Text('ไม่พบข้อมูลใบสมัคร (ApplyForm)'),
                                  const Text(
                                    'กรุณากดปุ่มรีเฟรชเพื่อโหลดข้อมูลใหม่',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
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
              Icons.person_search_rounded,
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
                  'รายละเอียดข้อมูล',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  'ข้อมูลอาสาสมัคร',
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
                  'ชื่อ: ${widget.volunteer.name}',
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ผ่านการคัดเลือก':
        return AppTheme.primaryColor;
      case 'ไม่ผ่านการคัดเลือก':
        return const Color(0xFFF44336);
      case 'รอการตรวจสอบ':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

