class AppConstants {
  // API端点
  static const String baseUrl = 'http://192.168.3.17:4000';
  // WebSocket端点
  static const String wsBaseUrl = 'ws://192.168.3.17:4000';
  static const String registerEndpoint = '$baseUrl/user/signup';
  static const String loginEndpoint = '$baseUrl/user/login';
  static const String uploadImageEndpoint = '$baseUrl/common/upload';
  
  // 项目API端点
  static const String projectListEndpoint = '$baseUrl/project/queryProjectList';
  static const String projectEndpoint = '$baseUrl/project'; // 单个项目信息端点
  static const String memberProjectDetailEndpoint = '$baseUrl/project/memberProjectDetail'; // 成员视图的项目详情端点
  static const String managerProjectDetailEndpoint = '$baseUrl/project/managerProjectDetail'; // 项目经理视图的项目详情端点
  
  // 任务API端点
  static const String addTaskEndpoint = '$baseUrl/task/addTask'; // 创建单个任务端点
  static const String addBatchTaskEndpoint = '$baseUrl/task/addBatchTask'; // 批量创建任务端点
  
  // 用户API端点
  static const String userProfileEndpoint = '$baseUrl/user'; // 用户个人信息端点
  
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
  static const String userIdKey = 'user_id'; // 用户ID存储键
  static const String userTypeKey = 'user_type'; // 用户类型存储键
  
  // 错误信息
  static const String networkErrorMessage = '网络连接错误，请检查您的网络连接';
  static const String serverErrorMessage = '服务器错误，请稍后再试';
  static const String unknownErrorMessage = '发生未知错误，请稍后再试';
  
  // 表单验证规则
  static const int userNameMinLength = 2;
  static const int userNameMaxLength = 20;
  static const int passwordMinLength = 6;
  static const int passwordMaxLength = 20;
  static const int bioMaxLength = 200;
} 