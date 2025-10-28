import 'package:fireforest_project/model/join_member_model.dart';
import 'package:fireforest_project/screens/volunteer_fire_forest_detail.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import '../service.dart';
import '../utils.dart';

class VolunteerTaskPage extends StatefulWidget {
  final String userEmail;

  const VolunteerTaskPage({super.key, required this.userEmail});

  @override
  State<VolunteerTaskPage> createState() => _VolunteerTaskPageState();
}

class _VolunteerTaskPageState extends State<VolunteerTaskPage>
    with SingleTickerProviderStateMixin {
  Service service = Service();
  List<JoinMemberModel> pendingTasks = [];
  List<JoinMemberModel> noPendingTasks = [];
  bool isLoading = true;
  late TabController _tabController;

  // ✅ เพิ่มตัวแปรเช็คว่าผู้ใช้มีงาน assigned หรือไม่
  bool hasAssignedTask = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => isLoading = true);
    try {
      // ดึงงาน pending
      pendingTasks = await service.getPendingTasksByVolunteer(widget.userEmail);

      // ดึงงานที่ไม่มี pending จากทุกงาน
      List<JoinMemberModel> noPendingList =
          await service.getAllFireForestDetailsWithNoPending();

      if (noPendingList.isNotEmpty) {
        noPendingTasks = noPendingList;
      } else {
        noPendingTasks = await service.getNoPendingTasksByVolunteer(
          widget.userEmail,
        );
      }

      // เติมข้อมูล FireForest ให้แต่ละงาน
      for (var task in pendingTasks) {
        task.fireForest = await service.getFireForestById(task.fireForestId);
      }
      for (var task in noPendingTasks) {
        task.fireForest = await service.getFireForestById(task.fireForestId);
      }

      // Filter ออกงานที่ openForVolunteer = false/0
      pendingTasks =
          pendingTasks.where((task) {
            return task.fireForest?.detail?.openForVolunteer == true;
          }).toList();

      noPendingTasks =
          noPendingTasks.where((task) {
            return task.fireForest?.detail?.openForVolunteer == true;
          }).toList();

      // ✅ ตรวจสอบสถานะของผู้ใช้สำหรับ Tab "งานใหม่"
      await _checkUserAssignmentStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ ตรวจสอบสถานะของผู้ใช้สำหรับงานใหม่
  Future<void> _checkUserAssignmentStatus() async {
    try {
      // ดึงงาน assigned ของผู้ใช้
      final assignedTasks = await service.getAssignedTasksByVolunteer(
        widget.userEmail,
      );
      final pendingTasksCheck = await service.getPendingTasksByVolunteer(
        widget.userEmail,
      );

      // ✅ ตรวจสอบว่ามีงาน assigned หรือไม่
      hasAssignedTask = assignedTasks.isNotEmpty;

      // สร้าง Set ของ fireForestId ที่ผู้ใช้มีงานแล้ว
      final assignedTaskIds = <int>{};
      final pendingTaskIds = <int>{};

      for (var task in assignedTasks) {
        assignedTaskIds.add(task.fireForestId);
      }
      for (var task in pendingTasksCheck) {
        pendingTaskIds.add(task.fireForestId);
      }

      // อัพเดท workStatus ให้กับงานใน noPendingTasks
      for (var task in noPendingTasks) {
        if (assignedTaskIds.contains(task.fireForestId)) {
          task.workStatus = "assigned"; // ✅ เซตเป็น assigned
        } else if (pendingTaskIds.contains(task.fireForestId)) {
          task.workStatus = "pending"; // เซตเป็น pending
        } else {
          task.workStatus = ""; // ไม่มีงาน
        }
      }
    } catch (e) {
      print("Error checking user assignment status: $e");
    }
  }

  Future<void> _acceptTask(JoinMemberModel task) async {
    // ✅ ถ้ามีงาน assigned แล้วให้แสดงข้อความแทน
    if (hasAssignedTask && task.workStatus != "assigned") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("คุณมีงานแล้ว ไม่สามารถรับงานเพิ่มได้"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // แสดง loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(width: 16),
                  Text("กำลังรับงาน..."),
                ],
              ),
            ),
      );

      // เรียก API เพื่อรับงาน
      await service.acceptAssignedTask(task.fireForestId, widget.userEmail);

      // ปิด loading dialog
      if (mounted) Navigator.pop(context);

      // แสดงข้อความสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("รับงานสำเร็จ!"),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }

      // รีเฟรชข้อมูลทันที
      await _fetchTasks();
    } catch (e) {
      // ปิด loading dialog
      if (mounted) Navigator.pop(context);

      // แสดงข้อความผิดพลาด
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTaskItem(JoinMemberModel task) {
    final String workStatus = task.workStatus;
    final bool isAssigned = workStatus == "assigned";
    final bool isDone = workStatus == "done";
    final bool isPending = workStatus == "pending";

    // ✅ ปิดปุ่มถ้ามีงาน assigned (ไม่ว่าจะเป็นงานนี้หรืองานอื่น)
    final bool canAcceptTask = !hasAssignedTask;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color:
              isAssigned
                  ? Colors.orange.withOpacity(0.5)
                  : hasAssignedTask && !isAssigned
                  ? Colors.red.withOpacity(0.3) // ✅ งานอื่นที่ไม่สามารถรับได้
                  : const Color(0xFFDCEDC8),
          width: isAssigned || (hasAssignedTask && !isAssigned) ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDone
                            ? AppTheme.primaryColor
                            : isAssigned
                            ? const Color(0xFFFF9800)
                            : isPending
                            ? const Color(0xFF9C27B0)
                            : hasAssignedTask
                            ? Colors
                                .red // ✅ งานที่ไม่สามารถรับได้
                            : const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDone
                        ? "เสร็จสิ้น"
                        : isAssigned
                        ? "รับงานแล้ว"
                        : isPending
                        ? "รอยืนยัน"
                        : hasAssignedTask
                        ? "ไม่สามารถรับได้" // ✅ ข้อความใหม่
                        : "พร้อมรับงาน",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  isDone
                      ? Icons.check_circle
                      : isAssigned
                      ? Icons.assignment_turned_in
                      : isPending
                      ? Icons.hourglass_top
                      : hasAssignedTask
                      ? Icons
                          .block // ✅ ไอคอนใหม่
                      : Icons.assignment,
                  color:
                      isDone
                          ? AppTheme.primaryColor
                          : isAssigned
                          ? const Color(0xFFFF9800)
                          : isPending
                          ? const Color(0xFF9C27B0)
                          : hasAssignedTask
                          ? Colors.red
                          : const Color(0xFF2196F3),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Task Info
            Row(
              children: [
                const Icon(Icons.work_rounded, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(
                  "งาน ID: ${task.fireForestId}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color:
                        isAssigned
                            ? Colors.orange
                            : hasAssignedTask && !isAssigned
                            ? Colors.red
                            : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                // Debug info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "($workStatus)",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),

            // ✅ แสดงข้อความเตือนถ้าไม่สามารถรับงานได้
            if (hasAssignedTask && !isAssigned) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "คุณมีงานแล้ว ไม่สามารถรับงานเพิ่มได้",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 4),

            if (task.fireForest != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.fireForest!.fireForestLocation!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    Utils.formatDateTime(task.fireForest!.fireForestTime),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.fireForest!.status ?? 'ไม่ระบุสถานะ',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                // ✅ ปุ่มรับงาน - ปิดถ้ามีงาน assigned
                Expanded(
                  child: ElevatedButton(
                    onPressed: canAcceptTask ? () => _acceptTask(task) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canAcceptTask
                              ? AppTheme.primaryLight
                              : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      elevation: canAcceptTask ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          canAcceptTask
                              ? Icons.volunteer_activism_rounded
                              : isAssigned
                              ? Icons.assignment_turned_in_rounded
                              : Icons.block_rounded, // ✅ ไม่สามารถรับได้
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAssigned
                              ? "รับงานแล้ว"
                              : hasAssignedTask && !isAssigned
                              ? "คุณมีงานแล้ว" // ✅ ข้อความใหม่
                              : "เข้าร่วมช่วยเหลือ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ปุ่มดูรายละเอียด
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => VolunteerFireForestDetailPage(
                                fireForest: task.fireForest!,
                                fireForestDetailId: task.fireForestId,
                              ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_rounded, size: 18),
                        SizedBox(width: 6),
                        Text(
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<JoinMemberModel> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "ไม่มีงานในขณะนี้",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTasks,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return _buildTaskItem(tasks[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          // ✅ แสดงสถานะในหัวข้อ
          hasAssignedTask ? "งานอาสาสมัคร (มีงานแล้ว)" : "งานอาสาสมัคร",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchTasks,
            tooltip: "รีเฟรชข้อมูล",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_turned_in, size: 16),
                  const SizedBox(width: 4),
                  Text("งานของฉัน (${pendingTasks.length})"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text("งานใหม่ (${noPendingTasks.length})"),
                ],
              ),
            ),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList(pendingTasks),
                  _buildTaskList(noPendingTasks),
                ],
              ),
    );
  }
}

