import 'package:fireforest_project/model/fireforest_model.dart';
import 'package:fireforest_project/screens/user_edit_profile.dart';
import 'package:fireforest_project/screens/login.dart';
import 'package:fireforest_project/screens/user_fire_report_list.dart';
import 'package:fireforest_project/screens/user_list_recruit.dart';
import 'package:fireforest_project/screens/user_report_fire.dart';
import 'package:fireforest_project/screens/user_volunteer_status.dart';
import 'package:fireforest_project/service.dart';
import 'package:fireforest_project/utils.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  final String userEmail;

  const HomePage({super.key, required this.userEmail});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final Service _service = Service();
  List<FireforestModel>? _cachedReports;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    _loadReports();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _service.getFireForestByEmail(widget.userEmail);
      if (mounted) {
        setState(() {
          _cachedReports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshReports() async {
    await _loadReports();
  }

  void _navigateToReportFire() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportFirePage(userEmail: widget.userEmail),
      ),
    );

    // ✅ รีเฟรชข้อมูลเมื่อแจ้งเหตุสำเร็จ
    if (result == true) {
      _refreshReports();
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            content: const Text(
              'คุณต้องการออกจากระบบหรือไม่?',
              style: TextStyle(
                fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                fontSize: 16,
                color: Color(0xFF424242),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'ยกเลิก',
                  style: TextStyle(
                    fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _performLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'แอปพลิเคชันแจ้งเหตุไฟป่า',
          style: TextStyle(
            fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsBottomSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _refreshReports, // ✅ เพิ่ม pull-to-refresh
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // ✅ ทำให้ pull-to-refresh ทำงาน
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Welcome Header Card
                _buildWelcomeCard(),

                const SizedBox(height: 24),

                // Main Menu Grid
                _buildMainMenuGrid(),

                const SizedBox(height: 24),

                // Recent Reports
                _buildRecentReports(),
              ],
            ),
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
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
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
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.eco_rounded,
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
                      'ยินดีต้อนรับสู่',
                      style: TextStyle(
                        fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                        fontSize: 16,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Text(
                      'ระบบแจ้งเหตุไฟป่า',
                      style: TextStyle(
                        fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ผู้ใช้งาน: ${widget.userEmail}',
                      style: const TextStyle(
                        fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
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
        ],
      ),
    );
  }

  Widget _buildMainMenuGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio:
          1.1, // ✅ เปลี่ยนจาก 0.9 เป็น 1.1 เพื่อให้ช่องสี่เหลี่ยมเตี้ยลง
      children: [
        _MainMenuButton(
          icon: Icons.warning_amber_rounded,
          title: 'แจ้งเหตุไฟป่า',
          subtitle: 'รายงานเหตุฉุกเฉิน',
          color: AppTheme.primaryLight,
          onTap: _navigateToReportFire,
        ),
        _MainMenuButton(
          icon: Icons.location_on_rounded,
          title: 'ดูสถานะการแจ้ง',
          subtitle: 'ติดตามความคืบหน้า',
          color: AppTheme.primaryColor,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          FireReportListPage(userEmail: widget.userEmail),
                ),
              ),
        ),
        _MainMenuButton(
          icon: Icons.people_alt_rounded,
          title: 'สมัครอาสาสมัคร',
          subtitle: 'เข้าร่วมช่วยเหลือ',
          color: AppTheme.primaryDark,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => Listrecruit(userEmail: widget.userEmail),
                ),
              ),
        ),
        _MainMenuButton(
          icon: Icons.check_circle_rounded,
          title: 'ตรวจผลการสมัคร',
          subtitle: 'ดูสถานะใบสมัคร',
          color: AppTheme.accent,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          VolunteerStatusPage(userEmail: widget.userEmail),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildRecentReports() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
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
                    Icons.history_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'รายงานล่าสุด',
                    style: TextStyle(
                      fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                // ✅ เพิ่มปุ่มรีเฟรช
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                  onPressed: _refreshReports,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFFFE0B2)),
          SizedBox(
            height: 320,
            child: RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _refreshReports,
              child: _buildReportsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'กำลังโหลดข้อมูล...',
              style: TextStyle(
                fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                fontSize: 16,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      );
    }

    if (_cachedReports == null || _cachedReports!.isEmpty) {
      return Center(
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
                Icons.inbox_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ไม่มีรายงานล่าสุด',
              style: TextStyle(
                fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'เมื่อคุณแจ้งเหตุไฟป่า รายงานจะปรากฏที่นี่',
              style: TextStyle(
                fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                fontSize: 14,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      );
    }

    final latestReports =
        _cachedReports!.length > 5
            ? _cachedReports!.sublist(0, 5)
            : _cachedReports!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: latestReports.length,
      itemBuilder: (context, index) {
        final report = latestReports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE0B2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.fireForestLocation ?? 'ไม่ระบุสถานที่',
                      style: const TextStyle(
                        fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Utils.formatDateTime(
                        report.fireForestTime ?? 'ไม่ระบุเวลา',
                      ),
                      style: TextStyle(
                        fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(report.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  report.status ?? 'ไม่ระบุ',
                  style: const TextStyle(
                    fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'กำลังดำเนินการ':
        return AppTheme.warning;
      case 'เสร็จสิ้น':
        return AppTheme.success;
      case 'รอการตรวจสอบ':
        return AppTheme.info;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ยินดีต้อนรับ',
                            style: TextStyle(
                              fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                          Text(
                            widget.userEmail,
                            style: const TextStyle(
                              fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),

                // Menu Items
                _buildSettingsMenuItem(
                  Icons.edit_rounded,
                  'แก้ไขข้อมูลส่วนตัว',
                  'จัดการโปรไฟล์ของคุณ',
                  AppTheme.primaryColor,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                EditProfilePage(email: widget.userEmail),
                      ),
                    );
                  },
                ),

                _buildSettingsMenuItem(
                  Icons.logout_rounded,
                  'ออกจากระบบ',
                  'ออกจากบัญชีของคุณ',
                  Colors.red,
                  () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildSettingsMenuItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E2E2E),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.grey[400],
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

// Enhanced Main Menu Button Component
class _MainMenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MainMenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12, // ✅ ลด horizontal padding
              vertical: 16, // ✅ เพิ่ม vertical padding เพื่อให้บนล่างเท่ากัน
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // ✅ จัดให้อยู่กลางแนวตั้ง
              crossAxisAlignment:
                  CrossAxisAlignment.center, // ✅ จัดให้อยู่กลางแนวนอน
              children: [
                // ✅ เพิ่ม Flexible เพื่อให้ไอคอนอยู่กลาง
                Flexible(
                  flex: 3, // ✅ กำหนดพื้นที่สำหรับไอคอน
                  child: Container(
                    width: 48, // ✅ ลดขนาดไอคอนลงอีก
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24, // ✅ ลดขนาดไอคอน
                    ),
                  ),
                ),

                // ✅ เพิ่ม spacing ที่ยืดหยุ่น
                const SizedBox(height: 8),

                // ✅ ใช้ Flexible สำหรับ text
                Flexible(
                  flex: 2, // ✅ กำหนดพื้นที่สำหรับ title
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 13, // ✅ ลดขนาดฟอนต์อีก
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      height: 1.2, // ✅ ปรับ line height
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ✅ ใช้ Flexible สำหรับ subtitle
                Flexible(
                  flex: 1, // ✅ กำหนดพื้นที่สำหรับ subtitle
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1, // ✅ จำกัดให้ 1 บรรทัด
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 10, // ✅ ลดขนาดฟอนต์
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                      height: 1.1, // ✅ ปรับ line height
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
