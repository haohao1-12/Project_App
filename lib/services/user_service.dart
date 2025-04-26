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
      // 获取认证令牌和用户ID
      final token = await AuthService.getToken();
      final userId = await AuthService.getUserId();
      
      if (token == null) {
        return UserProfileResponse(
          success: false,
          message: '未登录，请先登录',
        );
      }
      
      if (userId == null) {
        return UserProfileResponse(
          success: false,
          message: '无法获取用户ID',
        );
      }

      // 构建请求URL
      final url = Uri.parse('${AppConstants.userProfileEndpoint}/$userId');

      // 请求头中包含令牌
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'Accept-Charset': 'utf-8',
        'token': token,
      };

      debugPrint('发送获取用户信息请求: userId=$userId');

      // 发送请求
      final response = await http.get(
        url,
        headers: headers,
      );

      debugPrint('用户信息响应状态码: ${response.statusCode}');

      // 解码响应体
      String responseBody;
      try {
        responseBody = utf8.decode(response.bodyBytes);
        debugPrint('用户信息响应体(部分): ${responseBody.substring(0, min(200, responseBody.length))}...');
      } catch (e) {
        debugPrint('解码响应体失败: $e');
        responseBody = response.body;
      }

      // 解析响应
      try {
        final Map<String, dynamic> responseData = json.decode(responseBody);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (success && responseData['code'] == 200) {
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
      // 获取认证令牌
      final token = await AuthService.getToken();
      
      if (token == null) {
        return UserProfileResponse(
          success: false,
          message: '未登录，请先登录',
        );
      }

      // 构建请求URL
      final url = Uri.parse('${AppConstants.userProfileEndpoint}/$userId');

      // 请求头中包含令牌
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'Accept-Charset': 'utf-8',
        'token': token,
      };

      debugPrint('发送获取指定用户信息请求: userId=$userId');

      // 发送请求
      final response = await http.get(
        url,
        headers: headers,
      );

      debugPrint('指定用户信息响应状态码: ${response.statusCode}');

      // 解码响应体
      String responseBody;
      try {
        responseBody = utf8.decode(response.bodyBytes);
        debugPrint('指定用户信息响应体(部分): ${responseBody.substring(0, min(200, responseBody.length))}...');
      } catch (e) {
        debugPrint('解码响应体失败: $e');
        responseBody = response.body;
      }

      // 解析响应
      try {
        final Map<String, dynamic> responseData = json.decode(responseBody);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (success && responseData['code'] == 200) {
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

  // 根据用户ID获取用户详情
  static Future<UserResponse> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users/$userId'),
        headers: await HttpUtils.getAuthHeaders(),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UserResponse(
          success: true,
          message: '获取用户详情成功',
          user: User.fromJson(responseData['data']),
        );
      } else {
        return UserResponse(
          success: false,
          message: responseData['message'] ?? '获取用户详情失败',
        );
      }
    } catch (e) {
      return UserResponse(
        success: false,
        message: '网络错误: $e',
      );
    }
  }

  // 获取所有用户列表（可选分页）
  static Future<List<User>> getUsers({int page = 1, int pageSize = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users?page=$page&pageSize=$pageSize'),
        headers: await HttpUtils.getAuthHeaders(),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = responseData['data'];
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception(responseData['message'] ?? '获取用户列表失败');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  // 获取项目经理列表
  static Future<List<User>> getProjectManagers() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users/managers'),
        headers: await HttpUtils.getAuthHeaders(),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> managersJson = responseData['data'];
        return managersJson.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception(responseData['message'] ?? '获取项目经理列表失败');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }
}

// 帮助函数：取较小值
int min(int a, int b) {
  return a < b ? a : b;
} 