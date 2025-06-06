import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/http_utils.dart';
import 'message_service.dart';

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

class UploadResponse {
  final bool success;
  final String message;
  final String? imageUrl;

  UploadResponse({
    required this.success,
    required this.message,
    this.imageUrl,
  });
}

class AuthService {
  // 获取保存的token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // 获取当前登录用户
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      
      debugPrint('获取保存的用户信息: $userJson');
      
      if (userJson != null) {
        try {
          // 解析用户JSON数据
          final Map<String, dynamic> userData = json.decode(userJson);
          
          // 调试输出
          userData.forEach((key, value) {
            debugPrint('获取到用户字段: $key = $value (类型: ${value.runtimeType})');
          });
          
          // 构建User对象
          final user = User.fromJson(userData);
          debugPrint('成功获取用户: ${user.userName}, 类型: ${user.userType}');
          return user;
        } catch (e, stackTrace) {
          debugPrint('解析用户信息出错: $e');
          debugPrint('错误堆栈: $stackTrace');
          // 如果解析失败，尝试清除存储的用户信息
          await prefs.remove(AppConstants.userKey);
          return null;
        }
      }
      debugPrint('未找到已保存的用户信息');
      return null;
    } catch (e, stackTrace) {
      debugPrint('获取用户过程中发生错误: $e');
      debugPrint('错误堆栈: $stackTrace');
      return null;
    }
  }

  // 检查用户是否已登录
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final user = await getCurrentUser();
    return token != null && user != null;
  }

  // 登出
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userTypeKey);
    await prefs.remove('unread_message_count'); // 清除未读消息数量
  }

  // 登录用户
  static Future<AuthResponse> login({
    required String userName,
    required String password,
  }) async {
    try {
      // 显示完整的URL，用于调试
      debugPrint('正在请求URL: ${AppConstants.loginEndpoint}');
      
      // 创建请求
      var requestBody = {
        'userName': userName,
        'password': password,
      };

      // 打印请求体，用于调试
      debugPrint('请求体: $requestBody');

      // 发送请求，使用HttpUtils
      debugPrint('发送请求...');
      var response = await HttpUtils.post(
        AppConstants.loginEndpoint,
        body: requestBody,
      );
      
      debugPrint('收到响应，状态码: ${response.statusCode}');
      
      // 解析响应
      try {
        var responseData = HttpUtils.parseResponse(response);
        
        // 检查响应是否成功
        bool isSuccess = responseData['success'] == true;
        int code = responseData['code'] ?? 0;
        String message = responseData['message'] ?? '未知消息';
        
        debugPrint('接口返回信息: success=$isSuccess, code=$code, message=$message');
        
        // code为200表示成功
        if (isSuccess && code == 200) {
          // 从data中解析用户信息
          var userData = responseData['data'];
          
          debugPrint('用户数据: $userData');
          
          String? token = userData['token'] as String?;
          
          if (userData != null) {
            // 详细打印userData的所有键值对，便于调试
            userData.forEach((key, value) {
              debugPrint('userData字段: $key = $value (类型: ${value.runtimeType})');
            });
            
            try {
              User user = User.fromJson(userData);
              
              // 保存用户信息和token
              if (token != null) {
                await saveUserAndToken(user, token);
                
                // 登录成功后获取未读消息数量
                await updateUnreadMessageCount();
              }
              
              return AuthResponse(
                success: true,
                message: message,
                user: user,
                token: token,
              );
            } catch (e, stackTrace) {
              // 详细记录User.fromJson过程中的错误
              debugPrint('User.fromJson解析出错: $e');
              debugPrint('错误堆栈: $stackTrace');
              return AuthResponse(
                success: false,
                message: '用户数据解析失败: $e',
              );
            }
          } else {
            return AuthResponse(
              success: false,
              message: '登录成功但未返回用户信息',
            );
          }
        } else {
          return AuthResponse(
            success: false,
            message: message,
          );
        }
      } catch (e, stackTrace) {
        debugPrint('解析响应时出错: $e');
        debugPrint('错误堆栈: $stackTrace');
        return AuthResponse(
          success: false,
          message: '解析响应失败',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('登录过程中发生错误: $e');
      debugPrint('错误堆栈: $stackTrace');
      return AuthResponse(
        success: false,
        message: '${AppConstants.networkErrorMessage}. 错误详情: $e',
      );
    }
  }

  // 上传图片到阿里云OSS
  static Future<UploadResponse> uploadImage(File imageFile) async {
    try {
      debugPrint('准备上传图片到阿里云OSS...');
      // 创建multipart请求
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConstants.uploadImageEndpoint),
      );
      
      // 添加头部，指定编码
      request.headers.addAll(await HttpUtils.getAuthHeaders());
      
      // 添加文件
      request.files.add(await http.MultipartFile.fromPath(
        'file', // 服务器端接收的字段名
        imageFile.path,
      ));
      
      debugPrint('正在上传图片...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('收到上传响应，状态码: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        var responseData = HttpUtils.parseResponse(response);
        
        bool isSuccess = responseData['success'] == true;
        int code = responseData['code'] ?? 0;
        String message = responseData['message'] ?? '未知消息';
        
        if (isSuccess && code == 200) {
          // 从data中获取图片URL
          String? imageUrl = responseData['data'];
          
          return UploadResponse(
            success: true,
            message: message,
            imageUrl: imageUrl,
          );
        } else {
          return UploadResponse(
            success: false,
            message: message,
          );
        }
      } else {
        return UploadResponse(
          success: false,
          message: '上传失败，状态码: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('上传图片时出错: $e');
      debugPrint('错误堆栈: $stackTrace');
      return UploadResponse(
        success: false,
        message: '上传图片错误: $e',
      );
    }
  }

  // 注册用户
  static Future<AuthResponse> register({
    required String userName,
    required String password,
    required String email,
    required String userType,
    required String userProfile,
    required String imageUrl, // 直接接收已上传的图片URL
  }) async {
    try {
      // 获取用户类型的整数值
      int userTypeValue = AppConstants.userTypeValues[userType] ?? 1; // 默认为员工
      
      // 显示完整的URL，用于调试
      debugPrint('正在请求URL: ${AppConstants.registerEndpoint}');
      
      // 创建请求
      var requestBody = {
        'userName': userName,
        'password': password,
        'email': email,
        'userType': userTypeValue.toString(),
        'userProfile': userProfile,
        'imageUrl': imageUrl, // 使用传入的URL
      };

      // 打印请求体，用于调试
      debugPrint('请求体: $requestBody');

      // 发送请求，使用HttpUtils
      debugPrint('发送请求...');
      var response = await HttpUtils.post(
        AppConstants.registerEndpoint,
        body: requestBody,
      );
      
      debugPrint('收到响应，状态码: ${response.statusCode}');
      
      // 解析响应
      try {
        var responseData = HttpUtils.parseResponse(response);
        
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
              userName: userName,
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
      } catch (e, stackTrace) {
        debugPrint('解析响应时出错: $e');
        debugPrint('错误堆栈: $stackTrace');
        return AuthResponse(
          success: false,
          message: '解析响应失败',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('注册过程中发生错误: $e');
      debugPrint('错误堆栈: $stackTrace');
      return AuthResponse(
        success: false,
        message: '${AppConstants.networkErrorMessage}. 错误详情: $e',
      );
    }
  }

  // 带token的HTTP请求工具方法
  static Future<http.Response> authenticatedGet(String url) async {
    final token = await getToken();
    return http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'Accept-Charset': 'utf-8',
        'token': token ?? '',
      },
    );
  }

  static Future<http.Response> authenticatedPost(String url, Map<String, dynamic> body) async {
    final token = await getToken();
    return http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'Accept-Charset': 'utf-8',
        'token': token ?? '',
      },
      body: json.encode(body),
    );
  }

  // 保存用户信息和token到本地存储
  static Future<void> saveUserAndToken(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 将用户对象转换为JSON字符串
      final userJson = json.encode(user.toJson());
      debugPrint('保存用户信息: $userJson');
      
      // 保存用户信息、token、用户ID和userType
      await prefs.setString(AppConstants.userKey, userJson);
      await prefs.setString(AppConstants.tokenKey, token);
      
      // 保存用户ID和用户类型
      if (user.id != null) {
        await prefs.setString(AppConstants.userIdKey, user.id.toString());
        debugPrint('保存用户ID: ${user.id}');
      }
      
      if (user.userType != null) {
        // userType可能是各种类型，统一转为字符串存储
        await prefs.setString(AppConstants.userTypeKey, user.userType.toString());
        debugPrint('保存用户类型: ${user.userType}');
      }
      
      debugPrint('用户信息、token、ID和类型保存成功');
    } catch (e, stackTrace) {
      debugPrint('保存用户信息失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      rethrow; // 重新抛出异常，以便调用者知道发生了错误
    }
  }

  // 获取当前用户ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userIdKey);
  }

  // 获取当前用户类型
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userTypeKey);
  }

  // 获取用户类型的文本表示
  static String getUserTypeText(dynamic userType) {
    // 处理各种可能的userType格式
    if (userType == 0 || userType == '0') {
      return '项目经理';
    } else if (userType == 1 || userType == '1') {
      return '员工';
    } else {
      return '未知身份';
    }
  }

  // 清除所有存储的用户数据（用于调试和登出）
  static Future<void> clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userKey);
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userTypeKey);
      await prefs.remove('unread_message_count'); // 清除未读消息数量
      debugPrint('已清除所有用户数据');
    } catch (e) {
      debugPrint('清除用户数据失败: $e');
    }
  }

  // 保存未读消息数量
  static Future<void> saveUnreadMessageCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_message_count', count);
      debugPrint('保存未读消息数量: $count');
    } catch (e) {
      debugPrint('保存未读消息数量失败: $e');
    }
  }

  // 获取未读消息数量
  static Future<int> getUnreadMessageCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('unread_message_count') ?? 0;
    } catch (e) {
      debugPrint('获取未读消息数量失败: $e');
      return 0;
    }
  }

  // 更新未读消息数量（从服务器获取）
  static Future<int> updateUnreadMessageCount() async {
    try {
      final count = await MessageService.getUnreadMessageCount();
      await saveUnreadMessageCount(count);
      return count;
    } catch (e) {
      debugPrint('更新未读消息数量失败: $e');
      return 0;
    }
  }
} 