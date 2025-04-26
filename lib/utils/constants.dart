class AppConstants {
  // API端点
  static const String baseUrl = 'http://192.168.3.17:4000';
  static const String registerEndpoint = '$baseUrl/user/signup';
  static const String loginEndpoint = '$baseUrl/user/login';
  static const String uploadImageEndpoint = '$baseUrl/common/upload';
  
  // 项目API端点
  static const String projectListEndpoint = '$baseUrl/project/queryProjectList';
  
  // 用户类型
  static const List<String> userTypes = ['项目经理', '员工'];
  static const Map<String, int> userTypeValues = {
    '项目经理': 0,
    '员工': 1,
  };

  // 项目状态
  static const Map<int, String> projectStatusText = {
    0: '进行中',
    1: '已完成',
  };

  // 存储键
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_info';
  
  // 错误信息
  static const String networkErrorMessage = '网络连接错误，请检查您的网络连接';
  static const String serverErrorMessage = '服务器错误，请稍后再试';
  static const String unknownErrorMessage = '发生未知错误，请稍后再试';
  
  // 表单验证规则
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 20;
  static const int passwordMinLength = 6;
  static const int passwordMaxLength = 20;
  static const int bioMaxLength = 200;
} 