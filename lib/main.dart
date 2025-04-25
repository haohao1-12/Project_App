import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'utils/theme.dart';
import 'screens/login_screen.dart';

void main() {
  // 设置HTTP请求的默认编码
  http.Client client = http.Client();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '项目管理系统',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
