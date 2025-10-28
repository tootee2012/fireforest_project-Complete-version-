import 'package:fireforest_project/screens/admin_home.dart';
import 'package:fireforest_project/service.dart';
import 'package:flutter/material.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RecruitVolunteerPage extends StatefulWidget {
  final String agencyEmail;
  const RecruitVolunteerPage({super.key, required this.agencyEmail});

  @override
  State<RecruitVolunteerPage> createState() => _RecruitVolunteerPageState();
}

class _RecruitVolunteerPageState extends State<RecruitVolunteerPage>
    with TickerProviderStateMixin {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController maxNumberController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Service service = Service();
  final _formKey = GlobalKey<FormState>();

  // ✅ เพิ่ม Animation Controller เหมือน home
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      // ✅ เพิ่ม Theme สำหรับ DatePicker
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2E2E2E),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() &&
        startDateController.text.isNotEmpty &&
        endDateController.text.isNotEmpty) {
      final inputDate1 = startDateController.text;
      final parsedDate1 = DateFormat("dd/MM/yyyy").parse(inputDate1);
      final formattedDate1 = DateFormat("yyyy-MM-dd").format(parsedDate1);

      final inputDate2 = endDateController.text;
      final parsedDate2 = DateFormat("dd/MM/yyyy").parse(inputDate2);
      final formattedDate2 = DateFormat("yyyy-MM-dd").format(parsedDate2);
      int max = int.parse(maxNumberController.text);

      // ✅ แก้ไข SnackBar ให้สวยขึ้น
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
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'บันทึกข้อมูลเรียบร้อย',
                style: TextStyle(
                  fontFamily: 'Kanit',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      service.saveRecruitForm(
        formattedDate1,
        formattedDate2,
        max,
        descriptionController.text,
        locationController.text,
        widget.agencyEmail,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Adminhome(agencyEmail: widget.agencyEmail),
        ),
      );
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
          'เปิดรับอาสาสมัคร',
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ✅ เพิ่ม Welcome Header Card เหมือน home
                _buildWelcomeCard(),

                const SizedBox(height: 24),

                // ✅ แก้ไข Form Container ให้สวยขึ้น
                Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.group_add_rounded,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ข้อมูลการรับสมัคร',
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

                      // Form Fields
                      _buildTextField(
                        controller: locationController,
                        hint: 'ระบุพื้นที่',
                        label: 'พื้นที่',
                        icon: Icons.location_on_rounded,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'กรุณาระบุพื้นที่' : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: startDateController,
                        hint: 'เลือกวันที่เปิดรับสมัคร',
                        label: 'วันที่เปิดรับสมัคร',
                        icon: Icons.calendar_today_rounded,
                        readOnly: true,
                        onTap: () => _selectDate(startDateController),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'กรุณาเลือกวันที่เปิดรับ'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: endDateController,
                        hint: 'เลือกวันที่ปิดรับสมัคร',
                        label: 'วันที่ปิดรับสมัคร',
                        icon: Icons.event_busy_rounded,
                        readOnly: true,
                        onTap: () => _selectDate(endDateController),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'กรุณาเลือกวันที่ปิดรับ'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: maxNumberController,
                        hint: 'จำนวนอาสาสมัครที่ต้องการ',
                        label: 'จำนวน',
                        icon: Icons.people_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator:
                            (value) => value!.isEmpty ? 'กรุณาระบุจำนวน' : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: descriptionController,
                        hint: 'รายละเอียดการรับสมัครอาสาสมัคร',
                        label: 'รายละเอียด',
                        icon: Icons.description_rounded,
                        maxLines: 4,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'กรุณาระบุรายละเอียด' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ แก้ไขปุ่มให้สวยขึ้น
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _submitForm,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'เปิดรับสมัคร',
                          style: TextStyle(
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
                ),

                const SizedBox(height: 16),
              ],
            ),
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
              Icons.group_add_rounded,
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
                  'สร้างโครงการใหม่',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 16,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  'เปิดรับอาสาสมัคร',
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
                  'Agency: ${widget.agencyEmail}',
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

  // ✅ แก้ไข TextField ให้สวยขึ้น
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Kanit',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            validator: validator,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 16,
              color: Color(0xFF2E2E2E),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 14,
                color: Colors.grey[500],
              ),
              prefixIcon:
                  icon != null
                      ? Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      )
                      : null,
              filled: true,
              fillColor: AppTheme.surfaceColor,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
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
            ),
          ),
        ),
      ],
    );
  }
}
