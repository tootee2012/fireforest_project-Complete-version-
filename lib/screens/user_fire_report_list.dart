import 'package:fireforest_project/model/fireforest_model.dart';
import 'package:fireforest_project/screens/user_fire_report_detail.dart';
import 'package:fireforest_project/service.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import '../utils.dart';

class FireReportListPage extends StatefulWidget {
  final String userEmail;

  const FireReportListPage({super.key, required this.userEmail});

  @override
  State<FireReportListPage> createState() => _FireReportListPageState();
}

class _FireReportListPageState extends State<FireReportListPage>
    with TickerProviderStateMixin {
  List<FireforestModel>? _cachedReports;
  bool _isLoading = false;

  // ✅ เพิ่ม Animation Controller เหมือน home
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadReports();

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

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await Service().getFireForestByEmail(widget.userEmail);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.backgroundColor, // ✅ เปลี่ยนสีพื้นหลังเหมือน home
      appBar: AppBar(
        backgroundColor:
            AppTheme.primaryColor, // ✅ เปลี่ยนสี AppBar เหมือน home
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ดูสถานะเหตุเกิดแจ้ง',
          style: TextStyle(
            fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          // ✅ เพิ่มปุ่มรีเฟรช
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refreshReports,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _refreshReports,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // ✅ เพิ่ม Welcome Header Card เหมือน home
                _buildWelcomeCard(),

                const SizedBox(height: 24),

                // ✅ แก้ไข Reports Container
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
                                Icons.list_alt_rounded,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'รายงานทั้งหมด',
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

                      // Content
                      SizedBox(height: 500, child: _buildReportsList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ เพิ่ม Welcome Card เหมือน home
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
              Icons.track_changes_rounded,
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
                  'ติดตามสถานะ',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  'การแจ้งเหตุของคุณ',
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
                  'ผู้ใช้งาน: ${widget.userEmail}',
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

  // ✅ แก้ไข Reports List ให้สวยขึ้น
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
                fontFamily: 'Sarabun',
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
              'ไม่มีรายงานการแจ้งเหตุ',
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'เมื่อคุณแจ้งเหตุไฟป่า รายงานจะปรากฏที่นี่',
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 14,
                color: Color(0xFF9E9E9E),
              ),
              textAlign: TextAlign.center,
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
      physics: const BouncingScrollPhysics(),
      itemCount: latestReports.length,
      itemBuilder: (context, index) {
        final report = latestReports[index];
        return _buildReportCard(report, index);
      },
    );
  }

  // ✅ แก้ไข Report Card ให้สวยขึ้น
  Widget _buildReportCard(FireforestModel report, int index) {
    final isProcessing = (report.status ?? '') == 'กำลังดำเนินการ';
    final statusColor = _getStatusColor(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with index
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
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      fontFamily: 'Kanit',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.fireForestLocation ?? 'ไม่ระบุสถานที่',
                    style: const TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
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

            const SizedBox(height: 16),

            // Details
            _buildDetailRow(
              Icons.access_time_rounded,
              'วันเวลาที่แจ้ง',
              Utils.formatDateTime(report.fireForestTime ?? 'ไม่ระบุเวลา'),
            ),

            const SizedBox(height: 20),

            // Action Button
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _navigateToDetail(report),
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
                      'ดูรายละเอียด',
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

  // ✅ เพิ่ม Detail Row Widget
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ เพิ่มฟังก์ชันสีสถานะ
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

  void _navigateToDetail(FireforestModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FireReportDetailPage(report: report),
      ),
    );
  }
}
