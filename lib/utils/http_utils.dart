import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'config.dart';
import 'constants.dart';

/// HTTP工具类
/// 封装HTTP请求方法，统一处理请求头、错误处理、编码问题等
class HttpUtils {
  /// 获取带认证令牌的请求头
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json; charset=utf-8',
      'Accept-Charset': 'utf-8',
      'token': token ?? '',
    };
  }

  /// 发送GET请求
  static Future<http.Response> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    final headers = await getAuthHeaders();
    final uri = _buildUri(endpoint, queryParams);
    
    _logRequest('GET', uri, headers: headers);
    
    try {
      final response = await http.get(uri, headers: headers)
          .timeout(Duration(milliseconds: Config.requestTimeout));
      
      _logResponse(response);
      return response;
    } catch (e) {
      _logError('GET', uri, e);
      rethrow;
    }
  }

  /// 发送POST请求
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    dynamic body,
  }) async {
    final headers = await getAuthHeaders();
    final uri = _buildUri(endpoint, queryParams);
    final encodedBody = body != null ? json.encode(body) : null;
    
    _logRequest('POST', uri, headers: headers, body: encodedBody);
    
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: encodedBody,
      ).timeout(Duration(milliseconds: Config.requestTimeout));
      
      _logResponse(response);
      return response;
    } catch (e) {
      _logError('POST', uri, e);
      rethrow;
    }
  }

  /// 发送PUT请求
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    dynamic body,
  }) async {
    final headers = await getAuthHeaders();
    final uri = _buildUri(endpoint, queryParams);
    final encodedBody = body != null ? json.encode(body) : null;
    
    _logRequest('PUT', uri, headers: headers, body: encodedBody);
    
    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: encodedBody,
      ).timeout(Duration(milliseconds: Config.requestTimeout));
      
      _logResponse(response);
      return response;
    } catch (e) {
      _logError('PUT', uri, e);
      rethrow;
    }
  }

  /// 发送DELETE请求
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    dynamic body,
  }) async {
    final headers = await getAuthHeaders();
    final uri = _buildUri(endpoint, queryParams);
    final encodedBody = body != null ? json.encode(body) : null;
    
    _logRequest('DELETE', uri, headers: headers, body: encodedBody);
    
    try {
      final response = await http.delete(
        uri,
        headers: headers,
        body: encodedBody,
      ).timeout(Duration(milliseconds: Config.requestTimeout));
      
      _logResponse(response);
      return response;
    } catch (e) {
      _logError('DELETE', uri, e);
      rethrow;
    }
  }

  /// 解析JSON响应
  static dynamic parseResponse(http.Response response) {
    try {
      // 尝试使用UTF-8解码
      String responseBody = utf8.decode(response.bodyBytes);
      return json.decode(responseBody);
    } catch (e) {
      debugPrint('解析响应出错: $e');
      throw Exception('解析响应失败: $e');
    }
  }

  /// 检查响应是否成功(返回code=200)
  static bool isSuccessful(Map<String, dynamic> responseData) {
    return responseData['success'] == true && responseData['code'] == 200;
  }

  /// 获取响应中的错误消息
  static String getErrorMessage(Map<String, dynamic> responseData) {
    return responseData['message'] ?? AppConstants.unknownErrorMessage;
  }

  /// 构建URI
  static Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    // 如果endpoint已经包含完整URL，则直接使用
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return Uri.parse(endpoint).replace(
        queryParameters: queryParams,
      );
    }
    
    // 否则，将其与baseUrl结合
    String path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('${Config.apiUrl}$path').replace(
      queryParameters: queryParams,
    );
  }

  /// 记录请求信息
  static void _logRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!Config.showNetworkLogs) return;
    
    debugPrint('┌───────────────────────────────────────────────────');
    debugPrint('│ 请求: $method ${uri.toString()}');
    if (headers != null) {
      debugPrint('│ 请求头: ${_filterSensitiveHeaders(headers)}');
    }
    if (body != null) {
      debugPrint('│ 请求体: $body');
    }
    debugPrint('└───────────────────────────────────────────────────');
  }

  /// 记录响应信息
  static void _logResponse(http.Response response) {
    if (!Config.showNetworkLogs) return;
    
    String responseBody;
    try {
      responseBody = utf8.decode(response.bodyBytes);
      if (responseBody.length > 500) {
        responseBody = '${responseBody.substring(0, 500)}...（已截断）';
      }
    } catch (e) {
      responseBody = '无法解码响应体: $e';
    }
    
    debugPrint('┌───────────────────────────────────────────────────');
    debugPrint('│ 响应: ${response.statusCode} - ${response.request?.url}');
    debugPrint('│ 响应头: ${response.headers}');
    debugPrint('│ 响应体: $responseBody');
    debugPrint('└───────────────────────────────────────────────────');
  }

  /// 记录错误信息
  static void _logError(String method, Uri uri, dynamic error) {
    if (!Config.showNetworkLogs) return;
    
    debugPrint('┌───────────────────────────────────────────────────');
    debugPrint('│ 错误: $method ${uri.toString()}');
    debugPrint('│ $error');
    debugPrint('└───────────────────────────────────────────────────');
  }

  /// 过滤请求头中的敏感信息
  static Map<String, String> _filterSensitiveHeaders(Map<String, String> headers) {
    final filtered = Map<String, String>.from(headers);
    if (filtered.containsKey('token')) {
      filtered['token'] = '***FILTERED***';
    }
    return filtered;
  }
}

/// 帮助方法
int min(int a, int b) {
  return a < b ? a : b;
} 