import 'package:fireforest_project/screens/login.dart';
import 'package:fireforest_project/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // สำหรับ locale ไทย

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // โหลด locale ไทยสำหรับ intl
  await initializeDateFormatting('th');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ซ่อน debug banner
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Login()),
    );
  }
}
