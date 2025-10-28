import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fireforest_project/model/fireforest_model.dart';
import 'package:fireforest_project/service.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReportFirePage extends StatefulWidget {
  final String userEmail;
  const ReportFirePage({super.key, required this.userEmail});

  @override
  State<ReportFirePage> createState() => _ReportFirePageState();
}

class _ReportFirePageState extends State<ReportFirePage> {
  final _formKey = GlobalKey<FormState>();
  final Service service = Service();

  // Controllers
  final TextEditingController locationController = TextEditingController();
  final TextEditingController detailController = TextEditingController();

  // Form values
  String severity = 'ระดับน้อย';
  String areaType = 'ป่าไม้';

  // Image handling (ใช้โค้ดเดิม)
  List<Uint8List> _thumbnails = [];
  List<File> _originalFiles = [];
  final ImagePicker picker = ImagePicker();

  // Map & Location
  GoogleMapController? _mapController;
  Position? currentPosition;
  LatLng? selectedLocation;
  Set<Marker> markers = {};
  bool isLoadingLocation = false;
  bool isSubmitting = false;
  bool showMap = false;

  // Progress tracking
  OverlayEntry? _progressOverlay;
  String _currentProgressText = "";
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    locationController.dispose();
    detailController.dispose();
    _mapController?.dispose();

    // ✅ ทำความสะอาด progress overlay
    if (_progressOverlay != null) {
      _progressOverlay!.remove();
      _progressOverlay = null;
    }

