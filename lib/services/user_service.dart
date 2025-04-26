import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import '../utils/config.dart';
import '../utils/http_utils.dart';

class UserProfileResponse {
  final bool success;
  final String message;
  final User? user;

  UserProfileResponse({
    required this.success,
    required this.message,
    this.user,
  });
}

class UserResponse {
  final bool success;
  final String message;
  final User? user;

  UserResponse({
    required this.success,
    required this.message,
    this.user,
  });
}

class UserService {
  // 获取当前登录用户的个人信息
  static Future<UserProfileResponse> getUserProfile() async {
    try {
      // 获取用户ID
      final userId = await AuthService.getUserId();
      
      if (userId == null) {
        return UserProfileResponse(
          success: false,
          message: '无法获取用户ID',
        );
      }

      debugPrint('发送获取用户信息请求: userId=$userId');

      // 使用HttpUtils工具类发送请求
      final response = await HttpUtils.get('${AppConstants.userProfileEndpoint}/$userId');

      debugPrint('用户信息响应状态码: ${response.statusCode}');

      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          final Map<String, dynamic> data = responseData['data'];
          
          try {
            // 为了保持一致性，需要添加id到data中
            data['id'] = userId;
            
            final user = User.fromJson(data);
            
            debugPrint('成功获取用户信息: ${user.username}');
            
            return UserProfileResponse(
              success: true,
              message: message,
              user: user,
            );
          } catch (e) {
            debugPrint('解析用户数据出错: $e');
            return UserProfileResponse(
              success: false,
              message: '解析用户数据失败: $e',
            );
          }
        } else {
          debugPrint('获取用户信息失败: $message');
          return UserProfileResponse(
            success: false,
            message: message,
          );
        }
      } catch (e) {
        debugPrint('解析用户信息响应出错: $e');
        return UserProfileResponse(
          success: false,
          message: '解析响应数据失败: $e',
        );
      }
    } catch (e) {
      debugPrint('获取用户信息过程中发生错误: $e');
      return UserProfileResponse(
        success: false,
        message: '网络请求失败: $e',
      );
    }
  }

  // 根据用户ID获取用户信息
  static Future<UserProfileResponse> getUserById(int userId) async {
    try {
      debugPrint('发送获取指定用户信息请求: userId=$userId');

      // 使用HttpUtils工具类发送请求
      final response = await HttpUtils.get('${AppConstants.userProfileEndpoint}/$userId');

      debugPrint('指定用户信息响应状态码: ${response.statusCode}');

      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          final Map<String, dynamic> data = responseData['data'];
          
          try {
            // 为了保持一致性，需要添加id到data中
            data['id'] = userId.toString();
            
            final user = User.fromJson(data);
            
            debugPrint('成功获取指定用户信息: ${user.username}');
            
            return UserProfileResponse(
              success: true,
              message: message,
              user: user,
            );
          } catch (e) {
            debugPrint('解析指定用户数据出错: $e');
            return UserProfileResponse(
              success: false,
              message: '解析用户数据失败: $e',
            );
          }
        } else {
          debugPrint('获取指定用户信息失败: $message');
          return UserProfileResponse(
            success: false,
            message: message,
          );
        }
      } catch (e) {
        debugPrint('解析指定用户信息响应出错: $e');
        return UserProfileResponse(
          success: false,
          message: '解析响应数据失败: $e',
        );
      }
    } catch (e) {
      debugPrint('获取指定用户信息过程中发生错误: $e');
      return UserProfileResponse(
        success: false,
        message: '网络请求失败: $e',
      );
    }
  }

  // 获取项目经理列表
  static Future<List<User>> getProjectManagers() async {
    try {
      final response = await HttpUtils.get('users/managers');

      final responseData = HttpUtils.parseResponse(response);

      if (HttpUtils.isSuccessful(responseData)) {
        final List<dynamic> managersJson = responseData['data'];
        return managersJson.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception(HttpUtils.getErrorMessage(responseData));
      }
    } catch (e) {
      throw Exception('获取项目经理列表失败: $e');
    }
  }
  
  // 获取所有用户列表（可选分页）
  static Future<List<User>> getUsers({int page = 1, int pageSize = 20}) async {
    try {
      final response = await HttpUtils.get('users', queryParams: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      });

      final responseData = HttpUtils.parseResponse(response);

      if (HttpUtils.isSuccessful(responseData)) {
        final List<dynamic> usersJson = responseData['data'];
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception(HttpUtils.getErrorMessage(responseData));
      }
    } catch (e) {
      throw Exception('获取用户列表失败: $e');
    }
  }
}

// 帮助函数：取较小值
int min(int a, int b) {
  return a < b ? a : b;
} 