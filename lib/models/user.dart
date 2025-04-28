import 'dart:convert';
import '../utils/encoding_helper.dart';

class User {
  final String? id;
  final String userName;
  final String? email;
  final dynamic userType; // 保持为动态类型以处理不同格式
  final String? userProfile;
  final String? imageUrl;

  User({
    this.id,
    required this.userName,
    this.email,
    this.userType,
    this.userProfile,
    this.imageUrl,
  });

  // 从JSON创建User对象，增加空值处理，同时处理userName和username两种字段名
  factory User.fromJson(Map<String, dynamic> json) {
    // 优先使用userName字段，如果不存在则使用username字段
    String userNameValue;
    if (json.containsKey('userName')) {
      userNameValue = EncodingHelper.fixEncoding(json['userName'] ?? 'unknown_user');
    } else {
      userNameValue = EncodingHelper.fixEncoding(json['username'] ?? 'unknown_user');
    }
    
    // 处理userType可能是数字或字符串的情况
    dynamic userTypeValue = json['userType'];
    // 确保即使是字符串的数字也能被正确解析
    if (userTypeValue is String && (userTypeValue == '0' || userTypeValue == '1')) {
      userTypeValue = int.tryParse(userTypeValue) ?? userTypeValue;
    }
    
    return User(
      id: json['id']?.toString(), // 确保id为字符串类型
      userName: userNameValue,
      email: json['email'],
      userType: userTypeValue, // 使用处理过的userType
      userProfile: EncodingHelper.fixEncoding(json['userProfile']),
      imageUrl: json['imageUrl'],
    );
  }

  // 将User对象转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'email': email,
      'userType': userType,
      'userProfile': userProfile,
      'imageUrl': imageUrl,
    };
  }

  // 创建注册请求JSON
  Map<String, dynamic> toRegisterJson(String password) {
    return {
      'userName': userName,
      'password': password,
      'email': email,
      'userType': userType,
      'userProfile': userProfile,
      'imageUrl': imageUrl,
    };
  }
  
  // 获取用户类型的文本表示
  String getUserTypeText() {
    // 处理各种可能的userType格式
    if (userType == 0 || userType == '0') {
      return '项目经理';
    } else if (userType == 1 || userType == '1') {
      return '员工';
    } else {
      return '未知身份';
    }
  }
} 