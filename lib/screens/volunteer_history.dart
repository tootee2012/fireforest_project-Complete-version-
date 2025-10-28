import 'package:fireforest_project/screens/user_fire_report_detail.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import '../model/history_model.dart';
import '../model/volunteer_model.dart';
import '../service.dart';

class VolunteerHistoryPage extends StatefulWidget {
  final String userEmail;

  const VolunteerHistoryPage({super.key, required this.userEmail});

  @override
  State<VolunteerHistoryPage> createState() => _VolunteerHistoryPageState();
}

class _VolunteerHistoryPageState extends State<VolunteerHistoryPage>
    with TickerProviderStateMixin {
  Service service = Service();
  List<HistoryModel> histories = [];
  VolunteerModel? volunteer;
  bool isLoading = true;

  // ✅ เพิ่ม Animation Controller เหมือน home
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Animation Setup เหมือน home
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadHistory();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ✅ ปรับปรุงฟังก์ชัน _loadHistory ให้รวม experience system
  void _loadHistory() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      print('🔄 Loading history and volunteer data for: ${widget.userEmail}');

      // 1. โหลด history และ volunteer data พร้อมกัน
      final futures = await Future.wait([
        service.getVolunteerHistory(widget.userEmail),
        service.getVolunteerByEmail(widget.userEmail),
        service.getVolunteerHistoryCount(widget.userEmail),
      ]);

      final fetchedHistory = futures[0] as List<HistoryModel>;
      final volunteerData = futures[1] as VolunteerModel?;
      final historyCount = futures[2] as int;

      print('📊 Loaded ${fetchedHistory.length} history records');
      print('👤 Volunteer data: ${volunteerData?.experience?.experienceId}');
      print('📈 History count: $historyCount');

      if (mounted) {
        setState(() {
          histories = fetchedHistory;
          volunteer = volunteerData;
          isLoading = false;
        });
      }

      // 2. ✅ Auto-update experience level หากจำเป็น
      await _checkAndUpdateExperience(historyCount);
    } catch (e) {
      print("❌ Error loading history: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ✅ ฟังก์ชัน check และ update experience
  Future<void> _checkAndUpdateExperience(int completedTasks) async {
    try {
      if (volunteer == null) return;

      // คำนวณ experience level ที่ควรจะเป็น
      int expectedExperienceId = 1; // Default: เริ่มต้น
      if (completedTasks > 4) {
        expectedExperienceId = 3; // มีประสบการณ์สูง
      } else if (completedTasks > 2) {
        expectedExperienceId = 2; // มีประสบการณ์
      }

      int currentExperienceId = volunteer?.experience?.experienceId ?? 1;

      // ถ้า experience level เปลี่ยนแปลง ให้อัพเดท
      if (expectedExperienceId != currentExperienceId) {
        print(
          '🔄 Updating experience level from $currentExperienceId to $expectedExperienceId (Completed: $completedTasks tasks)',
        );

        try {
          // อัพเดท experience level
          await service.updateVolunteerExperience(
            widget.userEmail,
            expectedExperienceId,
          );

          // โหลดข้อมูล volunteer ใหม่
          final updatedVolunteer = await service.getVolunteerByEmail(
            widget.userEmail,
          );

          if (mounted) {
            setState(() {
              volunteer = updatedVolunteer;
            });

            // แสดง notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🎉 ระดับประสบการณ์อัพเดทเป็น "${_getExperienceText(expectedExperienceId)}"',
                  style: const TextStyle(fontFamily: 'Sarabun'),
                ),
                backgroundColor: AppTheme.primaryColor,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        } catch (updateError) {
          print('❌ Error updating experience: $updateError');
        }
      }
    } catch (e) {
      print('❌ Error checking experience: $e');
    }
  }

  // ✅ Helper functions เหมือน service.dart
  String _getExperienceText(int experienceId) {
    switch (experienceId) {
      case 3:
        return 'มีประสบการณ์สูง';
      case 2:
        return 'มีประสบการณ์';
      case 1:
      default:
        return 'เริ่มต้น';
    }
  }

  Color _getExperienceColor(int experienceId) {
    switch (experienceId) {
      case 3:
        return AppTheme.primaryColor; // เขียวเข้ม
      case 2:
        return AppTheme.primaryColor; // เขียว
      case 1:
      default:
        return const Color(0xFF9C27B0); // ม่วง
    }
  }

  IconData _getExperienceIcon(int experienceId) {
    switch (experienceId) {
      case 3:
        return Icons.workspace_premium_rounded; // ไอคอนเหรียญทอง
      case 2:
        return Icons.military_tech_rounded; // ไอคอนเหรียญ
      case 1:
      default:
        return Icons.emoji_events_outlined; // ไอคอนถ้วยรางวัล
    }
  }

  String _getNextLevelRequirement(int currentExperienceId) {
    switch (currentExperienceId) {
      case 1:
        return 'ทำงานให้เสร็จ 3 งานเพื่อขึ้นเป็น "มีประสบการณ์"';
      case 2:
        return 'ทำงานให้เสร็จ 5 งานเพื่อขึ้นเป็น "มีประสบการณ์สูง"';
      case 3:
      default:
        return 'คุณอยู่ในระดับสูงสุดแล้ว!';
    }
  }

  // ✅ Experience Level Card เหมือน home style
  Widget _buildExperienceCard() {
    final currentExperienceId = volunteer?.experience?.experienceId ?? 1;
    final completedTasks = histories.where((h) => h.isCompleted).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getExperienceColor(currentExperienceId),
                      _getExperienceColor(currentExperienceId).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getExperienceIcon(currentExperienceId),
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
                      'ระดับประสบการณ์',
                      style: TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 14,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      _getExperienceText(currentExperienceId),
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _getExperienceColor(currentExperienceId),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'งานที่สำเร็จ: $completedTasks/${histories.length}',
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

          const SizedBox(height: 16),

          // Progress to next level
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getNextLevelRequirement(currentExperienceId),
                    style: const TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 12,
                      color: Color(0xFF616161),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ History Card สไตล์ home
  Widget _buildHistoryCard(HistoryModel history) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          history.isCompleted
                              ? [AppTheme.primaryColor, const Color(0xFF66BB6A)]
                              : [
                                const Color(0xFFFF9800),
                                const Color(0xFFFFB74D),
                              ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    history.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.access_time_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        history.isCompleted
                            ? AppTheme.primaryColor
                            : const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    history.isCompleted ? "เสร็จสิ้น" : "ดำเนินการ",
                    style: const TextStyle(
                      fontFamily: 'Sarabun',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        history.isCompleted
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    history.isCompleted
                        ? Icons.verified_rounded
                        : Icons.pending_rounded,
                    color:
                        history.isCompleted
                            ? AppTheme.primaryColor
                            : const Color(0xFFFF9800),
                    size: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // งาน ID
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.badge_rounded,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "งาน ID:",
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${history.fireForestId}",
                    style: const TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // สถานที่
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "สถานที่",
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        history.location,
                        style: const TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 14,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // วันที่และเวลา
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "วันที่ปฏิบัติงาน",
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      history.date,
                      style: const TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 13,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // สถานะงาน
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "สถานะ:",
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    history.status,
                    style: const TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 14,
                      color: Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ปุ่มดูรายละเอียด สไตล์ home
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) => const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                    );

                    // Fetch the full report data
                    final report = await service.getFireForestById(
                      history.fireForestId,
                    );

                    // Hide loading indicator
                    if (mounted) Navigator.pop(context);

                    // Check if report is not null before navigating
                    if (report != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FireReportDetailPage(report: report),
                        ),
                      );
                    } else if (mounted) {
                      // Show error if report is null
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ไม่พบข้อมูลรายงาน',
                            style: TextStyle(fontFamily: 'Sarabun'),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    // Hide loading indicator
                    if (mounted) Navigator.pop(context);

                    // Show error message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'ไม่สามารถโหลดข้อมูลได้: $e',
                            style: const TextStyle(fontFamily: 'Sarabun'),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "ดูรายละเอียด",
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.backgroundColor, // ✅ เปลี่ยนสีพื้นหลังเหมือน home
      appBar: AppBar(
        title: const Text(
          "ประวัติการทำงาน",
          style: TextStyle(
            fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์เหมือน home
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.primaryColor, // ✅ สี AppBar เหมือน home
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ✅ เพิ่มปุ่มรีเฟรชเหมือน home
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadHistory,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async => _loadHistory(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child:
              isLoading
                  ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'กำลังโหลดข้อมูลและตรวจสอบระดับประสบการณ์...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Sarabun',
                            fontSize: 16,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  )
                  : histories.isEmpty
                  ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: Color(0xFF9E9E9E),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "ยังไม่มีประวัติการทำงาน",
                              style: TextStyle(
                                fontFamily: 'Kanit',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF757575),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "เมื่อคุณเข้าร่วมงานอาสาสมัคร\nประวัติจะปรากฏที่นี่",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Sarabun',
                                fontSize: 14,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  : Column(
                    children: [
                      // ✅ Experience Level Card
                      _buildExperienceCard(),

                      // รายการประวัติ
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: histories.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(histories[index]);
                          },
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
