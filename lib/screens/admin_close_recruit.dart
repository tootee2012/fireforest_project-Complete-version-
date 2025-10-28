import 'package:fireforest_project/model/recruit_model.dart';
import 'package:fireforest_project/model/volunteer_model.dart';
import 'package:fireforest_project/service.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';

class CloseRecruit extends StatefulWidget {
  const CloseRecruit({super.key});

  @override
  State<CloseRecruit> createState() => _CloseRecruitState();
}

class _CloseRecruitState extends State<CloseRecruit> {
  Service service = Service();
  Map<int, bool> visibility = {};
  Map<int, int> applicantCounts = {};
  bool isLoading = true;
  Set<int> updatingItems = {}; // ✅ เก็บ ID ของรายการที่กำลังอัปเดต

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')} น.";
  }

  Future<int> _getApplicantCount(int recruitId) async {
    try {
      final volunteers = await service.getVolunteersByRecruitId(recruitId);
      return volunteers.length;
    } catch (e) {
      print("Error getting applicant count for recruit $recruitId: $e");
      return 0;
    }
  }

  Future<void> _loadData() async {
    try {
      final data = await service.getAllRecruit();

      // โหลดสถานะ visibility
      for (var item in data) {
        visibility[item.id] = item.isVisible ?? true;
      }

      // โหลดจำนวนผู้สมัครสำหรับแต่ละ recruit
      for (var item in data) {
        final count = await _getApplicantCount(item.id);
        applicantCounts[item.id] = count;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // ✅ เปลี่ยนจาก _saveAllChanges เป็น _updateSingleItem
  Future<void> _updateSingleItem(int recruitId, bool newVisibility) async {
    setState(() {
      updatingItems.add(recruitId);
    });

    try {
      bool success = await service.updateRecruitVisibility(
        recruitId,
        newVisibility,
      );

      if (success) {
        setState(() {
          visibility[recruitId] = newVisibility;
        });

        // ✅ แสดง Snackbar สำเร็จ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      newVisibility
                          ? "แสดงประกาศเรียบร้อยแล้ว"
                          : "ซ่อนประกาศเรียบร้อยแล้ว",
                      style: const TextStyle(
                        fontFamily: 'Sarabun',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // ✅ กรณีอัปเดตไม่สำเร็จ - คืนค่าเดิม
        setState(() {
          visibility[recruitId] = !newVisibility;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "ไม่สามารถอัปเดตได้ กรุณาลองใหม่",
                      style: const TextStyle(
                        fontFamily: 'Sarabun',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print("Error updating recruit visibility: $e");

      // ✅ กรณีเกิด exception - คืนค่าเดิม
      setState(() {
        visibility[recruitId] = !newVisibility;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "เกิดข้อผิดพลาด: $e",
                    style: const TextStyle(
                      fontFamily: 'Sarabun',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        updatingItems.remove(recruitId);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "จัดการการมองเห็นประกาศ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // ✅ ลบปุ่ม save ออก เพราะไม่ต้องใช้แล้ว
        actions: [
          // ✅ เพิ่มปุ่ม refresh แทน
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadData();
            },
            tooltip: "รีเฟรชข้อมูล",
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : FutureBuilder<List<RecruitModel>>(
                future: service.getAllRecruit(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "เกิดข้อผิดพลาด: ${snapshot.error}",
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "ไม่พบข้อมูลประกาศรับสมัคร",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final data = snapshot.data!;

                    // แยกข้อมูลตามสถานะการแสดง
                    final visibleRecruits =
                        data
                            .where((item) => visibility[item.id] ?? true)
                            .toList();
                    final hiddenRecruits =
                        data
                            .where((item) => !(visibility[item.id] ?? true))
                            .toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Header Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 24),
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
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.visibility_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'จัดการประกาศรับสมัคร',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'เปลี่ยนสถานะแล้วบันทึกอัตโนมัติ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // ✅ เพิ่มไอคอน auto-save
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.auto_mode_rounded,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // สรุปสถิติ
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFDCEDC8),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              '${data.length}',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                            const Text(
                                              'ประกาศทั้งหมด',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              '${applicantCounts.values.fold(0, (sum, count) => sum + count)}',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            const Text(
                                              'ผู้สมัครทั้งหมด',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ประกาศที่แสดง (ด้านบน)
                          if (visibleRecruits.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    Color(0xFF66BB6A),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.3,
                                    ),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.visibility_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'ประกาศที่แสดง (${visibleRecruits.length} รายการ)',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${visibleRecruits.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...visibleRecruits
                                .map((item) => _buildRecruitCard(item))
                                .toList(),
                          ],

                          // ประกาศที่ซ่อน (ด้านล่าง)
                          if (hiddenRecruits.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF44336),
                                    Color(0xFFE57373),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF44336,
                                    ).withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.visibility_off_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'ประกาศที่ซ่อน (${hiddenRecruits.length} รายการ)',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${hiddenRecruits.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...hiddenRecruits
                                .map((item) => _buildRecruitCard(item))
                                .toList(),
                          ],

                          // ข้อความเมื่อไม่มีข้อมูล
                          if (visibleRecruits.isEmpty && hiddenRecruits.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'ไม่พบประกาศรับสมัคร',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ยังไม่มีประกาศรับสมัครในระบบ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                },
              ),
    );
  }

  Widget _buildRecruitCard(RecruitModel item) {
    final isVisible = visibility[item.id] ?? true;
    final applicantCount = applicantCounts[item.id] ?? 0;
    final isFullyBooked = applicantCount >= item.max;
    final fillPercentage = item.max > 0 ? (applicantCount / item.max) : 0.0;
    final isUpdating = updatingItems.contains(
      item.id,
    ); // ✅ เช็คว่ากำลังอัปเดตหรือไม่

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            isVisible
                ? Border.all(color: AppTheme.primaryLight, width: 2)
                : Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isVisible ? AppTheme.primaryColor : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
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
                        item.recruitLocation,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isVisible
                                  ? AppTheme.primaryColor
                                  : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    // ✅ แก้ไข Switch เพื่อแสดง loading และ save ทันที
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Switch(
                          value: isVisible,
                          activeColor: AppTheme.primaryColor,
                          inactiveThumbColor: Colors.red,
                          inactiveTrackColor: Colors.red.withOpacity(0.4),
                          onChanged:
                              isUpdating
                                  ? null // ✅ ปิดการใช้งานขณะอัปเดต
                                  : (value) {
                                    // ✅ เปลี่ยนสถานะในหน้าจอทันที
                                    setState(() {
                                      visibility[item.id] = value;
                                    });

                                    // ✅ เรียก API เพื่ออัปเดต
                                    _updateSingleItem(item.id, value);
                                  },
                        ),

                        // ✅ แสดง loading indicator ขณะอัปเดต
                        if (isUpdating)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // ✅ แสดงสถานะ
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isVisible ? "แสดง" : "ซ่อน",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color:
                                isVisible ? AppTheme.primaryColor : Colors.red,
                          ),
                        ),

                        // ✅ แสดงไอคอน auto-save
                        if (isUpdating) ...[
                          const SizedBox(width: 4),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // วันที่
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCEDC8), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "เริ่มสมัคร: ${formatDate(item.startDate)}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          "สิ้นสุด: ${formatDate(item.endDate)}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // สถิติผู้สมัคร
            Row(
              children: [
                // จำนวนผู้สมัคร
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isFullyBooked
                              ? Colors.red.withOpacity(0.1)
                              : AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isFullyBooked ? Colors.red : AppTheme.primaryColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_rounded,
                          color:
                              isFullyBooked
                                  ? Colors.red
                                  : AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              '$applicantCount',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    isFullyBooked
                                        ? Colors.red
                                        : AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              'ผู้สมัคร',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isFullyBooked
                                        ? Colors.red
                                        : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // จำนวนที่รับ
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.group_add_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              '${item.max}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const Text(
                              'รับสมัคร',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // เปอร์เซ็นต์
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.analytics_rounded,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              '${(fillPercentage * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              'เต็ม',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Progress Bar
            const SizedBox(height: 12),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fillPercentage.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isFullyBooked
                            ? Colors.red
                            : fillPercentage > 0.8
                            ? Colors.orange
                            : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Status Text
            if (isFullyBooked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'เต็มแล้ว',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
