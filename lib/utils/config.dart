// 项目配置文件
// 包含全局配置如API URL和环境设置

// 从constants.dart中导入以保持一致性
import 'constants.dart';

class Config {
  // API URL配置
  static const String apiUrl = AppConstants.baseUrl;

  // 应用版本
  static const String appVersion = '1.0.0';

  // 环境配置
  static const bool isDebug = true;

  // 请求超时时间（毫秒）
  static const int requestTimeout = 15000;

  // 是否显示网络日志
  static const bool showNetworkLogs = true;
} 