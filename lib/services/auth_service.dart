import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthResponse {
  final bool success;
  final String message;
  final User? user;
  final String? token;

  AuthResponse({
    required this.success,
    required this.message,
    this.user,
    this.token,
  });
}

class AuthService {
  // 注册用户
  static Future<AuthResponse> register({
    required String username,
    required String password,
    required String email,
    required String userType,
    required String userProfile,
    File? avatarFile, // 保留参数，但不再使用
    String imageUrl = "https://image/214514", // 默认头像URL
  }) async {
    try {
      // 获取用户类型的整数值
      int userTypeValue = AppConstants.userTypeValues[userType] ?? 1; // 默认为员工
      
      // 显示完整的URL，用于调试
      debugPrint('正在请求URL: ${AppConstants.registerEndpoint}');
      
      // 创建请求（改为普通的POST请求，不再需要multipart）
      var uri = Uri.parse(AppConstants.registerEndpoint);
      var requestBody = {
        'username': username,
        'password': password,
        'email': email,
        'userType': userTypeValue.toString(),
        'userProfile': userProfile,
        'imageUrl': imageUrl,
      };

      // 打印请求体，用于调试
      debugPrint('请求体: $requestBody');

      // 发送请求
      debugPrint('发送请求...');
      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      debugPrint('收到响应，状态码: ${response.statusCode}');
      debugPrint('响应体: ${response.body}');

      // 解析响应
      try {
        var responseData = json.decode(response.body);
        
        // 检查响应是否成功
        bool isSuccess = responseData['success'] == true;
        int code = responseData['code'] ?? 0;
        String message = responseData['message'] ?? '未知消息';
        
        // code为200表示成功
        if (isSuccess && code == 200) {
          // 如果data为null，就创建一个简单的用户对象
          User user;
          if (responseData['data'] == null) {
            // 创建一个包含注册信息的用户对象
            user = User(
              username: username,
              email: email,
              userType: userType,
              userProfile: userProfile,
              imageUrl: imageUrl,
            );
          } else {
            // 如果data不为null，从data中解析用户信息
            user = User.fromJson(responseData['data']);
          }
          
          return AuthResponse(
            success: true,
            message: message,
            user: user,
            token: responseData['token'], // token可能为null
          );
        } else {
          return AuthResponse(
            success: false,
            message: message,
          );
        }
      } catch (e) {
        debugPrint('解析响应时出错: $e');
        return AuthResponse(
          success: false,
          message: '解析响应失败: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('注册过程中发生错误: $e');
      return AuthResponse(
        success: false,
        message: '${AppConstants.networkErrorMessage}. 错误详情: $e',
      );
    }
  }

  // 保存用户信息和token到本地存储
  static Future<void> saveUserAndToken(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, json.encode(user.toJson()));
    await prefs.setString(AppConstants.tokenKey, token);
  }
} 