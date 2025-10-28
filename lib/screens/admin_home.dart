import 'package:fireforest_project/screens/admin_close_recruit.dart';
import 'package:fireforest_project/screens/admin_fire_list.dart';
import 'package:fireforest_project/screens/login.dart';
import 'package:fireforest_project/screens/admin_recruit_list.dart';
import 'package:fireforest_project/screens/admin_recruit_volunteer.dart';
import 'package:fireforest_project/service.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'dart:async';

class Adminhome extends StatefulWidget {
  final String agencyEmail;
  const Adminhome({super.key, required this.agencyEmail});

  @override
  State<Adminhome> createState() => _AdminhomeState();
}

class _AdminhomeState extends State<Adminhome> with TickerProviderStateMixin {
  final Service service = Service();
  int unreadNotifications = 0;
  Timer? _notificationTimer;
  List<Map<String, dynamic>> recentReports = [];
  DateTime? lastCheckTime;
  bool isCheckingNotifications = false;
  String? errorMessage;

  // ✅ เพิ่ม Animation Controller เหมือน home
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ เพิ่ม Animation Setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeNotifications();
    _startNotificationChecking();
    _animationController.forward();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _animationController.dispose(); // ✅ เพิ่ม dispose animation
    super.dispose();
  }

  void _initializeNotifications() {
    lastCheckTime = DateTime.now().subtract(const Duration(minutes: 1));
    debugPrint('🔔 Initializing notifications at: $lastCheckTime');
    _checkForNewFireReports();
  }

  void _startNotificationChecking() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint('🔔 Checking for new notifications...');
      _checkForNewFireReports();
    });
  }

  Future<void> _checkForNewFireReports() async {
    if (isCheckingNotifications) return;

    setState(() {
      isCheckingNotifications = true;
      errorMessage = null;
    });

    try {
      final reports = await service.getRecentFireReports(lastCheckTime);
      debugPrint('📊 Received ${reports.length} reports from API');

      if (reports.isNotEmpty && mounted) {
        final newReports =
            reports.where((report) {
              try {
                final reportTime = DateTime.parse(report['timestamp']);
                return lastCheckTime == null ||
                    reportTime.isAfter(lastCheckTime!);
              } catch (e) {
                debugPrint('Error parsing timestamp: ${report['timestamp']}');
                return false;
              }
            }).toList();

        debugPrint('🆕 Found ${newReports.length} new reports');

        if (newReports.isNotEmpty) {
          setState(() {
            unreadNotifications += newReports.length;
            recentReports.addAll(newReports);

            if (recentReports.length > 10) {
              recentReports = recentReports.take(10).toList();
            }
          });

          if (mounted) {
            _showNewReportNotification(newReports.first);
          }
        }
      }

      lastCheckTime = DateTime.now();
    } catch (e) {
      debugPrint('❌ Error checking for new reports: $e');
      setState(() {
        errorMessage = 'ไม่สามารถตรวจสอบรายงานใหม่ได้: $e';
      });

      if (mounted && e.toString().contains('connection')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'ลองใหม่',
              onPressed: () => _checkForNewFireReports(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isCheckingNotifications = false;
        });
      }
    }
  }

  void _showNewReportNotification(Map<String, dynamic> report) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (BuildContext dialogContext) => AlertDialog(
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
                  child: Icon(Icons.warning, color: Colors.red.shade600),
                ),
                const SizedBox(width: 12),
                const Text(
                  '🔥 แจ้งเหตุไฟป่าใหม่!',
                  style: TextStyle(
                    fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'พื้นที่: ${report['location'] ?? 'ไม่ระบุ'}',
                  style: const TextStyle(
                    fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ระดับความรุนแรง: ${report['severity'] ?? 'ไม่ระบุ'}',
                  style: const TextStyle(
                    fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ประเภทพื้นที่: ${report['areaType'] ?? 'ไม่ระบุ'}',
                  style: const TextStyle(
                    fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เวลา: ${_formatDateTime(report['timestamp'])}',
                  style: TextStyle(
                    fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'ปิด',
                  style: TextStyle(
                    fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _navigateToFireList();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'ดูรายละเอียด',
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

  String _formatDateTime(String? timestamp) {
    if (timestamp == null) return 'ไม่ระบุ';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'ไม่ระบุ';
    }
  }

  void _navigateToFireList() {
    setState(() {
      unreadNotifications = 0;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FireListAdminPage(agencyEmail: widget.agencyEmail),
      ),
    );
  }

  void _showNotificationList() {
    if (recentReports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีการแจ้งเตือนใหม่'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'รายการแจ้งเตือนใหม่ (${recentReports.length})',
              style: const TextStyle(
                fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: recentReports.length,
                itemBuilder: (context, index) {
                  final report = recentReports[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.warning, color: Colors.red.shade600),
                      title: Text(
                        report['location'] ?? 'ไม่ระบุพื้นที่',
                        style: const TextStyle(
                          fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'ระดับ: ${report['severity']} | ${_formatDateTime(report['timestamp'])}',
                        style: const TextStyle(
                          fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                        ),
                      ),
                      dense: true,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _navigateToFireList();
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'ปิด',
                  style: TextStyle(
                    fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _navigateToFireList();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'ดูทั้งหมด',
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

  Future<void> _manualRefresh() async {
    await _checkForNewFireReports();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 รีเฟรชรายงานแล้ว'),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSettingsBottomSheet(BuildContext context) {
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
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
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
                            'ยินดีต้อนรับ Agency',
                            style: TextStyle(
                              fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                          Text(
                            widget.agencyEmail,
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
                  Icons.refresh_rounded,
                  'รีเฟรชข้อมูล',
                  'อัพเดทรายงานล่าสุด',
                  AppTheme.primaryColor,
                  () {
                    Navigator.pop(context);
                    _manualRefresh();
                  },
                ),

                _buildSettingsMenuItem(
                  Icons.logout_rounded,
                  'ออกจากระบบ',
                  'ออกจากบัญชีของคุณ',
                  Colors.red,
                  () {
                    Navigator.pop(context);
                    _showLogoutDialog(context);
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

  void _showLogoutDialog(BuildContext context) {
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
                  _performLogout(context);
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

  void _performLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, // ✅ พื้นหลังสีเขียวอ่อน
      appBar: AppBar(
        title: const Text(
          'หน้าหลัก Agency',
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
        backgroundColor: AppTheme.primaryColor, // ✅ AppBar สีเขียวมะกอก
        actions: [
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                ),
                tooltip: 'การแจ้งเตือน',
                onPressed: _showNotificationList,
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                      style: const TextStyle(
                        fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettingsBottomSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _checkForNewFireReports,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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

                // Recent Reports Section
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
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
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
                      'หน้าหลัก Agency',
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
                      'Agency: ${widget.agencyEmail}',
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

          // Notification Alert
          if (unreadNotifications > 0) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showNotificationList,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade50, Colors.orange.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'มีการแจ้งเตือนใหม่ $unreadNotifications รายการ',
                            style: const TextStyle(
                              fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          const Text(
                            'แตะเพื่อดูรายละเอียด',
                            style: TextStyle(
                              fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.red,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Loading Indicator
          if (isCheckingNotifications) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'กำลังตรวจสอบรายงานใหม่...',
                  style: TextStyle(
                    fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
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
      childAspectRatio: 1.0, // ✅ เปลี่ยนเป็น 1.0 ให้เป็นสี่เหลี่ยมจัตุรัส
      children: [
        _AdminMenuButton(
          icon: Icons.group_add_rounded,
          title: 'เปิดรับอาสาสมัคร',
          subtitle: 'สร้างโครงการใหม่',
          color: AppTheme.primaryLight,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          RecruitVolunteerPage(agencyEmail: widget.agencyEmail),
                ),
              ),
        ),
        _AdminMenuButton(
          icon: Icons.how_to_reg_rounded,
          title: 'คัดเลือกอาสาสมัคร',
          subtitle: 'จัดการใบสมัคร',
          color: AppTheme.primaryColor,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecruitListScreen(),
                ),
              ),
        ),
        _AdminMenuButton(
          icon: Icons.group_remove_rounded,
          title: 'ปิดรับอาสาสมัคร',
          subtitle: 'จัดการโครงการ',
          color: AppTheme.primaryColor,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CloseRecruit()),
              ),
        ),
        _AdminMenuButton(
          icon: Icons.report_problem_rounded,
          title: 'เหตุที่แจ้งเข้ามา',
          subtitle: 'ตรวจสอบรายงาน',
          color: AppTheme.primaryColor,
          hasNotification: unreadNotifications > 0,
          notificationCount: unreadNotifications,
          onTap: _navigateToFireList,
        ),
      ],
    );
  }

  Widget _buildRecentReports() {
    return Container(
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
                if (recentReports.isNotEmpty)
                  TextButton(
                    onPressed: _showNotificationList,
                    child: const Text(
                      'ดูทั้งหมด',
                      style: TextStyle(
                        fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderColor),
          SizedBox(
            height: 320,
            child:
                recentReports.isEmpty
                    ? Center(
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
                            'ไม่มีรายงานใหม่',
                            style: TextStyle(
                              fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'เมื่อมีการแจ้งเหตุไฟป่า รายงานจะปรากฏที่นี่',
                            style: TextStyle(
                              fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                              fontSize: 14,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          recentReports.length > 5 ? 5 : recentReports.length,
                      itemBuilder: (context, index) {
                        final report = recentReports[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.borderColor,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: _navigateToFireList,
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.primaryLight,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.warning_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report['location'] ?? 'ไม่ระบุสถานที่',
                                        style: const TextStyle(
                                          fontFamily:
                                              'Kanit', // ✅ เพิ่มฟอนต์สวย
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ระดับ: ${report['severity'] ?? 'ไม่ระบุ'}',
                                        style: TextStyle(
                                          fontFamily:
                                              'Sarabun', // ✅ เพิ่มฟอนต์สวย
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        _formatDateTime(report['timestamp']),
                                        style: TextStyle(
                                          fontFamily:
                                              'Sarabun', // ✅ เพิ่มฟอนต์สวย
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
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'ใหม่',
                                    style: TextStyle(
                                      fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์สวย
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Admin Menu Button Component
class _AdminMenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool hasNotification;
  final int notificationCount;

  const _AdminMenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.hasNotification = false,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
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
                // ✅ ปรับ padding ให้บนล่างเท่ากัน และลดขนาดลง 60%
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20, // ✅ ปรับให้บนล่างเท่ากัน
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // ✅ ให้อยู่กลาง
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // ✅ ให้อยู่กลาง
                  children: [
                    // ✅ ลดขนาดไอคอนลง 60%
                    Container(
                      width: 44, // ✅ จาก 56 เป็น 44 (ลดลง ~22%)
                      height: 44, // ✅ จาก 56 เป็น 44 (ลดลง ~22%)
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color, color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(
                          14,
                        ), // ✅ ปรับให้เข้ากับขนาดใหม่
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
                        size: 22, // ✅ ลดจาก 28 เป็น 22 (ลดลง ~21%)
                      ),
                    ),

                    const SizedBox(height: 8), // ✅ ลดระยะห่าง
                    // ✅ Title - ให้อยู่กลางและปรับขนาด
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 13, // ✅ ลดจาก 15 เป็น 13
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                        height: 1.2, // ✅ ปรับความสูงบรรทัด
                      ),
                    ),

                    const SizedBox(height: 4), // ✅ ลดระยะห่าง
                    // ✅ Subtitle - ให้อยู่กลางและปรับขนาด
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 10, // ✅ ลดจาก 11 เป็น 10
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                        height: 1.3, // ✅ ปรับความสูงบรรทัด
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Notification badge
        if (hasNotification && notificationCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              child: Text(
                notificationCount > 99 ? '99+' : '$notificationCount',
                style: const TextStyle(
                  fontFamily: 'Sarabun',
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

