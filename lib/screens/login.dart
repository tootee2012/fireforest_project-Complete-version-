import 'dart:convert';
import 'package:fireforest_project/screens/home.dart';
import 'package:fireforest_project/screens/register.dart';
import 'package:fireforest_project/screens/admin_home.dart'; // เพิ่ม import สำหรับ admin home
import 'package:fireforest_project/service.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/boxs/userlog.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  Service service = Service();

  bool _obscurePassword = true; // 👁️ toggle password
  bool _isButtonEnabled = false; // ✅ enable/disable login button

  @override
  void initState() {
    super.initState();
    // ฟังการเปลี่ยนแปลงของ TextField เพื่ออัปเดตสถานะปุ่ม
    emailController.addListener(_updateButtonState);
    passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled =
          emailController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // ✅ ไล่สีขาว → ส้มอ่อน → ส้มเล็กน้อย
            colors: [
              Color(0xFFFFFFFF), // ขาวบริสุทธิ์
              Color(0xFFFFF8F0), // ขาวครีม
              Color(0xFFFFE4B5), // ส้มอ่อนมาก
              Color(0xFFFFD4A3), // ส้มอ่อน
              Color(0xFFFFCC91), // ส้มเล็กน้อย
            ],
            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Logo - เปลี่ยนไอคอนและสี
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.0,
                        colors: [
                          Colors.white,
                          Colors.orange[50]!,
                          Colors.orange[100]!,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          spreadRadius: 3,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(-2, -2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      size: 50,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'แอปแจ้งเหตุไฟป่า',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF5722), // ✅ ส้มแดงให้เข้ากับปุ่ม
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ป้องกันและเฝ้าระวังไฟป่า',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[800],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email field
                  TextFormField(
                    controller: emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกอีเมล';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email, color: Colors.orange[700]),
                      hintText: "email@domain.com",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      labelText: "อีเมล",
                      labelStyle: TextStyle(color: Colors.orange[800]),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.95),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.orange[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.orange[200]!,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.orange[700]!,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password field with eye icon
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock, color: Colors.orange[700]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.orange[700],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      hintText: "••••••••",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      labelText: "รหัสผ่าน",
                      labelStyle: TextStyle(color: Colors.orange[800]),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.95),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.orange[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.orange[200]!,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.orange[700]!,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login button - เปลี่ยนสีเป็นส้มเข้ม
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isButtonEnabled
                              ? () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    // 1. ลองเช็ค User ก่อน
                                    var userRes = await service.loginUser(
                                      emailController.text,
                                      passwordController.text,
                                    );
                                    var email = emailController.text;

                                    if (userRes.statusCode == 200) {
                                      // ✅ Login สำเร็จด้วยบัญชี User
                                      try {
                                        var jsonRes = jsonDecode(userRes.body);
                                        print("User Login Success: $jsonRes");

                                        UserLog().username =
                                            emailController.text;

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => HomePage(
                                                  userEmail: "$email",
                                                ),
                                          ),
                                        );
                                        return; // ออกจากฟังก์ชัน
                                      } catch (e) {
                                        print("User JSON Parse Error: $e");
                                        print("Response Body: ${userRes.body}");
                                        // ถึงแม้ JSON ผิด แต่ status 200 แสดงว่า login สำเร็จ
                                        UserLog().username =
                                            emailController.text;
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => HomePage(
                                                  userEmail: "$email",
                                                ),
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    // 2. หาก User ล็อกอินไม่ได้ ให้ลองเช็ค Admin
                                    var adminRes = await service.loginAgency(
                                      emailController.text,
                                      passwordController.text,
                                    );

                                    if (adminRes.statusCode == 200) {
                                      // ✅ Login สำเร็จด้วยบัญชี Admin
                                      try {
                                        var jsonRes = jsonDecode(adminRes.body);
                                        print("Admin Login Success: $jsonRes");

                                        UserLog().username =
                                            emailController.text;

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => Adminhome(
                                                  agencyEmail: "$email",
                                                ),
                                          ),
                                        );
                                      } catch (e) {
                                        print("Admin JSON Parse Error: $e");
                                        print(
                                          "Response Body Length: ${adminRes.body.length}",
                                        );
                                        print(
                                          "Response Body Preview: ${adminRes.body.substring(0, 500)}...",
                                        );

                                        // ถึงแม้ JSON ผิด แต่ status 200 แสดงว่า login สำเร็จ
                                        UserLog().username =
                                            emailController.text;
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => Adminhome(
                                                  agencyEmail: "$email",
                                                ),
                                          ),
                                        );
                                      }
                                    } else {
                                      // ❌ ทั้งสองตารางล็อกอินไม่ได้
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "อีเมลหรือรหัสผ่านไม่ถูกต้อง",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    // ❌ กรณีเกิดข้อผิดพลาดในการเชื่อมต่อ
                                    print("Login Error: $e");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "เกิดข้อผิดพลาดในการเชื่อมต่อ กรุณาลองใหม่อีกครั้ง",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                              : null, // ❌ disable ปุ่มเมื่อข้อมูลไม่ครบ
                      style: ElevatedButton.styleFrom(
                        // ✅ ปุ่มโปร่งใสเพื่อใช้ gradient
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ).copyWith(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>((
                              Set<MaterialState> states,
                            ) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey[300]!;
                              }
                              return Colors.transparent;
                            }),
                      ),
                      child: Container(
                        decoration:
                            _isButtonEnabled
                                ? BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF9800), // ส้มกลาง
                                      Color(0xFFFF7043), // ส้มแซ่มอน
                                      Color(0xFFFF5722), // ส้มแดง
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFFF9800).withOpacity(0.4),
                                      spreadRadius: 1,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                )
                                : BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(15),
                                ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Center(
                          child: Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Forgot password
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "หากยังไม่มีบัญชี",
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Register button - เปลี่ยนสีขอบเป็นส้มอ่อน
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        // ✅ ปุ่มสมัครสมาชิกสวยขึ้น
                        side: BorderSide(
                          color: Colors.orange[600]!,
                          width: 2.5,
                        ),
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.orange[50]!.withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'สมัครสมาชิก',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
