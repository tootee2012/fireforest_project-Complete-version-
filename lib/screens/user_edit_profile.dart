import 'package:fireforest_project/screens/home.dart';
import 'package:fireforest_project/service.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  final String email; // รับ email ที่ login มา

  const EditProfilePage({super.key, required this.email});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _telController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Service service = Service();
  String? userId;

  @override
  void initState() {
    super.initState();
    service = Service();
    _loadUser();
  }

  void _loadUser() async {
    var user = await service.getUserByEmail(widget.email);
    print("User data: $user");
    if (user != null) {
      setState(() {
        userId = user["userEmail"].toString();
        _fnameController.text = user["userFname"] ?? "";
        _lnameController.text = user["userLname"] ?? "";
        _genderController.text = user["userGender"] ?? "";
        _addressController.text = user["userAddress"] ?? "";
        _telController.text = user["userTel"] ?? "";
        _passwordController.text = user["userPassword"] ?? "";
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("รหัสผ่านไม่ตรงกัน")));
        return;
      }

      if (userId == null) return;

      var data = {
        "userFname": _fnameController.text,
        "userLname": _lnameController.text,
        "userGender": _genderController.text,
        "userAddress": _addressController.text,
        "userTel": _telController.text,
        "userPassword": _passwordController.text,
      };

      bool success = await service.updateUser(userId!, data);

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("แก้ไขข้อมูลเรียบร้อย")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userEmail: widget.email),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("แก้ไขไม่สำเร็จ")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, // สีพื้นหลังเขียวอ่อน
      appBar: AppBar(
        title: const Text(
          "แก้ไขข้อมูลส่วนตัวของคุณ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor, // สี AppBar เขียวมะกอก
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  "ข้อมูลส่วนตัว",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fnameController,
                  decoration: const InputDecoration(
                    labelText: "ชื่อจริง",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator:
                      (value) => value!.isEmpty ? "กรุณากรอกชื่อจริง" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lnameController,
                  decoration: const InputDecoration(
                    labelText: "นามสกุล",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator:
                      (value) => value!.isEmpty ? "กรุณากรอกนามสกุล" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _genderController,
                  decoration: const InputDecoration(
                    labelText: "เพศ",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wc),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: "ที่อยู่",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telController,
                  decoration: const InputDecoration(
                    labelText: "เบอร์โทรศัพท์",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "รหัสผ่าน",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "ยืนยันรหัสผ่าน",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "แก้ไขข้อมูล",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
