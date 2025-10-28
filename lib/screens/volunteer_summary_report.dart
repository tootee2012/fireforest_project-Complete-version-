import 'package:fireforest_project/model/fire_forest_detail_request.dart';
import 'package:fireforest_project/model/join_member_model.dart';
import 'package:fireforest_project/service.dart';
import 'package:fireforest_project/utils.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';

class SummaryReportPage extends StatefulWidget {
  final String userEmail;
  const SummaryReportPage({super.key, required this.userEmail});

  @override
  State<SummaryReportPage> createState() => _SummaryReportPageState();
}

class _SummaryReportPageState extends State<SummaryReportPage> {
  final Service service = Service();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController assessController = TextEditingController();
  final TextEditingController summaryController = TextEditingController();

  List<JoinMemberModel> assignedTasks = [];
  bool isLoading = true;

  // ตัวอย่างการรวม date และ time string

  @override
  void initState() {
    super.initState();
    _loadAssignedTasks();
  }

  Future<void> _loadAssignedTasks() async {
    try {
      assignedTasks = await service.getAssignedTasksByVolunteer(
        widget.userEmail,
      );
    } catch (e) {
      // handle error
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    assessController.dispose();
    summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text(
          "รายงานไฟป่า",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // แสดงงาน assigned
                      if (assignedTasks.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "งานที่ได้รับมอบหมาย",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...assignedTasks.map(
                                (task) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    "งาน ID: ${task.fireForestId} | สถานะ: ${task.workStatus}",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // สถานที่เกิดเหตุ
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${assignedTasks.isNotEmpty ? assignedTasks[0].location : 'N/A'}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // วันและเวลาที่พบ
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "เวลา: ${Utils.formatDateTime(assignedTasks.isNotEmpty ? (assignedTasks[0].fireForest?.fireForestTime ?? assignedTasks[0].time) : 'N/A')}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ประเมินความเสียหาย
                      TextFormField(
                        controller: assessController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: "ประเมินความเสียหาย",
                          hintText: "กรุณาระบุความเสียหายที่พบ...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? "กรุณาระบุความเสียหาย"
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      // สรุปสถานการณ์
                      TextFormField(
                        controller: summaryController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: "สรุปสถานการณ์",
                          hintText: "กรุณาอธิบายสถานการณ์โดยละเอียด...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? "กรุณาระบุสรุปสถานการณ์"
                                    : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                final detail = FireForestDetail(
                                  fireForestId:
                                      assignedTasks.isNotEmpty
                                          ? assignedTasks[0].fireForestId
                                          : 0,
                                  assessDamage: assessController.text,
                                  summarize: summaryController.text,
                                  // เพิ่ม field อื่น ๆ ตามที่จำเป็น
                                );
                                await service.submitSummaryReport(
                                  detail.fireForestId,
                                  detail,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("ส่งรายงานสำเร็จ!"),
                                  ),
                                );
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
                                );
                              }
                            }
                          },
                          child: const Text(
                            "รายงาน",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
