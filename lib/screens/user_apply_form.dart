import 'package:fireforest_project/screens/home.dart';
import 'package:fireforest_project/service.dart';
import 'package:fireforest_project/model/volunteer_model.dart'; // ✅ เพิ่ม import
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';

class ApplyForm extends StatefulWidget {
  final String userEmail;
  final int recruitId;
  const ApplyForm({
    super.key,
    required this.userEmail,
    required this.recruitId,
  });

  @override
  State<ApplyForm> createState() => _ApplyFormState();
}

class _ApplyFormState extends State<ApplyForm> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  TextEditingController weightController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController allergiesController = TextEditingController();
  TextEditingController diseasesController = TextEditingController();
  TextEditingController specialSkillsController = TextEditingController();
  String hasTraining = 'ไม่เคย';
  final List<String> trainingOptions = ['เคย', 'ไม่เคย'];

  // ✅ เพิ่ม Animation Controller เหมือน home
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ✅ เพิ่มตัวแปรสำหรับโหลดข้อมูลเดิม
  bool isLoadingExistingData = true;
  VolunteerModel? existingVolunteer;
  String? dataSourceMessage;

  @override
  void initState() {
    super.initState();

    // ✅ เพิ่ม Animation Setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // ✅ โหลดข้อมูลเดิมของผู้ใช้
    _loadExistingVolunteerData();

    _animationController.forward();
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    allergiesController.dispose();
    diseasesController.dispose();
    specialSkillsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ ฟังก์ชันโหลดข้อมูลเดิมของอาสาสมัคร
  Future<void> _loadExistingVolunteerData() async {
    try {
      print('🔍 Loading existing volunteer data for: ${widget.userEmail}');

      // ดึงข้อมูลอาสาสมัครที่มีอยู่
      final volunteer = await Service().getVolunteerByEmail(widget.userEmail);

      if (volunteer != null) {
        print('✅ Found existing volunteer data');
        print('   Status: ${volunteer.volunteerStatus}');
        print('   Weight: ${volunteer.weight}');
        print('   Height: ${volunteer.height}');
        print('   Talent: ${volunteer.talent}');
        print('   Training: ${volunteer.isTraining}');

        // ตรวจสอบสถานะ - ถ้าไม่ผ่านการคัดเลือกหรือยังรอการตรวจสอบ ให้ใช้ข้อมูลเดิม
        if (volunteer.volunteerStatus == 'ไม่ผ่านการคัดเลือก' ||
            volunteer.volunteerStatus == 'รอการตรวจสอบ') {
          setState(() {
            existingVolunteer = volunteer;

            // ✅ เซ็ตข้อมูลเดิมลงใน form
            weightController.text = volunteer.weight.toString();
            heightController.text = volunteer.height.toString();
            specialSkillsController.text = volunteer.talent ?? '';
            hasTraining = volunteer.isTraining ? 'เคย' : 'ไม่เคย';

            // ✅ เซ็ตข้อมูลจาก applyForm ถ้ามี
            if (volunteer.applyForm != null) {
              String allergicFood = volunteer.applyForm!.allergicFood ?? '';
              String congenitalDiseases =
                  volunteer.applyForm!.congenitalDiseases ?? '';

              // แปลง "none" เป็นช่องว่าง
              allergiesController.text =
                  (allergicFood.toLowerCase() == 'none') ? '' : allergicFood;
              diseasesController.text =
                  (congenitalDiseases.toLowerCase() == 'none')
                      ? ''
                      : congenitalDiseases;
            }

            // กำหนดข้อความแสดงสถานะ
            if (volunteer.volunteerStatus == 'ไม่ผ่านการคัดเลือก') {
              dataSourceMessage =
                  'ดึงข้อมูลจากการสมัครครั้งที่แล้ว (ไม่ผ่านการคัดเลือก)';
            } else {
              dataSourceMessage =
                  'ดึงข้อมูลจากการสมัครครั้งที่แล้ว (รอการตรวจสอบ)';
            }

            isLoadingExistingData = false;
          });

          print('✅ Pre-filled form with existing data');
        } else {
          // ถ้าผ่านการคัดเลือกแล้ว ให้แสดงข้อความ
          setState(() {
            dataSourceMessage =
                'คุณได้ผ่านการคัดเลือกแล้ว ไม่สามารถสมัครใหม่ได้';
            isLoadingExistingData = false;
          });
          print('ℹ️ User already passed selection');
        }
      } else {
        // ไม่เคยสมัครมาก่อน
        setState(() {
          dataSourceMessage = 'การสมัครครั้งแรก';
          isLoadingExistingData = false;
        });
        print('ℹ️ No existing volunteer data found - first time application');
      }
    } catch (e) {
      print('❌ Error loading existing volunteer data: $e');
      setState(() {
        dataSourceMessage = 'ไม่สามารถดึงข้อมูลเดิมได้ กรุณากรอกข้อมูลใหม่';
        isLoadingExistingData = false;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // ✅ ไม่ต้อง check null เพราะมี default value แล้ว

      // ✅ แสดงข้อความส่งข้อมูลเสร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "ส่งข้อมูลการสมัครเรียบร้อย",
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // TODO: ส่งข้อมูลไป API
      print('=== ข้อมูลที่จะส่ง ===');
      print('User Email: ${widget.userEmail}');
      print('Recruit ID: ${widget.recruitId}');
      print('Weight: ${weightController.text}');
      print('Height: ${heightController.text}');
      print('Allergies: ${allergiesController.text}');
      print('Diseases: ${diseasesController.text}');
      print('Special Skills: ${specialSkillsController.text}');
      print('Has Training: $hasTraining');

      bool train = hasTraining == "เคย";
      double weight = double.parse(weightController.text);
      double height = double.parse(heightController.text);

      String allergies =
          allergiesController.text.isEmpty ? "none" : allergiesController.text;
      String diseases =
          diseasesController.text.isEmpty ? "none" : diseasesController.text;

      print('Final Allergies: $allergies');
      print('Final Diseases: $diseases');
      print('Final Training: $train');

      Service().saveApplyFormWithVolunteer(
        diseases,
        allergies,
        widget.recruitId,
        widget.userEmail,
        weight,
        height,
        specialSkillsController.text,
        train,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(userEmail: widget.userEmail),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          existingVolunteer != null ? 'แก้ไขข้อมูลการสมัคร' : 'สมัครอาสาสมัคร',
          style: const TextStyle(
            fontFamily: 'Kanit',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // ✅ แก้ไข Welcome Header Card
              _buildWelcomeCard(),

              const SizedBox(height: 16),

              // ✅ เพิ่ม Status Card
              if (dataSourceMessage != null) _buildStatusCard(),

              const SizedBox(height: 24),

              // ✅ แสดง Loading หรือ Form
              if (isLoadingExistingData)
                _buildLoadingCard()
              else
                _buildFormContainer(),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ แก้ไข Welcome Card
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
              gradient: LinearGradient(
                colors:
                    existingVolunteer != null
                        ? [const Color(0xFFFF9800), const Color(0xFFFFC107)]
                        : [AppTheme.primaryColor, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              existingVolunteer != null
                  ? Icons.edit_rounded
                  : Icons.assignment_ind_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existingVolunteer != null ? 'แก้ไขข้อมูล' : 'กรอกข้อมูล',
                  style: const TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  existingVolunteer != null
                      ? 'การสมัครอาสาสมัคร'
                      : 'การสมัครอาสาสมัคร',
                  style: const TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  existingVolunteer != null
                      ? 'แก้ไขข้อมูลและส่งใหม่'
                      : 'กรุณากรอกข้อมูลให้ครบถ้วน',
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
        ],
      ),
    );
  }

  // ✅ เพิ่ม Status Card
  Widget _buildStatusCard() {
    Color cardColor;
    Color iconColor;
    IconData icon;

    if (dataSourceMessage!.contains('ไม่ผ่านการคัดเลือก')) {
      cardColor = Colors.orange.withOpacity(0.1);
      iconColor = Colors.orange;
      icon = Icons.refresh_rounded;
    } else if (dataSourceMessage!.contains('รอการตรวจสอบ')) {
      cardColor = Colors.blue.withOpacity(0.1);
      iconColor = Colors.blue;
      icon = Icons.pending_rounded;
    } else if (dataSourceMessage!.contains('ผ่านการคัดเลือก')) {
      cardColor = Colors.red.withOpacity(0.1);
      iconColor = Colors.red;
      icon = Icons.block_rounded;
    } else {
      cardColor = AppTheme.success.withOpacity(0.1);
      iconColor = AppTheme.success;
      icon = Icons.new_releases_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dataSourceMessage!,
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 14,
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ เพิ่ม Loading Card
  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
      child: const Column(
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'กำลังตรวจสอบข้อมูลเดิม...',
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 16,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ แก้ไข Submit Button
  Widget _buildSubmitButton() {
    String buttonText =
        existingVolunteer != null ? 'อัปเดตข้อมูลการสมัคร' : 'ส่งใบสมัคร';

    IconData buttonIcon =
        existingVolunteer != null ? Icons.update_rounded : Icons.send_rounded;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              existingVolunteer != null
                  ? [const Color(0xFFFF9800), const Color(0xFFFFC107)]
                  : [AppTheme.primaryColor, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (existingVolunteer != null
                    ? const Color(0xFFFF9800)
                    : AppTheme.primaryColor)
                .withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(buttonIcon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              buttonText,
              style: const TextStyle(
                fontFamily: 'Kanit',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (เก็บ methods อื่นๆ เหมือนเดิม)
  Widget _buildFormContainer() {
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ข้อมูลส่วนตัว',
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

              const SizedBox(height: 24),

              // น้ำหนัก
              _buildTextField(
                controller: weightController,
                label: "น้ำหนัก (กิโลกรัม)",
                hint: "ระบุน้ำหนักของคุณ",
                icon: Icons.monitor_weight_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "กรุณาระบุน้ำหนัก";
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return "กรุณาระบุน้ำหนักที่ถูกต้อง";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ส่วนสูง
              _buildTextField(
                controller: heightController,
                label: "ส่วนสูง (เซนติเมตร)",
                hint: "ระบุส่วนสูงของคุณ",
                icon: Icons.height_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "กรุณาระบุส่วนสูง";
                  }
                  final height = double.tryParse(value);
                  if (height == null || height <= 0) {
                    return "กรุณาระบุส่วนสูงที่ถูกต้อง";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // อาหารที่แพ้
              _buildTextField(
                controller: allergiesController,
                label: "อาหารที่แพ้",
                hint: "ระบุอาหารที่แพ้ หากไม่มีสามารถเว้นว่างได้",
                icon: Icons.no_food_rounded,
                isOptional: true,
              ),

              const SizedBox(height: 20),

              // โรคประจำตัว
              _buildTextField(
                controller: diseasesController,
                label: "โรคประจำตัว",
                hint: "ระบุโรคประจำตัว หากไม่มีสามารถเว้นว่างได้",
                icon: Icons.medical_services_rounded,
                isOptional: true,
              ),

              const SizedBox(height: 20),

              // ความสามารถเฉพาะตัว
              _buildTextField(
                controller: specialSkillsController,
                label: "ความสามารถเฉพาะตัว",
                hint: "ระบุความสามารถหรือทักษะของคุณ",
                icon: Icons.star_rounded,
                maxLines: 3,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? "กรุณาระบุความสามารถเฉพาะตัว"
                            : null,
              ),

              const SizedBox(height: 20),

              // เคยผ่านการอบรมหรือไม่
              _buildDropdownField(),

              const SizedBox(height: 32),

              // ปุ่มสมัคร
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ สร้าง TextField สวยงาม
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isOptional = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Kanit',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
            if (isOptional)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ไม่จำเป็น',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Sarabun',
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 16,
            color: Color(0xFF2E2E2E),
          ),
        ),
      ],
    );
  }

  // ✅ สร้าง Dropdown Field สวยงาม
  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.school_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'ประสบการณ์การอบรม',
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: hasTraining,
          items:
              trainingOptions
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 16,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                    ),
                  )
                  .toList(),
          decoration: InputDecoration(
            hintText: "เลือกประสบการณ์การอบรม",
            hintStyle: TextStyle(
              fontFamily: 'Sarabun',
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (value) => setState(() => hasTraining = value!),
        ),
      ],
    );
  }
}

