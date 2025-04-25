import 'dart:convert';
import '../utils/encoding_helper.dart';

class User {
  final String? id;
  final String username;
  final String? email;
  final dynamic userType;
  final String? userProfile;
  final String? imageUrl;

  User({
    this.id,
    required this.username,
    this.email,
    this.userType,
    this.userProfile,
    this.imageUrl,
  });

  // 从JSON创建User对象，增加空值处理
  factory User.fromJson(Map<String, dynamic> json) {
    // 使用EncodingHelper修复编码问题
    String username = EncodingHelper.fixEncoding(json['username'] ?? 'unknown_user');
    
    return User(
      id: json['id']?.toString(), // 确保id为字符串类型
      username: username,
      email: json['email'],
      userType: json['userType'], // 直接接收userType，不进行类型转换
      userProfile: EncodingHelper.fixEncoding(json['userProfile']),
      imageUrl: json['imageUrl'],
    );
  }

  // 将User对象转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'userType': userType,
      'userProfile': userProfile,
      'imageUrl': imageUrl,
    };
  }

  // 创建注册请求JSON
  Map<String, dynamic> toRegisterJson(String password) {
    return {
      'username': username,
      'password': password,
      'email': email,
      'userType': userType,
      'userProfile': userProfile,
      'imageUrl': imageUrl,
    };
  }
} 