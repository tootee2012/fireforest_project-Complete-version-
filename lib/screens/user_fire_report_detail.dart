import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/fireforest_model.dart';
import '../model/firepicture_model.dart';
import '../service.dart';
import '../utils.dart';

class FireReportDetailPage extends StatefulWidget {
  final FireforestModel report;
  const FireReportDetailPage({super.key, required this.report});

  @override
  State<FireReportDetailPage> createState() => _FireReportDetailPageState();
}

class _FireReportDetailPageState extends State<FireReportDetailPage>
    with TickerProviderStateMixin {
  Service service = Service();
  List<FirePictureModel>? _cachedPictures;

  // ✅ เพิ่ม Animation Controller เหมือน home
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _preloadFirstImages();

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

  // Preload รูปแรก ๆ
  void _preloadFirstImages() async {
    try {
      final pictures = await service.getFirePictures(
        widget.report.fireForestId ?? 0,
      );
      if (mounted && pictures.isNotEmpty) {
        setState(() => _cachedPictures = pictures);

        // Preload 3 รูปแรก
        for (var pic in pictures.take(3)) {
          final url = pic.fullUrl;
          if (url != null) {
            precacheImage(CachedNetworkImageProvider(url), context);
          }
        }
      }
    } catch (e) {
      // FutureBuilder จัดการ error
    }
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
          'รายละเอียดรายงาน',
          style: TextStyle(
            fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์สวย
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ เพิ่ม Welcome Header Card เหมือน home
              _buildWelcomeCard(),

              const SizedBox(height: 24),

              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildLocationCard(),
            ],
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
              Icons.description_rounded,
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
                  'รายงานไฟป่า',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  'รายละเอียดเหตุการณ์',
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
                  'สถานที่: ${widget.report.fireForestLocation ?? "ไม่ระบุ"}',
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
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.report.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.report.status ?? 'ไม่ระบุ',
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
  }

  // ✅ แก้ไข Info Card ให้สวยขึ้น
  Widget _buildInfoCard() {
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
                    Icons.info_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ข้อมูลทั่วไป',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderColor),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.location_on_rounded,
                  "สถานที่",
                  widget.report.fireForestLocation ?? '-',
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.access_time_rounded,
                  "เวลา",
                  Utils.formatDateTime(widget.report.fireForestTime),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.description_rounded,
                  "รายละเอียด",
                  widget.report.fireForestDetail ?? '-',
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.info_outline_rounded,
                  "สถานะ",
                  widget.report.status ?? '-',
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.notes_rounded,
                  "หมายเหตุ",
                  widget.report.detail?.fireStatus?.isNotEmpty == true
                      ? widget.report.detail!.fireStatus!
                      : 'อยู่ระหว่างการมอบหมาย',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ แก้ไข Info Row ให้สวยขึ้น
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

  // ✅ แก้ไข Location Card ให้สวยขึ้น และเพิ่มรูปภาพด้านบน
  Widget _buildLocationCard() {
    final lat = widget.report.fireForestLat;
    final lng = widget.report.fireForestLong;

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
                  child: Icon(
                    lat == null || lng == null
                        ? Icons.location_off_rounded
                        : Icons.location_on_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'ตำแหน่งและรูปภาพ',
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ รูปภาพด้านบน (ย้ายมาจากเดิม)
                _buildPicturesWidget(widget.report.fireForestId ?? 0),

                const SizedBox(height: 20),

                // Map Section
                if (lat == null || lng == null)
                  _buildNoLocationWidget()
                else if (lat < -90 || lat > 90 || lng < -180 || lng > 180)
                  _buildInvalidLocationWidget()
                else
                  _buildMapWidget(lat, lng),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ แก้ไข No Location Widget
  Widget _buildNoLocationWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                color: Colors.grey[500],
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "ไม่มีข้อมูลตำแหน่ง",
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 16,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ แก้ไข Invalid Location Widget
  Widget _buildInvalidLocationWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "ข้อมูลพิกัดไม่ถูกต้อง",
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ แก้ไข Map Widget
  Widget _buildMapWidget(double lat, double lng) {
    const String apiKey = "AIzaSyCE-KaxViCGvCOeh04r4S01EAW3Yj6JKw8";
    final url =
        "https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=600x300&markers=color:red%7Clabel:F%7C$lat,$lng&maptype=roadmap&key=$apiKey";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "พิกัด: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}",
          style: const TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 14,
            color: Color(0xFF616161),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
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
            onPressed: () => _openMap(lat, lng),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "เปิดใน Google Maps",
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
    );
  }

  void _openMap(double lat, double lng) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ✅ แก้ไข Pictures Widget ให้สวยขึ้น
  Widget _buildPicturesWidget(int fireForestId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                Icons.photo_library_rounded,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'รูปภาพไฟป่า',
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _cachedPictures != null
            ? _buildPicturesList(_cachedPictures!)
            : FutureBuilder<List<FirePictureModel>>(
              future: service.getFirePictures(fireForestId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return _errorWidget();
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_rounded,
                            size: 32,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "ไม่มีรูปภาพ",
                            style: TextStyle(
                              fontFamily: 'Sarabun',
                              color: Colors.grey,
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
      ],
    );
  }

  // ✅ แก้ไข Error Widget
  Widget _errorWidget() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(height: 8),
            const Text(
              "โหลดรูปภาพไม่สำเร็จ",
              style: TextStyle(
                fontFamily: 'Sarabun',
                color: Colors.red,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _cachedPictures = null),
              child: const Text(
                "ลองใหม่",
                style: TextStyle(
                  fontFamily: 'Sarabun',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ แก้ไข Pictures List
  Widget _buildPicturesList(List<FirePictureModel> pictures) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pictures.length,
        itemBuilder:
            (context, index) => _buildImageCard(pictures[index], index),
      ),
    );
  }

  // ✅ แก้ไข Image Card
  Widget _buildImageCard(FirePictureModel pic, int index) {
    final String? url = pic.fullUrl;
    final heroTag = "image_${pic.id ?? index}";

    if (url == null) {
      return Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullImage(url, heroTag),
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    color: Colors.red.shade50,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Colors.red,
                      ),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(String url, String heroTag) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: Center(
                  child: Hero(
                    tag: heroTag,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder:
                          (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
}
