import 'package:fireforest_project/screens/login.dart';
import 'package:fireforest_project/screens/map_picker.dart';
import 'package:fireforest_project/service.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  Service service = Service();
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final telController = TextEditingController();
  final birthdayController = TextEditingController();

  String? _selectedGender = "ชาย";
  bool _isGenderError = false;
  bool _isBirthdayError = false;

  // ✅ เพิ่มตัวแปรสำหรับเก็บตำแหน่งจากแผนที่
  LatLng? selectedPosition;

  @override
  void initState() {
    super.initState();

    // ✅ เพิ่ม listener เพื่ออัปเดต UI เมื่อพิมพ์รหัสผ่าน
    passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // ✅ ลบ listener เมื่อทำลาย widget
    passwordController.removeListener(() {});
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    telController.dispose();
    birthdayController.dispose();
    super.dispose();
  }

  // ✅ แก้ไขฟังก์ชันช่วยสำหรับประเมินรหัสผ่าน - เปลี่ยน max เป็น 50
  Color _getPasswordStrengthColor(int length) {
    if (length < 6) return Colors.red;
    if (length < 8) return Colors.orange;
    if (length < 12) return AppTheme.primaryLight;
    if (length <= 50) return AppTheme.primaryColor; // ✅ เปลี่ยนจาก 33 เป็น 50
    return Colors.red; // เกิน 50 ตัว
  }

  IconData _getPasswordStrengthIcon(int length) {
    if (length < 6) return Icons.error;
    if (length < 8) return Icons.warning_amber;
    if (length < 12) return Icons.check_circle;
    if (length <= 50) return Icons.security; // ✅ เปลี่ยนจาก 33 เป็น 50
    return Icons.error; // เกิน 50 ตัว
  }

  String _getPasswordStrengthText(int length) {
    if (length < 6) return "สั้นเกินไป";
    if (length < 8) return "ปานกลาง";
    if (length < 12) return "ดี";
    if (length <= 50) return "แข็งแกร่ง"; // ✅ เปลี่ยนจาก 33 เป็น 50
    return "ยาวเกินไป"; // เกิน 50 ตัว
  }

  // ✅ ฟังก์ชันแปลงพิกัดเป็นที่อยู่ (เหมือนกับ ReportFire)
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

  // ✅ เพิ่มฟังก์ชัน _cleanAddress
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

  // ✅ เพิ่มฟังก์ชัน _buildAddressFromComponents
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

  // ตรวจสอบเบอร์โทร - ต้องขึ้นต้นด้วย 06, 07, 08, 09
  bool isValidPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final phoneRegex = RegExp(r'^0[6-9]\d{8}$');
    return phoneRegex.hasMatch(cleanPhone);
  }

  // ✅ ตรวจสอบอายุ - ต้องมากกว่า 15 ปี
  bool isValidAge(String birthDateStr) {
    if (birthDateStr.isEmpty) return false;

    try {
      final birthDate = DateFormat("dd/MM/yyyy").parse(birthDateStr);
      final today = DateTime.now();
      final age = today.year - birthDate.year;

      // ตรวจสอบว่าผ่านวันเกิดในปีนี้หรือยัง
      final hadBirthdayThisYear =
          (today.month > birthDate.month) ||
          (today.month == birthDate.month && today.day >= birthDate.day);

      final actualAge = hadBirthdayThisYear ? age : age - 1;

      return actualAge >= 15;
    } catch (e) {
      return false;
    }
  }

  // ✅ คำนวณอายุเพื่อแสดง
  int? calculateAge(String birthDateStr) {
    if (birthDateStr.isEmpty) return null;

    try {
      final birthDate = DateFormat("dd/MM/yyyy").parse(birthDateStr);
      final today = DateTime.now();
      final age = today.year - birthDate.year;

      final hadBirthdayThisYear =
          (today.month > birthDate.month) ||
          (today.month == birthDate.month && today.day >= birthDate.day);

      return hadBirthdayThisYear ? age : age - 1;
    } catch (e) {
      return null;
    }
  }

  // ✅ ฟังก์ชันเปิดหน้าเลือกตำแหน่งจากแผนที่
  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapPickerScreen(
              initialPosition: selectedPosition,
              initialAddress: addressController.text,
            ),
      ),
    );

    if (result != null) {
      setState(() {
        selectedPosition = result['position'];
      });

      // ✅ แปลงพิกัดเป็นที่อยู่ด้วย Google Geocoding API
      if (selectedPosition != null) {
        // แสดง loading
        setState(() {
          addressController.text = 'กำลังค้นหาที่อยู่...';
        });

        try {
          String address = await getAddressFromLatLong(
            selectedPosition!.latitude,
            selectedPosition!.longitude,
          );

          setState(() {
            addressController.text = address;
          });

          print('✅ Address converted: $address');
        } catch (e) {
          // ถ้าแปลงไม่ได้ให้ใช้พิกัดแทน
          setState(() {
            addressController.text =
                'พิกัด: ${selectedPosition!.latitude.toStringAsFixed(6)}, ${selectedPosition!.longitude.toStringAsFixed(6)}';
          });
          print('❌ Address conversion failed: $e');
        }
      }
    }
  }

  Future<void> saveUser() async {
    print("Starting registration process..."); // Debug

    if (!_formKey.currentState!.validate() ||
        _selectedGender == null ||
        birthdayController.text.isEmpty) {
      print("Validation failed"); // Debug
      if (_selectedGender == null) setState(() => _isGenderError = true);
      if (birthdayController.text.isEmpty) {
        setState(() => _isBirthdayError = true);
      }
      return;
    }

    final gender = _selectedGender!;
    final inputDate = birthdayController.text;
    print("Input date: $inputDate"); // Debug

    try {
      final parsedDate = DateFormat("dd/MM/yyyy").parse(inputDate);
      final formattedDate = DateFormat("yyyy-MM-dd").format(parsedDate);
      print("Formatted date: $formattedDate"); // Debug

      // ✅ ตรวจสอบอายุ
      if (!isValidAge(inputDate)) {
        final age = calculateAge(inputDate);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              age != null
                  ? "อายุของคุณ $age ปี ต้องมีอายุมากกว่า 15 ปีขึ้นไป"
                  : "วันเกิดไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // แก้ไขการฟอร์แมตเบอร์โทร - เก็บแค่ตัวเลข 10 หลัก
      String formattedTel = telController.text.replaceAll(RegExp(r'\D'), '');
      print("Formatted tel: $formattedTel"); // Debug
      print("Tel length: ${formattedTel.length}"); // Debug

      // ตรวจสอบความยาวและรูปแบบเบอร์โทร
      if (!isValidPhone(formattedTel)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "เบอร์โทรต้องขึ้นต้นด้วย 06, 07, 08, หรือ 09 และมี 10 หลัก",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // เช็คอีเมลซ้ำ
      print("Checking email: ${emailController.text}"); // Debug
      var emailExists = await service.getUserByEmail(emailController.text);
      print("Email exists: $emailExists"); // Debug

      if (emailExists != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("อีเมลนี้มีอยู่ในระบบแล้ว ❌"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // บันทึกข้อมูล - ส่งเบอร์โทรแบบตัวเลขธรรมดา
      print("Saving user data..."); // Debug
      await service.saveUser(
        emailController.text,
        firstNameController.text,
        lastNameController.text,
        gender,
        formattedDate,
        addressController.text,
        passwordController.text,
        formattedTel, // ส่งแค่ตัวเลข 10 หลัก เช่น "0812345678"
      );
      print("User saved successfully"); // Debug

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("สมัครสมาชิกสำเร็จ ✅"),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      print("Error occurred: $e"); // Debug
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เกิดข้อผิดพลาด: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 20),
      ), // เริ่มต้นที่ 20 ปีที่แล้ว
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 15),
      ), // ✅ จำกัดไม่ให้เลือกวันที่ทำให้อายุต่ำกว่า 15 ปี
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
        _isBirthdayError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "สมัครสมาชิก",
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
        child: Form(
          key: _formKey,
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
                child: const Column(
                  children: [
                    Text(
                      'ลงทะเบียนสมาชิกใหม่',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'กรุณากรอกข้อมูลให้ครบถ้วน',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Form Card
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email
                    const Text(
                      "อีเมล",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "กรุณากรอกอีเมล";
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return "รูปแบบอีเมลไม่ถูกต้อง";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // First Name
                    const Text(
                      "ชื่อ",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "กรุณากรอกชื่อ";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Last Name
                    const Text(
                      "นามสกุล",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "กรุณากรอกนามสกุล";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    const Text(
                      "เพศ",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "ชาย", child: Text("ชาย")),
                        DropdownMenuItem(value: "หญิง", child: Text("หญิง")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                          _isGenderError = false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Birthday
                    const Text(
                      "วันเกิด",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: birthdayController,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                _isBirthdayError
                                    ? Colors.red
                                    : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                _isBirthdayError
                                    ? Colors.red
                                    : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                        hintText:
                            "เลือกวันเกิด (อายุต้องมากกว่า 15 ปี)", // ✅ เพิ่ม hint
                      ),
                      onTap: _selectDate,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "กรุณาเลือกวันเกิด";
                        }
                        if (!isValidAge(value)) {
                          final age = calculateAge(value);
                          return age != null
                              ? "อายุของคุณ $age ปี ต้องมีอายุมากกว่า 15 ปี"
                              : "วันเกิดไม่ถูกต้อง";
                        }
                        return null;
                      },
                    ),
                    // ✅ แสดงอายุปัจจุบัน
                    if (birthdayController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isValidAge(birthdayController.text)
                                  ? AppTheme.surfaceColor
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isValidAge(birthdayController.text)
                                    ? AppTheme.borderColor
                                    : Colors.red,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isValidAge(birthdayController.text)
                                  ? Icons.check_circle
                                  : Icons.error,
                              size: 16,
                              color:
                                  isValidAge(birthdayController.text)
                                      ? AppTheme.primaryColor
                                      : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "อายุของคุณ: ${calculateAge(birthdayController.text)} ปี",
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isValidAge(birthdayController.text)
                                        ? AppTheme.primaryColor
                                        : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // ✅ Address with Map Picker (ปรับปรุงใหม่)
                    const Text(
                      "ที่อยู่",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: addressController,
                      maxLines: 3,
                      readOnly: true, // ✅ ป้องกันการพิมพ์โดยตรง
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        hintText: 'แตะปุ่มเพื่อเลือกตำแหน่งจากแผนที่',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ Loading indicator เมื่อกำลังแปลงที่อยู่
                            if (addressController.text ==
                                'กำลังค้นหาที่อยู่...')
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.map,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: _selectLocation,
                              tooltip: 'เลือกจากแผนที่',
                            ),
                          ],
                        ),
                      ),
                      onTap: _selectLocation, // ✅ แตะช่องเพื่อเปิดแผนที่
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value == 'กำลังค้นหาที่อยู่...') {
                          return "กรุณาเลือกที่อยู่จากแผนที่";
                        }
                        return null;
                      },
                    ),

                    // ✅ แสดงข้อมูลตำแหน่งและสถานะการแปลง
                    if (selectedPosition != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppTheme.primaryColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "พิกัด: ${selectedPosition!.latitude.toStringAsFixed(6)}, ${selectedPosition!.longitude.toStringAsFixed(6)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // ✅ แสดงสถานะการแปลงที่อยู่
                            if (addressController.text.isNotEmpty &&
                                addressController.text !=
                                    'กำลังค้นหาที่อยู่...') ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    addressController.text.startsWith('พิกัด:')
                                        ? Icons.warning_amber
                                        : Icons.check_circle,
                                    color:
                                        addressController.text.startsWith(
                                              'พิกัด:',
                                            )
                                            ? Colors.orange
                                            : AppTheme.primaryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      addressController.text.startsWith(
                                            'พิกัด:',
                                          )
                                          ? 'ใช้พิกัดแทนที่อยู่'
                                          : 'แปลงเป็นที่อยู่สำเร็จ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            addressController.text.startsWith(
                                                  'พิกัด:',
                                                )
                                                ? Colors.orange
                                                : AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Phone
                    const Text(
                      "เบอร์โทร",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: telController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        hintText: "เช่น 0812345678",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "กรุณากรอกเบอร์โทร";
                        }
                        if (!isValidPhone(value)) {
                          return "เบอร์โทรต้องขึ้นต้นด้วย 06, 07, 08, หรือ 09 และมี 10 หลัก";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    const Text(
                      "รหัสผ่าน",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        hintText:
                            "รหัสผ่าน 6-50 ตัวอักษร", // ✅ เปลี่ยน hint text
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "กรุณากรอกรหัสผ่าน";
                        }
                        // ✅ เปลี่ยนเงื่อนไขความยาวรหัสผ่าน
                        if (value.length < 6) {
                          return "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร";
                        }
                        if (value.length > 50) {
                          // ✅ เปลี่ยนจาก 33 เป็น 50
                          return "รหัสผ่านต้องไม่เกิน 50 ตัวอักษร";
                        }
                        return null;
                      },
                    ),

                    // ✅ เพิ่มแสดงจำนวนตัวอักษรปัจจุบัน
                    if (passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getPasswordStrengthColor(
                            passwordController.text.length,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getPasswordStrengthColor(
                              passwordController.text.length,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getPasswordStrengthIcon(
                                passwordController.text.length,
                              ),
                              size: 16,
                              color: _getPasswordStrengthColor(
                                passwordController.text.length,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "ความยาว: ${passwordController.text.length}/50 ตัวอักษร", // ✅ เปลี่ยนจาก 33 เป็น 50
                              style: TextStyle(
                                fontSize: 12,
                                color: _getPasswordStrengthColor(
                                  passwordController.text.length,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _getPasswordStrengthText(
                                passwordController.text.length,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getPasswordStrengthColor(
                                  passwordController.text.length,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Confirm Password
                    const Text(
                      "ยืนยันรหัสผ่าน",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "กรุณายืนยันรหัสผ่าน";
                        }
                        if (value != passwordController.text) {
                          return "รหัสผ่านไม่ตรงกัน";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saveUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          "สมัครสมาชิก",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }
}