    super.dispose();
  }

  /// ✅ รับตำแหน่งปัจจุบันและแสดงบนแผนที่ (เพิ่ม mounted check)
  Future<void> _getCurrentLocation() async {
    if (!mounted) return; // ✅ เพิ่ม mounted check
    setState(() => isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('กรุณาเปิดบริการตำแหน่ง (GPS)');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
          'ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่งอย่างถาวร\nกรุณาเปิดในการตั้งค่า',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return; // ✅ เพิ่ม mounted check ก่อน setState
      setState(() {
        currentPosition = position;
        selectedLocation = LatLng(position.latitude, position.longitude);
      });

      _updateMapMarker(LatLng(position.latitude, position.longitude));

      String address = await getAddressFromLatLong(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return; // ✅ เพิ่ม mounted check ก่อน setState
      setState(() {
        locationController.text = address;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16.0,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 ได้รับตำแหน่งแล้ว: ${address.length > 50 ? address.substring(0, 50) + '...' : address}',
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Location error: $e");
      _showLocationError('ไม่สามารถรับตำแหน่งได้: $e');
    } finally {
      if (mounted) {
        // ✅ เพิ่ม mounted check
        setState(() => isLoadingLocation = false);
      }
    }
  }

  void _updateMapMarker(LatLng location) {
    if (!mounted) return; // ✅ เพิ่ม mounted check
    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('fire_location'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'ตำแหน่งไฟป่า',
            snippet: 'กดเพื่อเลือกตำแหน่ง',
          ),
        ),
      );
      selectedLocation = location;
    });
  }

  void _onMapTapped(LatLng location) async {
    _updateMapMarker(location);

    String address = await getAddressFromLatLong(
      location.latitude,
      location.longitude,
    );

    if (!mounted) return; // ✅ เพิ่ม mounted check
    setState(() {
      locationController.text = address;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📍 เลือกตำแหน่งใหม่: ${address.substring(0, address.length > 40 ? 40 : address.length)}...',
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'ลองใหม่',
            onPressed: _getCurrentLocation,
          ),
        ),
      );
    }
  }

  /// ✅ ฟังก์ชันแปลงพิกัดเป็นที่อยู่ (ใช้เดียวกับ Register)
  Future<String> getAddressFromLatLong(double lat, double lng) async {
    const googleMapsApiKey = "AIzaSyCE-KaxViCGvCOeh04r4S01EAW3Yj6JKw8";
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleMapsApiKey&language=th&result_type=street_address|sublocality|locality';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          for (var result in data['results']) {
            String address = result['formatted_address'];
            if (address.contains(RegExp(r'^[A-Z0-9]{4}\+[A-Z0-9]{2,3}'))) {
              continue;
            }
            address = _cleanAddress(address);
            if (address.length > 15 &&
                !address.contains(RegExp(r'^[A-Z0-9]+$'))) {
              return address;
            }
          }
          return _buildAddressFromComponents(data['results'][0]);
        }
      }
      return "ไม่พบที่อยู่";
    } catch (e) {
      debugPrint("Geocoding error: $e");
      return "เกิดข้อผิดพลาดในการหาที่อยู่";
    }
  }

  String _cleanAddress(String address) {
    address = address.replaceAll(
      RegExp(r'[A-Z0-9]{4}\+[A-Z0-9]{2,3}\s*,?\s*'),
      '',
    );
    address = address.replaceAll(RegExp(r',?\s*(Thailand|ประเทศไทย)\s*$'), '');
    address = address.replaceAll(RegExp(r'^,\s*'), '');
    address = address.replaceAll(RegExp(r',\s*$'), '');
    address = address.replaceAll(RegExp(r',\s*,+'), ',');
    return address.trim();
  }

  String _buildAddressFromComponents(Map<String, dynamic> result) {
    if (result['address_components'] == null) {
      return "ไม่พบที่อยู่ที่ละเอียด";
    }

    Map<String, String> components = {};

    for (var component in result['address_components']) {
      List<String> types = List<String>.from(component['types']);
      String longName = component['long_name'];

      if (longName.contains(RegExp(r'^[A-Z0-9]{4}\+[A-Z0-9]{2,3}$'))) {
        continue;
      }

      if (types.contains('street_number')) {
        components['street_number'] = longName;
      } else if (types.contains('route')) {
        components['route'] = longName;
      } else if (types.contains('sublocality_level_1') ||
          types.contains('sublocality')) {
        components['sublocality'] = longName;
      } else if (types.contains('locality')) {
        components['locality'] = longName;
      } else if (types.contains('administrative_area_level_2')) {
        components['district'] = longName;
      } else if (types.contains('administrative_area_level_1')) {
        components['province'] = longName;
      }
    }

    List<String> addressParts = [];

    if (components['street_number'] != null && components['route'] != null) {
      addressParts.add('${components['street_number']} ${components['route']}');
    } else if (components['route'] != null) {
      addressParts.add(components['route']!);
    }

    if (components['sublocality'] != null) {
      addressParts.add(components['sublocality']!);
    }

    if (components['locality'] != null) {
      addressParts.add(components['locality']!);
    }

    if (components['district'] != null &&
        components['district'] != components['locality']) {
      addressParts.add(components['district']!);
    }

    if (components['province'] != null) {
      addressParts.add(components['province']!);
    }

    String finalAddress = addressParts.join(' ');
    return finalAddress.isEmpty ? "ไม่พบที่อยู่ที่ละเอียด" : finalAddress;
  }

  /// ✅ เลือกรูปหลายรูปและสร้าง thumbnail (เพิ่ม mounted check)
  Future<void> _pickImages() async {
    try {
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        int totalImages = _originalFiles.length + pickedFiles.length;
        if (totalImages > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('สามารถเลือกรูปได้สูงสุด 5 รูป'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('กำลังประมวลผลรูป...'),
                ],
              ),
              backgroundColor: AppTheme.primaryColor,
              duration: Duration(seconds: 2),
            ),
          );
        }

        for (var picked in pickedFiles) {
          if (!mounted) return; // ✅ เพิ่ม mounted check ใน loop

          File originalFile = File(picked.path);
          Uint8List bytes = await originalFile.readAsBytes();
          img.Image? image = img.decodeImage(bytes);
          if (image == null) continue;

          // สร้าง thumbnail
          img.Image thumbnail = img.copyResize(image, width: 180, height: 180);
          Uint8List thumbBytes = Uint8List.fromList(
            img.encodeJpg(thumbnail, quality: 80),
          );

          if (!mounted) return; // ✅ เพิ่ม mounted check ก่อน setState
          setState(() {
            _thumbnails.add(thumbBytes);
            _originalFiles.add(originalFile);
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เลือกรูป ${pickedFiles.length} รูปแล้ว'),
              backgroundColor: AppTheme.primaryColor,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเลือกรูป: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    if (!mounted) return; // ✅ เพิ่ม mounted check
    setState(() {
      _thumbnails.removeAt(index);
      _originalFiles.removeAt(index);
    });
  }

  /// ✅ Upload file -> return แค่ชื่อไฟล์ (ใช้โค้ดเดิมที่ทำงานได้)
  Future<String> uploadImage(File file) async {
    try {
      // แปลงไฟล์เป็น JPG
      Uint8List bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception("Cannot decode image");

      Uint8List jpgBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: 85),
      );

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/${file.path.split('/').last.split('.').first}.jpg',
      );
      await tempFile.writeAsBytes(jpgBytes);

      final uri = Uri.parse("${Service.baseUrl}/upload");
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          tempFile.path,
          filename: tempFile.path.split('/').last,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['filename'] ?? tempFile.path.split('/').last;
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// ✅ แสดง Progress Dialog (เพิ่ม mounted check)
  void _showProgressDialog() {
    if (!mounted) return; // ✅ เพิ่ม mounted check

    _progressOverlay = OverlayEntry(
      builder:
          (context) => Material(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentProgressText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _currentProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_currentProgress * 100).toInt()}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_progressOverlay!);
  }

  void _updateProgress(String text, double progress) {
    if (!mounted) return; // ✅ เพิ่ม mounted check

    if (_progressOverlay != null) {
      setState(() {
        _currentProgressText = text;
        _currentProgress = progress;
      });
      _progressOverlay!.markNeedsBuild();
    }
  }

  /// ✅ ส่ง report พร้อม notification (เพิ่ม mounted check)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาเลือกตำแหน่งบนแผนที่หรือกดปุ่มรับตำแหน่งปัจจุบัน',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_originalFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาแนบรูปภาพอย่างน้อย 1 รูป")),
      );
      return;
    }

    if (!mounted) return; // ✅ เพิ่ม mounted check
    setState(() => isSubmitting = true);
    _showProgressDialog();

    try {
      // Step 1: อัปโหลดรูปภาพ (ใช้โค้ดเดิม)
      _updateProgress("กำลังอัปโหลดรูปภาพ...", 0.1);
      List<String> uploadedFilenames = [];

      for (int i = 0; i < _originalFiles.length; i++) {
        if (!mounted) return; // ✅ เพิ่ม mounted check ใน loop

        double progress = 0.1 + (0.4 * (i / _originalFiles.length));
        _updateProgress(
          "กำลังอัปโหลดรูป ${i + 1}/${_originalFiles.length}...",
          progress,
        );

        try {
          String filename = await uploadImage(_originalFiles[i]);
          uploadedFilenames.add(filename);
          debugPrint(
            "✅ Uploaded image ${i + 1}/${_originalFiles.length}: $filename",
          );
        } catch (e) {
          debugPrint("❌ Failed to upload image: $e");
        }

        // หน่วงเวลาเล็กน้อยเพื่อไม่ให้ server ล้น
        if (i < _originalFiles.length - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      if (!mounted) return; // ✅ เพิ่ม mounted check

      // Step 2: บันทึกรายงาน
      _updateProgress("กำลังบันทึกรายงาน...", 0.7);
      final report = FireforestModel(
        fireForestLocation: locationController.text.trim(),
        fireForestDetail: detailController.text.trim(),
        status: severity,
        field: areaType,
        fireForestTime: DateTime.now().toIso8601String(),
        userEmail: widget.userEmail,
      );

      final result = await service.saveFireForest(
        report,
        uploadedFilenames,
        widget.userEmail,
      );

      if (!mounted) return; // ✅ เพิ่ม mounted check

      // Step 3: ส่งแจ้งเตือนไปยัง Agencies (Fire and Forget)
      _updateProgress("กำลังส่งแจ้งเตือน...", 0.9);

      service
          .notifyAgenciesAboutFire({
            'fireForestId': result['fireForestId'],
            'location': locationController.text.trim(),
            'severity': severity,
            'areaType': areaType,
            'timestamp': DateTime.now().toIso8601String(),
            'userEmail': widget.userEmail,
            'detail': detailController.text.trim(),
            'coordinates': {
              'lat': selectedLocation!.latitude,
              'lng': selectedLocation!.longitude,
            },
          })
          .then((_) {
            debugPrint('✅ Notification sent to agencies successfully');
          })
          .catchError((e) {
            debugPrint('❌ Failed to send notification: $e');
          });

      _updateProgress("เสร็จสิ้น", 1.0);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // ✅ ปิด progress overlay อย่างปลอดภัย
        if (_progressOverlay != null) {
          _progressOverlay!.remove();
          _progressOverlay = null;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ แจ้งเหตุไฟป่าสำเร็จ"),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context, true); // ✅ ส่ง true กลับไปเพื่อบอกว่าสำเร็จ
      }
    } catch (e) {
      debugPrint("Submit error: $e");

      if (mounted) {
        // ✅ ปิด progress overlay อย่างปลอดภัย
        if (_progressOverlay != null) {
          _progressOverlay!.remove();
          _progressOverlay = null;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ เกิดข้อผิดพลาด: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(label: 'ลองใหม่', onPressed: _submitForm),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'แจ้งเหตุไฟป่า',
          style: TextStyle(
            fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์เหมือน home
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'แจ้งเหตุไฟป่า',
                      style: TextStyle(
                        fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'กรุณากรอกข้อมูลให้ครบถ้วนเพื่อความรวดเร็วในการช่วยเหลือ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // รูปภาพ
              _buildImageSection(),
              const SizedBox(height: 24),

              // สถานที่ + แผนที่
              _buildLocationSection(),
              const SizedBox(height: 24),

              // ระดับความรุนแรง
              _buildSeveritySection(),
              const SizedBox(height: 24),

              // ประเภทพื้นที่
              _buildAreaTypeSection(),
              const SizedBox(height: 24),

              // รายละเอียดเพิ่มเติม
              _buildDetailSection(),
              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ เพิ่มฟอนต์ใน Widget methods
  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'รูปภาพ',
                style: TextStyle(
                  fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                '${_originalFiles.length}/5',
                style: TextStyle(
                  fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          // ... ส่วนอื่นๆ ของ _buildImageSection() เหมือนเดิม ...
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _originalFiles.length < 5 ? _pickImages : null,
            child: Container(
              width: double.infinity,
              height: _thumbnails.isEmpty ? 120 : 200,
              decoration: BoxDecoration(
                color:
                    _originalFiles.length < 5
                        ? AppTheme.surfaceColor
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _originalFiles.length < 5
                          ? AppTheme.primaryColor
                          : Colors.grey[400]!,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child:
                  _thumbnails.isEmpty
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 32,
                            color:
                                _originalFiles.length < 5
                                    ? AppTheme.primaryColor
                                    : Colors.grey[500],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _originalFiles.length < 5
                                ? 'แนบรูป (ถ่าย)'
                                : 'ครบ 5 รูปแล้ว',
                            style: TextStyle(
                              fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์
                              fontSize: 16,
                              color:
                                  _originalFiles.length < 5
                                      ? AppTheme.primaryColor
                                      : Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_originalFiles.length < 5)
                            Text(
                              'สูงสุด 5 รูป',
                              style: TextStyle(
                                fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      )
                      : Padding(
                        padding: const EdgeInsets.all(8),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 1,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount:
                              _thumbnails.length +
                              (_originalFiles.length < 5 ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _thumbnails.length) {
                              // แสดงรูปภาพที่เลือก
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _thumbnails[index],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // ปุ่มเพิ่มรูป
                              return GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.primaryColor,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        size: 24,
                                        color: AppTheme.primaryColor,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'เพิ่ม',
                                        style: TextStyle(
                                          fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์
                                          fontSize: 12,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'สถานที่เกิดเหตุ',
                style: TextStyle(
                  fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (!mounted) return; // ✅ เพิ่ม mounted check
                  setState(() {
                    showMap = !showMap;
                  });
                },
                icon: Icon(
                  showMap ? Icons.map : Icons.map_outlined,
                  color: AppTheme.primaryColor,
                ),
                tooltip: showMap ? 'ซ่อนแผนที่' : 'แสดงแผนที่',
              ),
              if (isLoadingLocation)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              IconButton(
                onPressed: isLoadingLocation ? null : _getCurrentLocation,
                icon: Icon(
                  Icons.my_location,
                  color:
                      isLoadingLocation ? Colors.grey : AppTheme.primaryColor,
                ),
                tooltip: 'รับตำแหน่งใหม่',
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: locationController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'ระบุสถานที่เกิดเหตุ หรือกดปุ่มรับตำแหน่งปัจจุบัน',
              hintStyle: TextStyle(
                fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์
                color: Colors.grey[500],
              ),
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(Icons.place, color: AppTheme.primaryColor),
            ),
            style: const TextStyle(
              fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณาระบุสถานที่เกิดเหตุ';
              }
              return null;
            },
          ),

          if (selectedLocation != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.gps_fixed, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'พิกัด: ${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (showMap) ...[
            const SizedBox(height: 16),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    selectedLocation != null
                        ? GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: selectedLocation!,
                            zoom: 16.0,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          onTap: _onMapTapped,
                          markers: markers,
                          mapType: MapType.hybrid,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          compassEnabled: true,
                          tiltGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                        )
                        : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '💡 แตะบนแผนที่เพื่อเลือกตำแหน่งไฟป่า',
              style: TextStyle(
                fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeveritySection() {
    final severityOptions = [
      {'value': 'ระดับน้อย', 'label': 'ระดับน้อย', 'color': AppTheme.success},
      {
        'value': 'ระดับปานกลาง',
        'label': 'ระดับปานกลาง',
        'color': Colors.orange,
      },
      {'value': 'ระดับรุนแรง', 'label': 'ระดับรุนแรง', 'color': Colors.red},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.priority_high, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'ระดับความรุนแรง',
                style: TextStyle(
                  fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...severityOptions.map((option) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: RadioListTile<String>(
                title: Text(
                  option['label'] as String,
                  style: const TextStyle(
                    fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์
                    fontSize: 16,
                  ),
                ),
                value: option['value'] as String,
                groupValue: severity,
                activeColor: option['color'] as Color,
                onChanged: (value) {
                  if (!mounted) return; // ✅ เพิ่ม mounted check
                  setState(() {
                    severity = value!;
                  });
                },
                tileColor:
                    severity == option['value']
                        ? (option['color'] as Color).withOpacity(0.1)
                        : AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAreaTypeSection() {
    final areaOptions = ['ป่าไม้', 'ชุมชน', 'บ่อขยะ', 'อื่นๆ'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.nature, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'ประเภทพื้นที่',
                style: TextStyle(
                  fontFamily: 'Kanit',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: areaType,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Sarabun',
              color: Colors.black, // ✅ เพิ่มสีดำให้ตัวหนังสือ
              fontSize: 16, // ✅ เพิ่มขนาดฟอนต์
            ),
            dropdownColor: Colors.white, // ✅ เพิ่มสีพื้นหลัง dropdown
            items:
                areaOptions.map((String area) {
                  return DropdownMenuItem<String>(
                    value: area,
                    child: Text(
                      area,
                      style: const TextStyle(
                        fontFamily: 'Sarabun',
                        color:
                            Colors.black, // ✅ เพิ่มสีดำให้ตัวหนังสือใน dropdown
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              if (!mounted) return;
              setState(() {
                areaType = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'รายละเอียดเพิ่มเติม',
                style: TextStyle(
                  fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: detailController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'บรรยายสถานการณ์ เช่น ขนาดไฟ ทิศทางลม สิ่งที่อาจเป็นอันตราย',
              hintStyle: TextStyle(
                fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์
                color: Colors.grey[500],
              ),
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Sarabun', // ✅ เพิ่มฟอนต์
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child:
            isSubmitting
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'กำลังส่งรายงาน...',
                      style: TextStyle(
                        fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : const Text(
                  'แจ้งเหตุ',
                  style: TextStyle(
                    fontFamily: 'Kanit', // ✅ เพิ่มฟอนต์
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}
