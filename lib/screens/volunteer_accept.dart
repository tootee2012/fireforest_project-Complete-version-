// lib/screens/volunteer_accept_page.dart
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import '../model/volunteer_model.dart';
import '../service.dart';

class VolunteerAcceptPage extends StatefulWidget {
  final int recruitId; // id ของ recruit (คนที่สมัคร)
  final int fireForestId; // id ของเหตุไฟป่า (งานที่กำลังมอบหมาย)

  const VolunteerAcceptPage({
    super.key,
    required this.recruitId,
    required this.fireForestId,
  });

  @override
  State<VolunteerAcceptPage> createState() => _VolunteerAcceptPageState();
}

class _VolunteerAcceptPageState extends State<VolunteerAcceptPage> {
  final Service _service = Service();
  List<VolunteerModel> _volunteers = [];
  Map<String, bool> _hasActiveJob = {};
  bool _isLoading = true;
  bool _isActionInProgress = false; // เพื่อป้องกันกดซ้ำหลายครั้ง

  @override
  void initState() {
    super.initState();
    _loadVolunteers();
  }

  Future<void> _loadVolunteers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ดึงอาสาที่สมัครมา (Service.getVolunteersByRecruitId ควรรับ recruitId)
      final list = await _service.getVolunteersByRecruitId(widget.recruitId);

      if (!mounted) return;
      _volunteers = list;

      // ตรวจสอบงานค้างสำหรับแต่ละคน (parallel)
      for (var v in _volunteers) {
        try {
          final bool hasActive = await _service.hasActiveJob(v.userEmail);
          _hasActiveJob[v.userEmail] = hasActive;
        } catch (e) {
          // ถ้า check ล้มเหลว assume false และ log
          _hasActiveJob[v.userEmail] = false;
          debugPrint('Error checking active job for ${v.userEmail}: $e');
        }
      }
    } catch (e, st) {
      debugPrint('Error loading volunteers: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดขณะดึงรายชื่ออาสาสมัคร: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptVolunteer(String userEmail) async {
    if (_isActionInProgress) return;

    // ป้องกันกรณีมีงานค้าง
    if (_hasActiveJob[userEmail] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อาสาสมัครคนนี้ยังมีงานค้าง ไม่สามารถรับงานได้'),
        ),
      );
      return;
    }

    setState(() {
      _isActionInProgress = true;
    });

    try {
      // เรียกมอบหมายงาน (assign single volunteer)
      final res = await _service.assignVolunteer(
        userEmail,
        widget.fireForestId,
      );

      // (optionally) อัปเดตสถานะ volunteer ในระบบ backend (ถ้ามี API)
      // ตัวอย่าง: await _service.updateVolunteerStatus(userEmail, "assigned");

      if (!mounted) return;
      // แสดงผลลัพธ์ที่ backend ส่งมา (หรือข้อความสำเร็จ)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));

      // รีโหลดรายการ เพื่อแสดงว่าอาจหายไปจาก list หรือแสดงงานค้าง
      await _loadVolunteers();
    } catch (e) {
      debugPrint('Error assignVolunteer: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการมอบหมาย: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isActionInProgress = false;
      });
    }
  }

  Widget _buildVolunteerTile(VolunteerModel v) {
    final hasActive = _hasActiveJob[v.userEmail] ?? false;
    final bool canAccept = !hasActive && v.volunteerStatus == 'ผ่านการคัดเลือก';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(v.name.isNotEmpty ? v.name : v.userEmail),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('อายุ: ${v.age}'),
            Text('สถานะสมัคร: ${v.volunteerStatus}'),
            if (hasActive)
              const Text(
                'มีงานค้าง',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed:
              canAccept && !_isActionInProgress
                  ? () => _confirmAndAccept(v.userEmail)
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canAccept ? AppTheme.success : Colors.grey,
          ),
          child: const Text('รับงาน'),
        ),
        isThreeLine: true,
      ),
    );
  }

  void _confirmAndAccept(String userEmail) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('ยืนยันการรับงาน'),
            content: Text('คุณต้องการมอบหมายงานให้ $userEmail ใช่หรือไม่ ?'),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) Navigator.of(ctx).pop();
                },
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () {
                  if (mounted) Navigator.of(ctx).pop();
                  _acceptVolunteer(userEmail);
                },
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตรวจสอบอาสาสมัคร'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadVolunteers,
                child:
                    _volunteers.isEmpty
                        ? ListView(
                          // เพื่อให้ RefreshIndicator ทำงานเมื่อหน้าว่าง
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('ยังไม่มีอาสาสมัครที่สมัคร')),
                          ],
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _volunteers.length,
                          itemBuilder: (context, index) {
                            final v = _volunteers[index];
                            return _buildVolunteerTile(v);
                          },
                        ),
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: _isActionInProgress ? null : _loadVolunteers,
          icon: const Icon(Icons.refresh),
          label: const Text('รีเฟรช'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
