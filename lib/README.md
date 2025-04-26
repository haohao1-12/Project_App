# 项目管理系统 - Flutter移动端

## HTTP工具类使用说明

本项目使用统一的`HttpUtils`工具类处理所有HTTP请求，位于`app/lib/utils/http_utils.dart`文件中。

### 主要功能

1. **统一请求头处理**：所有请求自动添加认证令牌和内容类型
2. **统一错误处理**：捕获并格式化网络错误
3. **编码问题解决**：自动处理UTF-8编码问题
4. **日志记录**：详细记录请求和响应日志，方便调试
5. **超时处理**：统一设置请求超时时间

### 使用方法

```dart
// GET请求示例
final response = await HttpUtils.get('users/profile');

// 带查询参数的GET请求
final response = await HttpUtils.get('users', queryParams: {
  'page': '1',
  'pageSize': '10'
});

// POST请求示例
final response = await HttpUtils.post(
  'auth/login',
  body: {
    'username': 'user123',
    'password': '******'
  }
);

// 解析响应
final responseData = HttpUtils.parseResponse(response);

// 检查响应是否成功
if (HttpUtils.isSuccessful(responseData)) {
  // 处理成功响应
} else {
  // 处理错误响应
  final errorMsg = HttpUtils.getErrorMessage(responseData);
}
```

### 优势

1. **代码复用**：避免在每个服务类中重复相同的HTTP请求逻辑
2. **一致性**：确保所有HTTP请求使用相同的请求头、错误处理和日志记录
3. **易于维护**：集中修改HTTP相关逻辑，无需修改多个文件
4. **可扩展性**：轻松添加新的HTTP方法或全局拦截器
5. **安全性**：统一管理敏感信息如认证令牌

## 配置文件

项目配置信息位于`app/lib/utils/config.dart`文件中，包含API URL、环境设置和请求超时时间等配置。 