import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;

  const MapPickerScreen({Key? key, this.initialPosition, this.initialAddress})
    : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? mapController;
  LatLng selectedPosition = const LatLng(
    13.736717,
    100.523186,
  ); // Default: Bangkok
  String selectedAddress = '';
  bool isLoading = false;
  bool showAddressCard = true;

  // ✅ เพิ่ม Timer สำหรับ debounce
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      selectedPosition = widget.initialPosition!;
      if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
        selectedAddress = widget.initialAddress!;
      } else {
        _getAddressFromLatLng(selectedPosition);
      }
    } else {
      _getAddressFromLatLng(selectedPosition);
    }
  }

  @override
  void dispose() {
    // ✅ ยกเลิก Timer และ dispose resources
    _debounceTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  // ✅ ปรับปรุงฟังก์ชันแปลง LatLng เป็นที่อยู่ - แก้ไข setState() error
  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (!mounted) return; // ✅ เช็ค mounted ก่อน

    setState(() => isLoading = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
        },
      );

      if (!mounted) return; // ✅ เช็ค mounted หลัง await

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String fullAddress = _buildThaiAddress(place, position);

        setState(() {
          selectedAddress = fullAddress;
        });

        debugPrint('✅ Address found: $fullAddress');
      } else {
        setState(() {
          selectedAddress =
              'พิกัด: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      debugPrint('❌ Error getting address: $e');

      if (!mounted) return; // ✅ เช็ค mounted ก่อน setState

      String errorMessage;
      String fallbackAddress =
          'พิกัด: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      if (e.toString().contains('Service not available')) {
        errorMessage =
            'บริการแผนที่ไม่พร้อมใช้งาน กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
      } else if (e.toString().contains('IO_ERROR')) {
        errorMessage = 'ไม่สามารถเชื่อมต่อบริการได้ กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
      } else {
        errorMessage = 'ไม่สามารถดึงข้อมูลที่อยู่ได้';
      }

      setState(() {
        selectedAddress = fallbackAddress;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: Colors.white,
              onPressed: () => _debouncedGetAddress(position),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ✅ เพิ่มฟังก์ชัน debounce เพื่อป้องกันการเรียกซ้ำเร็วเกินไป
  void _debouncedGetAddress(LatLng position) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _getAddressFromLatLng(position);
      }
    });
  }

  // ✅ ปรับปรุงฟังก์ชันสร้างที่อยู่ให้ดีกว่าเดิม
  String _buildThaiAddress(Placemark place, LatLng position) {
    List<String> addressParts = [];

    // เลขที่ + ถนน
    if (place.name != null &&
        place.name!.isNotEmpty &&
        place.name != 'Unnamed Road' &&
        !place.name!.contains(RegExp(r'^[A-Z0-9]{4}\+[A-Z0-9]{2,3}'))) {
      addressParts.add(place.name!);
    }

    if (place.street != null &&
        place.street!.isNotEmpty &&
        place.street != place.name &&
        !place.street!.contains(RegExp(r'^[A-Z0-9]{4}\+[A-Z0-9]{2,3}'))) {
      addressParts.add(place.street!);
    }

    // แขวง/ตำบล
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      String subLocality = place.subLocality!;
      if (!subLocality.contains('แขวง') && !subLocality.contains('ตำบล')) {
        subLocality = 'แขวง$subLocality';
      }
      addressParts.add(subLocality);
    }

    // เขต/อำเภอ
    if (place.locality != null && place.locality!.isNotEmpty) {
      String locality = place.locality!;
      if (!locality.contains('เขต') && !locality.contains('อำเภอ')) {
        locality = 'เขต$locality';
      }
      addressParts.add(locality);
    }

    // อำเภอ (ถ้าไม่มี locality)
    if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.isNotEmpty &&
        (place.locality == null || place.locality!.isEmpty)) {
      String district = place.subAdministrativeArea!;
      if (!district.contains('อำเภอ')) {
        district = 'อำเภอ$district';
      }
      addressParts.add(district);
    }

    // จังหวัด
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      String province = place.administrativeArea!;
      if (!province.contains('จังหวัด')) {
        province = 'จังหวัด$province';
      }
      addressParts.add(province);
    }

    // รหัสไปรษณีย์
    if (place.postalCode != null &&
        place.postalCode!.isNotEmpty &&
        place.postalCode != '00000') {
      addressParts.add(place.postalCode!);
    }

    String fullAddress = addressParts.join(' ');

    // ถ้าที่อยู่สั้นเกินไป หรือว่างเปล่า ให้ใช้พิกัด
    if (fullAddress.isEmpty || fullAddress.length < 15) {
      fullAddress =
          'พิกัด: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    }

    return fullAddress;
  }

  // ✅ ปรับปรุงฟังก์ชันดึงตำแหน่งปัจจุบัน
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );

        if (!mounted) return;

        LatLng newPosition = LatLng(position.latitude, position.longitude);

        setState(() => selectedPosition = newPosition);

        // เลื่อนกล้องไปตำแหน่งใหม่
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 16.0),
        );

        _debouncedGetAddress(newPosition);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('ดึงตำแหน่งปัจจุบันสำเร็จ'),
                ],
              ),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('กรุณาอนุญาตการเข้าถึงตำแหน่ง'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ไม่สามารถดึงตำแหน่งได้: ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e.toString()}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map เต็มหน้าจอ
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: selectedPosition,
              zoom: 16.0,
            ),
            onTap: (LatLng position) {
              if (mounted) {
                setState(() => selectedPosition = position);
                _debouncedGetAddress(position); // ✅ ใช้ debounced version
              }
            },
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: selectedPosition,
                draggable: true,
                onDragEnd: (LatLng position) {
                  if (mounted) {
                    setState(() => selectedPosition = position);
                    _debouncedGetAddress(position); // ✅ ใช้ debounced version
                  }
                },
                infoWindow: InfoWindow(
                  title: '📍 ตำแหน่งที่เลือก',
                  snippet:
                      selectedAddress.isEmpty
                          ? 'กำลังโหลด...'
                          : selectedAddress.length > 50
                          ? '${selectedAddress.substring(0, 50)}...'
                          : selectedAddress,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            mapType: MapType.normal,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),

          // Top Control Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  // ปุ่มกลับ
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      tooltip: 'กลับ',
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title
                  const Expanded(
                    child: Text(
                      'เลือกตำแหน่ง',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ ปุ่มยืนยัน - ปรับปรุงใหม่
                  Container(
                    decoration: BoxDecoration(
                      color:
                          selectedAddress.isNotEmpty && !isLoading
                              ? AppTheme.primaryColor
                              : Colors.grey,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: TextButton.icon(
                      onPressed:
                          selectedAddress.isNotEmpty && !isLoading
                              ? () {
                                Navigator.pop(context, {
                                  'position': selectedPosition,
                                  'address': selectedAddress,
                                  'latitude': selectedPosition.latitude,
                                  'longitude': selectedPosition.longitude,
                                });
                              }
                              : null,
                      icon:
                          isLoading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                      label: Text(
                        isLoading ? 'กำลังโหลด...' : 'ยืนยัน',
                        style: const TextStyle(
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

          // Address Card
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top:
                showAddressCard
                    ? 80 + MediaQuery.of(context).padding.top
                    : -250,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'ที่อยู่ที่เลือก',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        IconButton(
                          onPressed: () {
                            setState(() => showAddressCard = !showAddressCard);
                          },
                          icon: Icon(
                            showAddressCard
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                          tooltip:
                              showAddressCard ? 'ซ่อนที่อยู่' : 'แสดงที่อยู่',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    isLoading
                        ? const Row(
                          children: [
                            Icon(Icons.search, size: 16, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'กำลังค้นหาที่อยู่...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                        : Text(
                          selectedAddress.isEmpty
                              ? 'แตะเพื่อเลือกตำแหน่งบนแผนที่'
                              : selectedAddress,
                          style: TextStyle(
                            color:
                                selectedAddress.isEmpty
                                    ? Colors.grey
                                    : Colors.black87,
                            fontSize: 14,
                          ),
                        ),

                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'พิกัด: ${selectedPosition.latitude.toStringAsFixed(6)}, ${selectedPosition.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Control Buttons (ด้านล่าง)
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // ปุ่มแสดง/ซ่อน Address Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() => showAddressCard = !showAddressCard);
                    },
                    icon: Icon(
                      showAddressCard ? Icons.info : Icons.info_outline,
                      color: AppTheme.primaryColor,
                    ),
                    tooltip: 'แสดง/ซ่อน ที่อยู่',
                  ),
                ),

                const Spacer(),

                // ปุ่ม GPS
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: isLoading ? null : _getCurrentLocation,
                    icon:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(
                              Icons.my_location,
                              color: Colors.white,
                            ),
                    tooltip: 'ตำแหน่งปัจจุบัน',
                  ),
                ),

                const SizedBox(width: 12),

                // ปุ่ม Zoom In
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      mapController?.animateCamera(CameraUpdate.zoomIn());
                    },
                    icon: const Icon(Icons.zoom_in, color: Colors.black87),
                    tooltip: 'ขยาย',
                  ),
                ),

                const SizedBox(width: 8),

                // ปุ่ม Zoom Out
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      mapController?.animateCamera(CameraUpdate.zoomOut());
                    },
                    icon: const Icon(Icons.zoom_out, color: Colors.black87),
                    tooltip: 'ย่อ',
                  ),
                ),
              ],
            ),
          ),

          // ✅ Center Crosshair - ปรับปรุงให้สวยกว่า
          const Center(
            child: Icon(
              Icons.my_location,
              size: 30,
              color: Colors.red,
              shadows: [
                Shadow(
                  color: Colors.white,
                  offset: Offset(1, 1),
                  blurRadius: 3,
                ),
                Shadow(
                  color: Colors.black26,
                  offset: Offset(2, 2),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
