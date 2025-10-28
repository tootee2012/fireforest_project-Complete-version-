import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/fireforest_model.dart';
import '../model/volunteer_model.dart';
import '../model/firepicture_model.dart';
import '../service.dart';
import '../utils.dart';

class VolunteerFireForestDetailPage extends StatefulWidget {
  final FireforestModel fireForest;
  final int fireForestDetailId;

  const VolunteerFireForestDetailPage({
    super.key,
    required this.fireForest,
    required this.fireForestDetailId,
  });

  @override
  State<VolunteerFireForestDetailPage> createState() =>
      _VolunteerFireForestDetailPageState();
}

class _VolunteerFireForestDetailPageState
    extends State<VolunteerFireForestDetailPage> {
  bool isLoading = false;
  List<VolunteerModel> volunteers = [];
  List<FirePictureModel>? _cachedPictures;

  @override
  void initState() {
    super.initState();
    _fetchVolunteers();
    _preloadFirstImages();
  }

  Future<void> _fetchVolunteers() async {
    setState(() => isLoading = true);
    try {
      volunteers = await Service().getVolunteersByFireForest(
        widget.fireForestDetailId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ Preload รูปแรก ๆ
  void _preloadFirstImages() async {
    try {
      final pictures = await Service().getFirePictures(
        widget.fireForest.fireForestId ?? 0,
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
    final fire = widget.fireForest;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "รายละเอียดไฟป่า",
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(fire),
            const SizedBox(height: 16),
            // ✅ ใช้วิธีการแสดงรูปแบบใหม่
            _buildPicturesWidget(fire.fireForestId ?? 0),
            const SizedBox(height: 16),
            _buildLocationCard(fire),
            const SizedBox(height: 16),
            _buildVolunteersCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(FireforestModel fire) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "รายละเอียดไฟป่า",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow("สถานที่", fire.fireForestLocation ?? '-'),
            _buildInfoRow("เวลา", Utils.formatDateTime(fire.fireForestTime)),
            _buildInfoRow(
              "พิกัด",
              "${fire.fireForestLat ?? '-'}, ${fire.fireForestLong ?? '-'}",
            ),
            _buildInfoRow("รายละเอียด", fire.fireForestDetail ?? '-'),
            _buildInfoRow("สถานะ", fire.status ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  // ✅ แก้ไขวิธีการแสดงรูปภาพแบบใหม่
  Widget _buildPicturesWidget(int fireForestId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'รูปภาพไฟป่า',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _cachedPictures != null
                ? _buildPicturesList(_cachedPictures!)
                : FutureBuilder<List<FirePictureModel>>(
                  future: Service().getFirePictures(fireForestId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 150,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return _errorWidget();
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "ไม่มีรูปภาพ",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
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
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            const Text(
              "โหลดรูปภาพไม่สำเร็จ",
              style: TextStyle(color: Colors.red),
            ),
            TextButton(
              onPressed: () => setState(() => _cachedPictures = null),
              child: const Text("ลองใหม่"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicturesList(List<FirePictureModel> pictures) {
    return SizedBox(
      height: 150,
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
    final heroTag = "image_${pic.id ?? index}";

    if (url == null) {
      return Container(
        width: 150,
        height: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }

    return GestureDetector(
      onTap: () => _showFullImage(url, heroTag),
      child: Container(
        width: 150,
        height: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    color: Colors.red.shade50,
                    child: const Center(child: Icon(Icons.broken_image)),
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
                              size: 64,
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

  Widget _buildLocationCard(FireforestModel fire) {
    final lat = fire.fireForestLat;
    final lng = fire.fireForestLong;

    if (lat == null || lng == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.location_off, color: Colors.grey[400], size: 24),
              const SizedBox(width: 8),
              const Text(
                "ไม่มีข้อมูลตำแหน่ง",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "พิกัดบนแผนที่",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text("พิกัด: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}"),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  "https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=600x300&markers=color:red%7Clabel:F%7C$lat,$lng&maptype=roadmap&key=AIzaSyCE-KaxViCGvCOeh04r4S01EAW3Yj6JKw8",
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text(
                          "ไม่สามารถโหลดแผนที่",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "อาสาสมัครที่เข้าร่วม",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                )
                : volunteers.isEmpty
                ? Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "ยังไม่มีอาสาสมัคร",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: volunteers.length,
                  itemBuilder: (context, index) {
                    final v = volunteers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDCEDC8)),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          v.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        subtitle: Text("อายุ ${v.age} ปี"),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
