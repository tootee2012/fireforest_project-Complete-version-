import 'package:fireforest_project/model/fireforest_model.dart';
import 'package:fireforest_project/screens/home.dart';
import 'package:fireforest_project/screens/login.dart';
import 'package:fireforest_project/screens/volunteer_history.dart';
import 'package:fireforest_project/screens/volunteer_summary_report.dart';
import 'package:fireforest_project/screens/volunteer_task.dart';
import 'package:fireforest_project/service.dart';
import 'package:fireforest_project/utils.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'dart:async';
import 'dart:convert';

class HomeVolunteer extends StatefulWidget {
  final String userEmail;

  const HomeVolunteer({super.key, required this.userEmail});

  @override
  State<HomeVolunteer> createState() => _HomeVolunteerState();
}

class _HomeVolunteerState extends State<HomeVolunteer>
    with TickerProviderStateMixin {
  final Service _service = Service();
  List<Map<String, dynamic>> notifications = [];
  int unreadCount = 0;
  Timer? _notificationTimer;
  bool isLoading = false;
  String? volunteerWorkStatus; // ✅ เพิ่มตัวแปรเก็บ workStatus
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

    _loadNotifications();
    _loadVolunteerStatus(); // ✅ เพิ่มการโหลดสถานะ
    _startNotificationTimer();
    _animationController.forward();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ เพิ่มฟังก์ชันโหลดสถานะอาสาสมัคร
  Future<void> _loadVolunteerStatus() async {
    try {
      final volunteer = await _service.getVolunteerByEmail(widget.userEmail);
      if (mounted && volunteer != null) {
        setState(() {
          volunteerWorkStatus = volunteer.joinMember?.workStatus;
        });
        print('🔍 Volunteer work status: $volunteerWorkStatus');
      }
    } catch (e) {
      print('❌ Error loading volunteer status: $e');
    }
  }

  Future<void> _loadNotifications() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final data = await _service.getVolunteerNotifications(widget.userEmail);
      if (mounted) {
        setState(() {
          notifications = data;
          unreadCount = data.where((n) => n['isRead'] == false).length;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadNotifications();
      _loadVolunteerStatus(); // ✅ อัปเดตสถานะด้วย
    });
  }

  // ✅ เพิ่มฟังก์ชันตรวจสอบสถานะก่อนเข้าปุ่มรายงาน
  void _checkStatusAndNavigateToReport() {
    if (volunteerWorkStatus != 'assigned') {
      _showStatusWarningDialog();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryReportPage(userEmail: widget.userEmail),
        ),
      );
    }
  }

  // ✅ เพิ่ม Dialog แจ้งเตือนสถานะ
  void _showStatusWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ไม่สามารถเข้าใช้งานได้',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange.shade700,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'คุณยังไม่ได้เข้าช่วยเหลือไฟป่าในขณะนี้',
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'หรือมีผู้เข้าร่วมอื่นส่งรายงานเหตุไฟป่าแล้ว',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 14,
                      color: Color(0xFF616161),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.assignment_rounded,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'สถานะปัจจุบัน:',
                                style: TextStyle(
                                  fontFamily: 'Sarabun',
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _getWorkStatusText(volunteerWorkStatus),
                                style: TextStyle(
                                  fontFamily: 'Kanit',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getWorkStatusColor(
                                    volunteerWorkStatus,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ตกลง',
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => VolunteerTaskPage(
                                  userEmail: widget.userEmail,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.volunteer_activism, size: 18),
                      label: const Text(
                        'ดูงาน',
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  // ✅ ฟังก์ชันแปลงสถานะเป็นข้อความ
  String _getWorkStatusText(String? status) {
    switch (status) {
      case 'assigned':
        return 'กำลังปฏิบัติภารกิจ';
      case 'done':
        return 'เสร็จสิ้นภารกิจ พร้อมรับงานใหม่';
      case 'pending':
        return 'มีการมอบหมายงาน';
      case null:
        return 'ยังไม่ได้รับงาน';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  // ✅ ฟังก์ชันกำหนดสีสถานะ
  Color _getWorkStatusColor(String? status) {
    switch (status) {
      case 'assigned':
        return AppTheme.primaryColor;
      case 'completed':
        return const Color(0xFF2196F3);
      case 'pending':
        return const Color(0xFFFF9800);
      case null:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    final success = await _service.markNotificationAsRead(notificationId);
    if (success && mounted) {
      _loadNotifications();
    }
  }

  void _showNotificationDialog(Map<String, dynamic> notification) {
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
                    color:
                        notification['type'] == 'fire_alert'
                            ? Colors.red.shade100
                            : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    notification['type'] == 'fire_alert'
                        ? Icons.warning_amber_rounded
                        : Icons.assignment_rounded,
                    color:
                        notification['type'] == 'fire_alert'
                            ? Colors.red
                            : AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification['title'] ?? 'การแจ้งเตือน',
                    style: const TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['message'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 15,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 16),
                if (notification['data'] != null)
                  _buildNotificationData(notification['data']),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _markAsRead(notification['id']);
                },
                child: const Text(
                  'ปิด',
                  style: TextStyle(fontFamily: 'Sarabun', color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _markAsRead(notification['id']);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              VolunteerTaskPage(userEmail: widget.userEmail),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.volunteer_activism, size: 18),
                label: const Text(
                  'ดูงาน',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildNotificationData(dynamic data) {
    try {
      Map<String, dynamic> parsedData;

      if (data is String) {
        parsedData = json.decode(data);
      } else if (data is Map) {
        parsedData = Map<String, dynamic>.from(data);
      } else {
        return const Text(
          'ไม่สามารถแสดงข้อมูลเพิ่มเติมได้',
          style: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 13,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDCEDC8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parsedData['location'] != null)
              _buildInfoRow(
                Icons.location_on,
                'สถานที่: ${parsedData['location']}',
              ),
            if (parsedData['requiredVolunteers'] != null)
              _buildInfoRow(
                Icons.people,
                'ต้องการ: ${parsedData['requiredVolunteers']} คน',
              ),
            if (parsedData['fireForestId'] != null)
              _buildInfoRow(
                Icons.tag,
                'รหัสงาน: ${parsedData['fireForestId']}',
              ),
          ],
        ),
      );
    } catch (e) {
      return const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange),
          SizedBox(width: 6),
          Text(
            'ไม่สามารถแสดงข้อมูลเพิ่มเติมได้',
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 13,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
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

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'การแจ้งเตือน',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$unreadCount ใหม่',
                          style: const TextStyle(
                            fontFamily: 'Sarabun',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Notifications List
                Expanded(
                  child:
                      notifications.isEmpty
                          ? _buildEmptyNotifications()
                          : ListView.builder(
                            itemCount: notifications.length,
                            itemBuilder:
                                (context, index) => _buildNotificationItem(
                                  notifications[index],
                                ),
                          ),
                ),

                // Action Buttons
                if (notifications.isNotEmpty) _buildActionButtons(),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ไม่มีการแจ้งเตือน',
            style: TextStyle(
              fontFamily: 'Kanit',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เมื่อมีเหตุไฟป่าหรืองานมอบหมาย\nจะมีการแจ้งเตือนที่นี่',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isUnread = notification['isRead'] == false;
    final isFireAlert = notification['type'] == 'fire_alert';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? AppTheme.surfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? AppTheme.primaryColor : const Color(0xFFDCEDC8),
          width: isUnread ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isFireAlert
                    ? Colors.red.shade100
                    : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isFireAlert
                ? Icons.local_fire_department_rounded
                : Icons.assignment_turned_in_rounded,
            color: isFireAlert ? Colors.red : AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          notification['title'] ?? 'การแจ้งเตือน',
          style: TextStyle(
            fontFamily: 'Kanit',
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
            fontSize: 16,
            color: AppTheme.primaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              notification['message'] ?? '',
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatNotificationTime(notification['createdAt']),
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing:
            isUnread
                ? Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                )
                : Icon(
                  Icons.check_circle_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
        onTap: () {
          Navigator.pop(context);
          if (isUnread) _markAsRead(notification['id']);
          _showNotificationDialog(notification);
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (unreadCount > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  for (var notification in notifications) {
                    if (notification['isRead'] == false) {
                      await _markAsRead(notification['id']);
                    }
                  }
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text(
                  'อ่านทั้งหมด',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            VolunteerTaskPage(userEmail: widget.userEmail),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.volunteer_activism, size: 18),
              label: const Text(
                'ดูงานทั้งหมด',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNotificationTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inDays > 0) {
        return '${difference.inDays} วันที่แล้ว';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ชั่วโมงที่แล้ว';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} นาทีที่แล้ว';
      } else {
        return 'เมื่อสักครู่';
      }
    } catch (e) {
      return '';
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
                    fontFamily: 'Kanit',
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            content: const Text(
              'คุณต้องการออกจากระบบหรือไม่?',
              style: TextStyle(
                fontFamily: 'Sarabun',
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
                    fontFamily: 'Sarabun',
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                    (route) => false,
                  );
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
                    fontFamily: 'Sarabun',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
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
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                        ),
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
                              fontFamily: 'Sarabun',
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                          Text(
                            widget.userEmail,
                            style: const TextStyle(
                              fontFamily: 'Kanit',
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
                  Icons.person,
                  'กลับสู่หน้าผู้ใช้งาน',
                  'เปลี่ยนไปหน้าผู้ใช้ทั่วไป',
                  AppTheme.primaryColor,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => HomePage(userEmail: widget.userEmail),
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
            fontFamily: 'Kanit',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E2E2E),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Sarabun',
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'กำลังดำเนินการ':
        return const Color(0xFFFF9800);
      case 'เสร็จสิ้น':
        return AppTheme.primaryColor;
      case 'รอการตรวจสอบ':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'หน้าหลักอาสาสมัคร',
          style: TextStyle(
            fontFamily: 'Kanit',
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
          // Notification Button with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                ),
                onPressed: _showNotificationList,
              ),
              if (unreadCount > 0)
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
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        fontFamily: 'Sarabun',
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
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsBottomSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          await _loadNotifications();
          await _loadVolunteerStatus(); // ✅ รีเฟรชสถานะด้วย
        },
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
                  Icons.volunteer_activism_rounded,
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
                        fontFamily: 'Sarabun',
                        fontSize: 16,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Text(
                      'หน้าหลักอาสาสมัคร',
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
                      'อาสาสมัคร: ${widget.userEmail}',
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

          // ✅ แสดงสถานะอาสาสมัคร
          if (volunteerWorkStatus != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getWorkStatusColor(
                  volunteerWorkStatus,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getWorkStatusColor(
                    volunteerWorkStatus,
                  ).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getWorkStatusColor(volunteerWorkStatus),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      volunteerWorkStatus == 'assigned'
                          ? Icons.assignment_turned_in
                          : Icons.assignment_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'สถานะปัจจุบัน',
                          style: TextStyle(
                            fontFamily: 'Sarabun',
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                        Text(
                          _getWorkStatusText(volunteerWorkStatus),
                          style: TextStyle(
                            fontFamily: 'Kanit',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getWorkStatusColor(volunteerWorkStatus),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Notification Alert
          if (unreadCount > 0) ...[
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
                            'มีการแจ้งเตือนใหม่ $unreadCount รายการ',
                            style: const TextStyle(
                              fontFamily: 'Kanit',
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          const Text(
                            'แตะเพื่อดูรายละเอียด',
                            style: TextStyle(
                              fontFamily: 'Sarabun',
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
      childAspectRatio: 1.1,
      children: [
        _MainMenuButton(
          icon: Icons.local_fire_department_rounded,
          title: 'รับช่วยเหตุไฟป่า',
          subtitle: 'เข้าช่วยเหลือเหตุฉุกเฉิน',
          color: AppTheme.primaryLight,
          badge: unreadCount,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          VolunteerTaskPage(userEmail: widget.userEmail),
                ),
              ),
        ),

        // ✅ แก้ไขปุ่ม Summary Report
        _MainMenuButton(
          icon: Icons.assignment_rounded,
          title: 'รายงานเหตุไฟป่า',
          subtitle:
              volunteerWorkStatus == 'assigned'
                  ? 'สรุปภารกิจที่ผ่านมา'
                  : 'ต้องมีงานที่ได้รับมอบหมาย',
          color:
              volunteerWorkStatus == 'assigned'
                  ? AppTheme.primaryColor
                  : Colors.grey, // ✅ เปลี่ยนเป็นสีเทา
          isDisabled:
              volunteerWorkStatus != 'assigned', // ✅ เพิ่ม disabled state
          onTap: _checkStatusAndNavigateToReport,
        ),

        _MainMenuButton(
          icon: Icons.history_rounded,
          title: 'ประวัติการช่วยเหลือ',
          subtitle: 'ดูบันทึกการทำงาน',
          color: AppTheme.primaryColor,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          VolunteerHistoryPage(userEmail: widget.userEmail),
                ),
              ),
        ),
        _MainMenuButton(
          icon: Icons.person_rounded,
          title: 'กลับหน้าผู้ใช้งาน',
          subtitle: 'เปลี่ยนไปโหมดปกติ',
          color: AppTheme.primaryColor,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(userEmail: widget.userEmail),
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
          SizedBox(
            height: 320,
            child: FutureBuilder<List<FireforestModel>>(
              future: _service.getFireForestByEmail(widget.userEmail),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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
                            fontFamily: 'Sarabun',
                            fontSize: 16,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
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
                            fontFamily: 'Kanit',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'เมื่อมีการปฏิบัติงาน รายงานจะปรากฏที่นี่',
                          style: TextStyle(
                            fontFamily: 'Sarabun',
                            fontSize: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final reports = snapshot.data!;
                final latestReports =
                    reports.length > 5 ? reports.sublist(0, 5) : reports;

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
                        border: Border.all(
                          color: AppTheme.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                              ),
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
                                    fontFamily: 'Kanit',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Utils.formatDateTime(
                                    report.fireForestTime ?? 'ไม่ระบุเวลา',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Sarabun',
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
                  },
                );
              },
            ),
          ),
        ],
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
  final int? badge;
  final bool isDisabled; // ✅ เพิ่ม parameter ใหม่

  const _MainMenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
    this.isDisabled = false, // ✅ default เป็น false
  });

  @override
  Widget build(BuildContext context) {
    // ✅ กำหนดสีและ opacity สำหรับ disabled state
    final effectiveColor = isDisabled ? Colors.grey : color;
    final opacity = isDisabled ? 0.5 : 1.0;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                isDisabled
                    ? []
                    : [
                      // ✅ ลบ shadow เมื่อ disabled
                      BoxShadow(
                        color: effectiveColor.withOpacity(0.15),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
          ),
          child: Opacity(
            // ✅ เพิ่ม Opacity wrapper
            opacity: opacity,
            child: Material(
              color:
                  isDisabled
                      ? Colors.grey[100]
                      : Colors.white, // ✅ เปลี่ยนพื้นหลัง
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: isDisabled ? null : onTap, // ✅ ปิด onTap เมื่อ disabled
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient:
                                isDisabled
                                    ? LinearGradient(
                                      // ✅ Gradient สีเทาสำหรับ disabled
                                      colors: [
                                        Colors.grey[400]!,
                                        Colors.grey[500]!,
                                      ],
                                    )
                                    : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        effectiveColor,
                                        effectiveColor.withOpacity(0.8),
                                      ],
                                    ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow:
                                isDisabled
                                    ? []
                                    : [
                                      BoxShadow(
                                        color: effectiveColor.withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(icon, color: Colors.white, size: 24),
                              // ✅ เพิ่ม lock icon เมื่อ disabled
                              if (isDisabled)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Flexible(
                        flex: 2,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Kanit',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isDisabled
                                    ? Colors.grey[600] // ✅ สีเทาสำหรับ disabled
                                    : const Color(0xFF2E7D32),
                            height: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Flexible(
                        flex: 1,
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Sarabun',
                            fontSize: 10,
                            color:
                                isDisabled
                                    ? Colors.grey[500] // ✅ สีเทาสำหรับ disabled
                                    : Colors.grey[600],
                            fontWeight: FontWeight.w400,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Badge for notification count - ซ่อนเมื่อ disabled
        if (badge != null && badge! > 0 && !isDisabled)
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
                badge! > 99 ? '99+' : '$badge',
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

        // ✅ เพิ่ม disabled overlay
        if (isDisabled)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ปิดใช้งาน',
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}


