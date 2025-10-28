import 'package:fireforest_project/model/fireforest_model.dart';
import 'package:fireforest_project/screens/admin_assign_task.dart';
import 'package:fireforest_project/screens/user_fire_report_detail.dart';
import 'package:fireforest_project/screens/volunteer_fire_forest_detail.dart';
import 'package:fireforest_project/service.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import '../utils.dart';

class FireListAdminPage extends StatefulWidget {
  final String agencyEmail;
  const FireListAdminPage({super.key, required this.agencyEmail});

  @override
  State<FireListAdminPage> createState() => _FireListAdminPageState();
}

class _FireListAdminPageState extends State<FireListAdminPage> {
  List<FireforestModel> reports = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await Service().getAllFireForests();
      if (mounted) {
        setState(() {
          // ✅ จัดเรียงให้งานที่สามารถมอบหมายได้ขึ้นด้านบน
          reports = _sortReportsByAssignability(data);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  // ✅ ฟังก์ชันจัดเรียงรายงาน
  List<FireforestModel> _sortReportsByAssignability(
    List<FireforestModel> reports,
  ) {
    return reports..sort((a, b) {
      final aCanAssign = _canAssignTask(a);
      final bCanAssign = _canAssignTask(b);

      // งานที่สามารถมอบหมายได้ขึ้นก่อน
      if (aCanAssign && !bCanAssign) return -1;
      if (!aCanAssign && bCanAssign) return 1;

      // ถ้าสถานะเดียวกัน จัดเรียงตามเวลา (ใหม่สุดก่อน)
      final aTime = DateTime.tryParse(a.fireForestTime ?? '');
      final bTime = DateTime.tryParse(b.fireForestTime ?? '');

      if (aTime != null && bTime != null) {
        return bTime.compareTo(aTime);
      }

      return 0;
    });
  }

  // ✅ ฟังก์ชันตรวจสอบว่าสามารถมอบหมายงานได้หรือไม่
  bool _canAssignTask(FireforestModel report) {
    final fireStatus = report.detail?.fireStatus ?? '';
    final status = report.status ?? '';

    final isProcessing =
        fireStatus == 'กำลังเข้าช่วยเหลือ' || status == 'กำลังดำเนินการ';
    final isDone = fireStatus == 'ดับไฟเสร็จสิ้น' || status == 'ดับไฟเสร็จสิ้น';

    return !(isProcessing || isDone);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ แยกรายงานตามสถานะเพื่อแสดงสถิติ
    final assignableReports = reports.where((r) => _canAssignTask(r)).toList();
    final processingReports = reports.where((r) => !_canAssignTask(r)).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'รายงานไฟป่าสำหรับ Agency',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Header Card พร้อมสถิติ
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
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'จัดการรายงานไฟป่า',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ✅ สถิติรายงาน
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDCEDC8)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${assignableReports.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const Text(
                                'รอมอบหมาย',
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
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${processingReports.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const Text(
                                'ดำเนินการแล้ว',
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
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${reports.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const Text(
                                'ทั้งหมด',
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

            // ✅ Content Section
            if (isLoading)
              Container(
                height: 400,
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
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
            else if (error != null)
              Container(
                width: double.infinity,
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
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "เกิดข้อผิดพลาด: $error",
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (reports.isEmpty)
              Container(
                width: double.infinity,
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
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "ไม่มีรายงานล่าสุด",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // ✅ แสดงงานที่รอมอบหมาย (ถ้ามี)
              if (assignableReports.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.priority_high_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'งานที่รอมอบหมาย (${assignableReports.length} งาน)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ✅ Reports List (เรียงลำดับแล้ว)
              ...reports.map((report) => _buildReportCard(report)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(FireforestModel report) {
    final fireStatus = report.detail?.fireStatus ?? '';
    final status = report.status ?? '';

    final isProcessing =
        fireStatus == 'กำลังเข้าช่วยเหลือ' || status == 'กำลังดำเนินการ';
    final isDone = fireStatus == 'ดับไฟเสร็จสิ้น' || status == 'ดับไฟเสร็จสิ้น';

    // ✅ แก้ไขสีสถานะ - เขียวสำหรับงานเสร็จสิ้น
    final statusColor =
        isDone
            ? Colors
                .green // ✅ เปลี่ยนเป็นสีเขียวสำหรับงานเสร็จสิ้น
            : isProcessing
            ? Colors.orange
            : Colors.blueGrey;

    final bool canAssign = !(isProcessing || isDone);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // ✅ แก้ไข border - เขียวสำหรับงานเสร็จสิ้น, ส้มสำหรับงานที่รอมอบหมาย
        border:
            isDone
                ? Border.all(
                  color: Colors.green,
                  width: 2,
                ) // ✅ กรอบเขียวสำหรับงานเสร็จสิ้น
                : canAssign
                ? Border.all(color: AppTheme.primaryLight, width: 2)
                : null,
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
            // ✅ Header Row พร้อม Priority Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isDone
                            ? Colors
                                .green // ✅ ไอคอนเขียวสำหรับงานเสร็จสิ้น
                            : canAssign
                            ? AppTheme.primaryColor
                            : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDone
                        ? Icons
                            .check_circle_rounded // ✅ ไอคอน check สำหรับงานเสร็จสิ้น
                        : canAssign
                        ? Icons.local_fire_department_rounded
                        : Icons.local_fire_department_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // ✅ Priority Badge
                          if (canAssign) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ด่วน',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // ✅ เพิ่ม Success Badge สำหรับงานเสร็จสิ้น
                          if (isDone) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'เสร็จสิ้น',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              report.fireForestLocation ?? "ไม่ระบุสถานที่",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDone
                                        ? Colors
                                            .green // ✅ ข้อความเขียวสำหรับงานเสร็จสิ้น
                                        : canAssign
                                        ? AppTheme.primaryColor
                                        : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Utils.formatDateTime(report.fireForestTime),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    fireStatus.isNotEmpty ? fireStatus : status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ✅ Info Rows
            if (report.fireForestDetail?.isNotEmpty == true)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // ✅ แก้ไขสีพื้นหลังตามสถานะ
                  color:
                      isDone
                          ? Colors.green.withOpacity(
                            0.1,
                          ) // ✅ พื้นหลังเขียวอ่อนสำหรับงานเสร็จสิ้น
                          : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDone
                            ? Colors
                                .green // ✅ ขอบเขียวสำหรับงานเสร็จสิ้น
                            : const Color(0xFFDCEDC8),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            isDone
                                ? Colors.green.withOpacity(
                                  0.2,
                                ) // ✅ ไอคอนเขียวสำหรับงานเสร็จสิ้น
                                : AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color:
                            isDone
                                ? Colors
                                    .green // ✅ ไอคอนเขียวสำหรับงานเสร็จสิ้น
                                : AppTheme.primaryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.fireForestDetail!,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDone
                                  ? Colors
                                      .green // ✅ ข้อความเขียวสำหรับงานเสร็จสิ้น
                                  : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // ✅ Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToDetail(report),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDone
                              ? Colors
                                  .green
                                  .shade100 // ✅ ปุ่มเขียวอ่อนสำหรับงานเสร็จสิ้น
                              : AppTheme.primaryLight,
                      foregroundColor:
                          isDone
                              ? Colors
                                  .green // ✅ ข้อความเขียวสำหรับงานเสร็จสิ้น
                              : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDone
                              ? Icons.visibility_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "ดูรายละเอียด",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canAssign ? () => _assignTask(report) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDone
                              ? Colors
                                  .green // ✅ ปุ่มเขียวสำหรับงานเสร็จสิ้น
                              : canAssign
                              ? AppTheme.primaryColor
                              : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: canAssign || isDone ? 2 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDone
                              ? Icons
                                  .check_circle_rounded // ✅ ไอคอน check สำหรับงานเสร็จสิ้น
                              : canAssign
                              ? Icons.assignment_turned_in_rounded
                              : Icons.block_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDone
                              ? "เสร็จสิ้นแล้ว" // ✅ ข้อความสำหรับงานเสร็จสิ้น
                              : canAssign
                              ? "มอบหมายงาน"
                              : "ดำเนินการแล้ว",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
    );
  }

  void _navigateToDetail(FireforestModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VolunteerFireForestDetailPage(
              fireForest: report,
              fireForestDetailId: report.fireForestId!,
            ),
      ),
    );
  }

  void _assignTask(FireforestModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AssignTaskPage(report: report, agencyEmail: widget.agencyEmail),
      ),
    );
  }
}
