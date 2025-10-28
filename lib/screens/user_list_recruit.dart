import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import '../model/recruit_model.dart';
import '../screens/user_apply_form.dart';
import '../service.dart';

class Listrecruit extends StatefulWidget {
  final String userEmail;
  const Listrecruit({super.key, required this.userEmail});

  @override
  State<Listrecruit> createState() => _ListrecruitState();
}

class _ListrecruitState extends State<Listrecruit>
    with TickerProviderStateMixin {
  Service service = Service();
  String volunteerStatus = ""; // สถานะอาสาสมัคร
  bool _isLoading = true;

  // ✅ เพิ่ม key สำหรับ FutureBuilder
  Key _futureBuilderKey = UniqueKey();

  // ✅ เพิ่ม Animation Controller เหมือน home
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadVolunteerStatus();

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

  // โหลดสถานะอาสาสมัครจาก backend
  void _loadVolunteerStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await service.getVolunteerStatus(widget.userEmail);
      if (mounted) {
        setState(() {
          volunteerStatus = status;
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

  // ✅ แก้ไข รีเฟรชข้อมูล
  Future<void> _refreshData() async {
    _loadVolunteerStatus();

    // ✅ แยก setState ออกมาเป็นคำสั่งแยก
    if (mounted) {
      setState(() {
        _futureBuilderKey =
            UniqueKey(); // สร้าง key ใหม่เพื่อบังคับให้ FutureBuilder รีเฟรช
      });
    }
  }

  // ฟังก์ชันจัดรูปแบบวันที่
  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')} น.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, // ✅ เปลี่ยนเป็นสีส้ม
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor, // ✅ เปลี่ยนเป็นสีส้ม
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สมัครอาสาสมัคร',
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
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // ✅ เพิ่ม Welcome Header Card เหมือน home
                _buildWelcomeCard(),

                const SizedBox(height: 24),

                // ✅ แก้ไข Recruit List
                _buildRecruitList(),
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
              Icons.people_alt_rounded,
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
                  'เข้าร่วมเป็น',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  'อาสาสมัครดับไฟป่า',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(volunteerStatus),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        volunteerStatus.isEmpty
                            ? 'กำลังโหลด...'
                            : volunteerStatus,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ แก้ไข Recruit List พร้อม key
  Widget _buildRecruitList() {
    return FutureBuilder<List<RecruitModel>>(
      key: _futureBuilderKey, // ✅ เพิ่ม key
      future: service.getVisibleRecruit(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
          return Container(
            height: 400,
            child: const Center(
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
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // ✅ เพิ่มปุ่ม retry
                  ElevatedButton(
                    onPressed: _refreshData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ลองใหม่',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                    'ไม่มีการรับสมัครอาสาสมัคร',
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'กรุณากลับมาดูใหม่ในภายหลัง',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          final data = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return _buildRecruitCard(item, index);
            },
          );
        }
      },
    );
  }

  // ✅ แก้ไข Recruit Card ให้สวยขึ้น
  Widget _buildRecruitCard(RecruitModel item, int index) {
    // ปุ่มสมัครจะ disabled หรือซ่อนถ้าสถานะเป็นรอการตรวจสอบหรือผ่านการคัดเลือก
    bool canApply =
        !(volunteerStatus == "รอการตรวจสอบ" ||
            volunteerStatus == "ผ่านการคัดเลือก");

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
                    'การรับสมัครอาสาสมัคร',
                    style: const TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // พื้นที่และคำอธิบาย
            _buildInfoRow(
              Icons.location_on_rounded,
              'พื้นที่',
              item.recruitLocation,
            ),

            const SizedBox(height: 12),

            _buildInfoRow(
              Icons.description_rounded,
              'รายละเอียด',
              item.description,
            ),

            const SizedBox(height: 16),

            // วันที่เริ่ม/สิ้นสุดสมัคร
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ระยะเวลาสมัคร',
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 30),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "เริ่ม: ${formatDate(item.startDate)}",
                              style: TextStyle(
                                fontFamily: 'Sarabun',
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "สิ้นสุด: ${formatDate(item.endDate)}",
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
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // จำนวนผู้สมัคร
            _buildInfoRow(
              Icons.people_rounded,
              'จำนวนที่รับ',
              '${item.max} คน',
            ),

            const SizedBox(height: 20),

            // ปุ่มสมัคร
            canApply
                ? Container(
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ApplyForm(
                                userEmail: widget.userEmail,
                                recruitId: item.id,
                              ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.how_to_reg_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'สมัครอาสาสมัคร',
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
                )
                : Tooltip(
                  message:
                      "คุณไม่สามารถสมัครได้ เนื่องจากสถานะอาสาสมัครของคุณคือ \"$volunteerStatus\"",
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.block_rounded,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ไม่สามารถสมัครได้',
                            style: TextStyle(
                              fontFamily: 'Kanit',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // ✅ เพิ่ม Helper Widget สำหรับ Info Row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
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
                const SizedBox(height: 4),
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
      ),
    );
  }

  // ✅ เพิ่มฟังก์ชันสีสถานะ
  Color _getStatusColor(String status) {
    switch (status) {
      case 'ผ่านการคัดเลือก':
        return AppTheme.primaryColor;
      case 'รอการตรวจสอบ':
        return const Color(0xFFFF9800);
      case 'ไม่ผ่านการคัดเลือก':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
