import 'package:fireforest_project/model/agency_model.dart';
import 'package:fireforest_project/model/assign_dto.dart';
import 'package:fireforest_project/model/fire_forest_detail_request.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../model/fireforest_model.dart';
import '../model/volunteer_model.dart';
import '../model/firepicture_model.dart';
import '../service.dart';
import '../screens/admin_home.dart';

class AssignTaskPage extends StatefulWidget {
  final FireforestModel report;
  final String agencyEmail;

  const AssignTaskPage({
    Key? key,
    required this.report,
    required this.agencyEmail,
  }) : super(key: key);

  @override
  _AssignTaskPageState createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage>
    with TickerProviderStateMixin {
  int volunteerCount = 5;
  bool selectAlertMode = true;
  List<VolunteerModel> volunteers = [];
  Set<String> selectedVolunteers = {};
  bool isLoading = true;
  bool isSubmitting = false;
  GoogleMapController? mapController;
  final Service service = Service();
  List<FirePictureModel>? _cachedPictures;

  // ✅ Animation Controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Animation Setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fetchVolunteers();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchVolunteers() async {
    setState(() => isLoading = true);
    try {
      final data = await service.getAllVolunteers();
      volunteers =
          data.where((v) => v.volunteerStatus == "ผ่านการคัดเลือก").toList();

      // ✅ เรียงตาม experience level (สูงไปต่ำ)
      volunteers.sort((a, b) {
        final aExp = a.experience?.experienceId ?? 1;
        final bExp = b.experience?.experienceId ?? 1;
        return bExp.compareTo(aExp);
      });

      for (var volunteer in volunteers) {
        try {
          final pendingTasks = await service.getPendingTasksByVolunteer(
            volunteer.userEmail,
          );
          if (pendingTasks.isNotEmpty) {
            volunteer.joinMember = pendingTasks.first;
          }

          final assignedTasks = await service.getAssignedTasksByVolunteer(
            volunteer.userEmail,
          );
          if (assignedTasks.isNotEmpty && volunteer.joinMember == null) {
            volunteer.joinMember = assignedTasks.first;
          }
        } catch (e) {
          // Skip individual errors
        }
      }

      // ✅ เรียงให้อาสาสมัครที่ว่างขึ้นมาด้านบน
      volunteers.sort((a, b) {
        // ตรวจสอบสถานะการว่าง
        bool aIsAvailable = _isVolunteerAvailable(a);
        bool bIsAvailable = _isVolunteerAvailable(b);

        if (aIsAvailable && !bIsAvailable) {
          return -1; // a ขึ้นก่อน (ว่าง)
        } else if (!aIsAvailable && bIsAvailable) {
          return 1; // b ขึ้นก่อน (ว่าง)
        } else {
          // ถ้าสถานะเท่ากัน เรียงตาม experience
          final aExp = a.experience?.experienceId ?? 1;
          final bExp = b.experience?.experienceId ?? 1;
          return bExp.compareTo(aExp); // เรียงจากมากไปน้อย
        }
      });

      setState(() {});
    } catch (e) {
      debugPrint("Error fetching volunteers: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ เพิ่มฟังก์ชันตรวจสอบว่าอาสาสมัครว่างหรือไม่
  bool _isVolunteerAvailable(VolunteerModel volunteer) {
    if (volunteer.joinMember == null) return true;

    final status = volunteer.joinMember!.workStatus;
    return !(status == "assigned" || status == "pending");
  }

  // ✅ Helper Functions สำหรับ Experience
  String _getExperienceText(VolunteerModel volunteer) {
    return volunteer.experience?.experienceType ?? 'เริ่มต้น';
  }

  Color _getExperienceColor(VolunteerModel volunteer) {
    final experienceId = volunteer.experience?.experienceId ?? 1;
    switch (experienceId) {
      case 3:
        return AppTheme.primaryColor; // เขียวเข้ม - มีประสบการณ์สูง
      case 2:
        return AppTheme.primaryColor; // เขียว - มีประสบการณ์
      case 1:
      default:
        return const Color(0xFF9C27B0); // ม่วง - เริ่มต้น
    }
  }

  IconData _getExperienceIcon(VolunteerModel volunteer) {
    final experienceId = volunteer.experience?.experienceId ?? 1;
    switch (experienceId) {
      case 3:
        return Icons.workspace_premium_rounded; // ไอคอนเหรียญทอง
      case 2:
        return Icons.military_tech_rounded; // ไอคอนเหรียญ
      case 1:
      default:
        return Icons.emoji_events_outlined; // ไอคอนถ้วยรางวัล
    }
  }

  Future<void> _submitTask() async {
    print('🔥 _submitTask started');

    if (isSubmitting) {
      print('⏸️ Already submitting, returning');
      return;
    }

    setState(() => isSubmitting = true);
    print('✅ Set isSubmitting = true');

    try {
      print('🎯 selectAlertMode: $selectAlertMode');

      if (selectAlertMode) {
        print('🚨 Entering Alert Mode');

        // Alert Mode - ประกาศงาน
        FireForestDetail detail = FireForestDetail(
          fireForestId: widget.report.fireForestId!,
          fireStatus: "กำลังเข้าช่วยเหลือ",
          assessDamage: "",
          summarize: "",
          requiredVolunteers: volunteerCount,
          openForVolunteer: true,
          fireForest: null,
          agency: AgencyModel(agencyEmail: widget.agencyEmail, agencyName: ""),
        );

        print('🏗️ Creating FireForestDetail...');
        print('📊 Detail data: ${detail.toJson()}');

        try {
          final result = await service.createFireForestDetail(detail);
          print('✅ FireForestDetail created: ${result.fireForestId}');

          // ส่งแจ้งเตือนให้อาสาสมัครทุกคน
          final notificationData = {
            'fireForestId': widget.report.fireForestId?.toString() ?? '0',
            'location': widget.report.fireForestLocation ?? '',
            'requiredVolunteers': volunteerCount.toString(),
            'detailId': result.fireForestId?.toString() ?? '0',
            'type': 'fire_alert',
            'action': 'volunteer_needed',
          };

          bool notificationSent = await service.sendNotificationToAllVolunteers(
            title: '🚨 งานอาสาสมัครใหม่',
            message:
                'เกิดไฟป่าที่ ${widget.report.fireForestLocation ?? 'ไม่ระบุสถานที่'} ต้องการอาสาสมัคร $volunteerCount คน',
            data: notificationData,
          );

          String message =
              notificationSent
                  ? '✅ ประกาศงานสำเร็จ! ส่งแจ้งเตือนให้อาสาสมัครแล้ว'
                  : '⚠️ ประกาศงานสำเร็จ แต่อาจส่งแจ้งเตือนไม่สำเร็จ';

          _showSnackBar(
            message,
            notificationSent ? AppTheme.success : Colors.orange,
          );
        } catch (createError) {
          print('❌ Error creating FireForestDetail: $createError');
          throw Exception('ไม่สามารถสร้างรายละเอียดงานได้: $createError');
        }
      } else {
        print('🎯 Entering Apply Mode');

        // Apply Mode - เลือกบุคคล
        if (selectedVolunteers.isEmpty) {
          print('❌ No volunteers selected');
          _showSnackBar('❌ กรุณาเลือกอาสาสมัครอย่างน้อย 1 คน', Colors.red);
          return;
        }

        print('👥 Selected volunteers: $selectedVolunteers');

        try {
          // Step 1: สร้าง FireForestDetail
          print('🏗️ Creating FireForestDetail for Apply Mode...');
          FireForestDetail detail = FireForestDetail(
            fireForestId: widget.report.fireForestId!,
            fireStatus: "กำลังเข้าช่วยเหลือ",
            assessDamage: "",
            summarize: "",
            requiredVolunteers: selectedVolunteers.length,
            openForVolunteer: true,
            fireForest: null,
            agency: AgencyModel(
              agencyEmail: widget.agencyEmail,
              agencyName: "",
            ),
          );

          final result = await service.createFireForestDetail(detail);
          print(
            '✅ FireForestDetail created for Apply Mode: ${result.fireForestId}',
          );

          // Step 2: มอบหมายงานให้อาสาสมัครที่เลือก
          final assignDTO = AssignDTO(
            fireForestId: widget.report.fireForestId!,
            userEmails: selectedVolunteers.toList(),
          );

          print('📝 Assigning multiple volunteers...');
          await service.assignMultipleVolunteers(assignDTO);
          print('✅ Assignment completed');

          // Step 3: ส่งแจ้งเตือนให้อาสาสมัครที่เลือก
          print('📤 Calling service.sendNotificationToSelectedVolunteers...');

          final selectedNotificationData = {
            'fireForestId': widget.report.fireForestId?.toString() ?? '0',
            'location': widget.report.fireForestLocation ?? '',
            'type': 'task_assignment',
            'action': 'task_assigned',
            'assignedBy': widget.agencyEmail,
            'assignedAt': DateTime.now().toIso8601String(),
          };

          bool
          notificationSent = await service.sendNotificationToSelectedVolunteers(
            volunteerEmails: selectedVolunteers.toList(),
            title: '🎯 คุณได้รับมอบหมายงานใหม่!',
            message:
                'คุณได้รับมอบหมายให้ช่วยเหลือเหตุไฟป่าที่ ${widget.report.fireForestLocation ?? 'ไม่ระบุสถานที่'}',
            data: selectedNotificationData,
          );

          print('📬 Selected Notification Result: $notificationSent');

          String message =
              notificationSent
                  ? '✅ มอบหมายงานสำเร็จ! ส่งแจ้งเตือนให้อาสาสมัคร ${selectedVolunteers.length} คนแล้ว'
                  : '⚠️ มอบหมายงานสำเร็จ แต่อาจส่งแจ้งเตือนไม่สำเร็จ';

          print('💬 Final message: $message');
          _showSnackBar(
            message,
            notificationSent ? AppTheme.success : Colors.orange,
          );
        } catch (assignError) {
          print('❌ Error in Apply Mode: $assignError');
          throw Exception('ไม่สามารถมอบหมายงานได้: $assignError');
        }
      }

      // Navigation - กลับไปหน้า AdminHome
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        print('🏃 Navigating back to AdminHome...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Adminhome(agencyEmail: widget.agencyEmail),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('💥 Error in _submitTask: $e');
      print('📚 Stack trace: $stackTrace');

      String errorMessage = 'เกิดข้อผิดพลาด';

      if (e.toString().contains('FormatException')) {
        errorMessage = 'เกิดข้อผิดพลาดในการประมวลผลข้อมูล กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('timeout')) {
        errorMessage =
            'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
      } else if (e.toString().contains('HTTP')) {
        errorMessage = 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง';
      } else {
        errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      }

      _showSnackBar('❌ $errorMessage', Colors.red);
    } finally {
      if (mounted) {
        print('🏁 Setting isSubmitting = false');
        setState(() => isSubmitting = false);
      }
    }

    print('🔥 _submitTask finished');
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    print('📢 Showing SnackBar: $message');

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                color == AppTheme.success
                    ? Icons.check_circle_rounded
                    : color == Colors.orange
                    ? Icons.warning_rounded
                    : Icons.error_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Sarabun',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'ปิด',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return "-";
    try {
      final dt = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dateTimeStr;
    }
  }

  Widget _buildCard(String title, IconData icon, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Kanit',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildFireInfoCard() {
    return _buildCard(
      'ข้อมูลเหตุไฟป่า',
      Icons.local_fire_department,
      Column(
        children: [
          _buildInfoRow(
            'สถานที่',
            widget.report.fireForestLocation ?? 'ไม่ระบุ',
          ),
          _buildInfoRow(
            'วันเวลา',
            _formatDateTime(widget.report.fireForestTime),
          ),
          if (widget.report.fireForestDetail?.isNotEmpty == true)
            _buildInfoRow('รายละเอียด', widget.report.fireForestDetail!),
          _buildInfoRow('สถานะ', widget.report.status ?? 'ไม่ระบุ'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontFamily: 'Kanit',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 14,
                color: Color(0xFF616161),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicturesCard() {
    return _buildCard(
      'รูปภาพไฟป่า',
      Icons.photo_library,
      _cachedPictures != null
          ? _buildPicturesList(_cachedPictures!)
          : FutureBuilder<List<FirePictureModel>>(
            future: service.getFirePictures(widget.report.fireForestId ?? 0),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                );
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.grey,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ไม่มีรูปภาพ',
                          style: TextStyle(
                            fontFamily: 'Sarabun',
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _cachedPictures = snapshot.data;
              });

              return _buildPicturesList(snapshot.data!);
            },
          ),
    );
  }

  Widget _buildPicturesList(List<FirePictureModel> pictures) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pictures.length,
        itemBuilder:
            (context, index) => _buildImageCard(pictures[index], index),
      ),
    );
  }

  Widget _buildImageCard(FirePictureModel pic, int index) {
    final String? url = pic.fullUrl;
    if (url == null) {
      return Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    return GestureDetector(
      onTap: () => _showFullImage(url),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            errorWidget:
                (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder:
                    (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                errorWidget:
                    (context, url, error) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
              ),
            ),
          ),
    );
  }

  Widget _buildMapCard() {
    final lat = widget.report.fireForestLat ?? 0.0;
    final lng = widget.report.fireForestLong ?? 0.0;

    return _buildCard(
      'ตำแหน่งบนแผนที่',
      Icons.map,
      Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child:
            lat != 0 && lng != 0
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat, lng),
                      zoom: 13,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('fire'),
                        position: LatLng(lat, lng),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    },
                    onMapCreated: (controller) => mapController = controller,
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                )
                : Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_rounded,
                          color: Colors.grey,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ไม่พบตำแหน่งพิกัด',
                          style: TextStyle(
                            fontFamily: 'Sarabun',
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildAssignmentCard() {
    return _buildCard(
      'เลือกวิธีมอบหมายงาน',
      Icons.assignment,
      Column(
        children: [
          // Alert Mode
          Container(
            decoration: BoxDecoration(
              color:
                  selectAlertMode
                      ? AppTheme.surfaceColor
                      : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    selectAlertMode
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                width: selectAlertMode ? 2 : 1,
              ),
            ),
            child: RadioListTile<bool>(
              value: true,
              groupValue: selectAlertMode,
              onChanged: (val) => setState(() => selectAlertMode = val!),
              title: const Row(
                children: [
                  Text('🚨', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'ประกาศงาน (Alert)',
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'ระบุจำนวนอาสาสมัคร ส่งแจ้งเตือนให้ทุกคน อาสาสมัครสมัครเข้ามาเอง',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 13,
                    color: Color(0xFF616161),
                  ),
                ),
              ),
              activeColor: AppTheme.primaryColor,
            ),
          ),

          if (selectAlertMode) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.surfaceColor,
                    AppTheme.surfaceColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'จำนวนอาสาสมัครที่ต้องการ:',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              volunteerCount > 1
                                  ? AppTheme.primaryColor
                                  : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: (volunteerCount > 1
                                      ? AppTheme.primaryColor
                                      : Colors.grey)
                                  .withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed:
                              volunteerCount > 1
                                  ? () => setState(() => volunteerCount--)
                                  : null,
                          icon: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$volunteerCount คน',
                          style: const TextStyle(
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => setState(() => volunteerCount++),
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Apply Mode
          Container(
            decoration: BoxDecoration(
              color:
                  !selectAlertMode
                      ? AppTheme.surfaceColor
                      : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    !selectAlertMode
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                width: !selectAlertMode ? 2 : 1,
              ),
            ),
            child: RadioListTile<bool>(
              value: false,
              groupValue: selectAlertMode,
              onChanged: (val) => setState(() => selectAlertMode = val!),
              title: const Row(
                children: [
                  Text('🎯', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'เลือกบุคคล (Apply)',
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'เลือกอาสาสมัครเฉพาะบุคคล ส่งแจ้งเตือนให้เฉพาะคนที่เลือก มอบหมายงานโดยตรง',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 13,
                    color: Color(0xFF616161),
                  ),
                ),
              ),
              activeColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteersCard() {
    if (selectAlertMode) return const SizedBox.shrink();

    return _buildCard(
      'รายชื่ออาสาสมัคร (${selectedVolunteers.length}/${volunteers.length})',
      Icons.group,
      Column(
        children: [
          if (volunteers.isNotEmpty) ...[
            // Experience Legend
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ระดับประสบการณ์:',
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildExperienceLegend(
                        Icons.workspace_premium_rounded,
                        'มีประสบการณ์สูง',
                        AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      _buildExperienceLegend(
                        Icons.military_tech_rounded,
                        'มีประสบการณ์',
                        AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      _buildExperienceLegend(
                        Icons.emoji_events_outlined,
                        'เริ่มต้น',
                        const Color(0xFF9C27B0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // รายการอาสาสมัคร
            ...volunteers.map(_buildVolunteerCard).toList(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ไม่มีอาสาสมัครที่ผ่านการคัดเลือก',
                      style: TextStyle(
                        fontFamily: 'Sarabun',
                        color: Colors.grey,
                        fontSize: 14,
                      ),
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

  Widget _buildExperienceLegend(IconData icon, String text, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerCard(VolunteerModel volunteer) {
    String workStatusText = "ว่าง";
    Color statusColor = AppTheme.primaryColor;
    bool isAvailable = true;

    if (volunteer.joinMember != null) {
      final status = volunteer.joinMember!.workStatus;
      if (status == "assigned") {
        workStatusText = "อยู่ระหว่างการช่วยเหลือไฟป่า";
        statusColor = const Color(0xFF2196F3);
        isAvailable = false;
      } else if (status == "pending") {
        workStatusText = "ถูกมอบหมายงานแล้ว";
        statusColor = const Color(0xFFFF9800);
        isAvailable = false;
      }
    }

    final isSelected = selectedVolunteers.contains(volunteer.userEmail);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.surfaceColor : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : const Color(0xFFE0E0E0),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Checkbox
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isAvailable ? Colors.transparent : Colors.grey.shade200,
              ),
              child: Checkbox(
                value: isSelected,
                onChanged:
                    isAvailable
                        ? (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedVolunteers.add(volunteer.userEmail);
                            } else {
                              selectedVolunteers.remove(volunteer.userEmail);
                            }
                          });
                        }
                        : null,
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name และ Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          volunteer.name,
                          style: TextStyle(
                            fontFamily: 'Kanit',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isAvailable
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          workStatusText,
                          style: TextStyle(
                            fontFamily: 'Sarabun',
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ข้อมูลพื้นฐาน
                  Row(
                    children: [
                      Icon(
                        Icons.cake_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'อายุ ${volunteer.age} ปี',
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 13,
                          color: isAvailable ? Colors.grey[600] : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.work_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          volunteer.talent ?? 'ไม่ระบุ',
                          style: TextStyle(
                            fontFamily: 'Sarabun',
                            fontSize: 13,
                            color: isAvailable ? Colors.grey[600] : Colors.grey,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Experience Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getExperienceColor(
                            volunteer,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getExperienceColor(
                              volunteer,
                            ).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getExperienceIcon(volunteer),
                              size: 14,
                              color: _getExperienceColor(volunteer),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getExperienceText(volunteer),
                              style: TextStyle(
                                fontFamily: 'Sarabun',
                                fontSize: 12,
                                color: _getExperienceColor(volunteer),
                                fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "มอบหมายงานอาสาสมัคร",
          style: TextStyle(
            fontFamily: 'Kanit',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => Adminhome(agencyEmail: widget.agencyEmail),
                ),
              ),
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'กำลังโหลดข้อมูลอาสาสมัคร...',
                      style: TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 16,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              )
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildFireInfoCard(),
                            _buildPicturesCard(),
                            _buildMapCard(),
                            _buildAssignmentCard(),
                            _buildVolunteersCard(),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isSubmitting
                                      ? [
                                        Colors.grey.shade400,
                                        Colors.grey.shade500,
                                      ]
                                      : [
                                        AppTheme.primaryColor,
                                        AppTheme.primaryLight,
                                      ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (!isSubmitting)
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : _submitTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child:
                                isSubmitting
                                    ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          "กำลังดำเนินการ...",
                                          style: TextStyle(
                                            fontFamily: 'Kanit',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          selectAlertMode
                                              ? Icons.campaign_rounded
                                              : Icons
                                                  .assignment_turned_in_rounded,
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          selectAlertMode
                                              ? "ประกาศงาน ($volunteerCount คน)"
                                              : "มอบหมายงาน (${selectedVolunteers.length} คน)",
                                          style: const TextStyle(
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
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
