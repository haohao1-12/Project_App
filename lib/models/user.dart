class User {
  final String? id;
  final String username;
  final String? email;
  final String? userType;
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
    // 确保至少有用户名，如果没有则使用默认值
    String username = json['username'] ?? 'unknown_user';
    
    return User(
      id: json['id'],
      username: username,
      email: json['email'],
      userType: json['userType']?.toString(), // 确保转换为字符串
      userProfile: json['userProfile'],
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