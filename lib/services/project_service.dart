import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import '../models/project_detail.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class ProjectListResponse {
  final bool success;
  final String message;
  final List<Project> projects;
  final int total;

  ProjectListResponse({
    required this.success,
    required this.message,
    required this.projects,
    required this.total,
  });
}

class ProjectDetailResponse {
  final bool success;
  final String message;
  final ProjectDetail? projectDetail;

  ProjectDetailResponse({
    required this.success,
    required this.message,
    this.projectDetail,
  });
}

class ProjectService {
  // 获取项目列表
  static Future<ProjectListResponse> getProjectList({required int page, int pageSize = 5}) async {
    try {
      // 获取认证令牌
      final token = await AuthService.getToken();
      if (token == null) {
        return ProjectListResponse(
          success: false,
          message: '未登录，请先登录',
          projects: [],
          total: 0,
        );
      }

      // 构建请求URL和请求体
      final url = Uri.parse(AppConstants.projectListEndpoint);
      final requestBody = {
        'page': page,
        'pageSize': pageSize,
      };

      // 请求头中包含令牌
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'Accept-Charset': 'utf-8',
        'token': token,
      };

      debugPrint('发送获取项目列表请求: page=$page, pageSize=$pageSize');

      // 发送请求
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );

      debugPrint('项目列表响应状态码: ${response.statusCode}');

      // 解码响应体
      String responseBody;
      try {
        responseBody = utf8.decode(response.bodyBytes);
        debugPrint('项目列表响应体(部分): ${responseBody.substring(0, min(200, responseBody.length))}...');
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
          final int total = data['total'] ?? 0;
          
          final List<Project> projects = [];
          if (data['records'] != null && data['records'] is List) {
            for (var projectJson in data['records']) {
              try {
                final project = Project.fromJson(projectJson);
                projects.add(project);
              } catch (e) {
                debugPrint('解析项目数据出错: $e');
              }
            }
          }
          
          debugPrint('成功获取项目列表: ${projects.length} 项目，总计 $total 个项目');
          
          return ProjectListResponse(
            success: true,
            message: message,
            projects: projects,
            total: total,
          );
        } else {
          debugPrint('获取项目列表失败: $message');
          return ProjectListResponse(
            success: false,
            message: message,
            projects: [],
            total: 0,
          );
        }
      } catch (e) {
        debugPrint('解析项目列表响应出错: $e');
        return ProjectListResponse(
          success: false,
          message: '解析响应数据失败: $e',
          projects: [],
          total: 0,
        );
      }
    } catch (e) {
      debugPrint('获取项目列表过程中发生错误: $e');
      return ProjectListResponse(
        success: false,
        message: '网络请求失败: $e',
        projects: [],
        total: 0,
      );
    }
  }

  // 获取项目详情（成员视图）
  static Future<ProjectDetailResponse> getMemberProjectDetail(int projectId) async {
    try {
      // 获取认证令牌
      final token = await AuthService.getToken();
      if (token == null) {
        return ProjectDetailResponse(
          success: false,
          message: '未登录，请先登录',
        );
      }

      // 构建请求URL
      final url = Uri.parse('${AppConstants.memberProjectDetailEndpoint}/$projectId');

      // 请求头中包含令牌
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'Accept-Charset': 'utf-8',
        'token': token,
      };

      debugPrint('发送获取项目详情请求: projectId=$projectId');

      // 发送请求
      final response = await http.get(
        url,
        headers: headers,
      );

      debugPrint('项目详情响应状态码: ${response.statusCode}');

      // 解码响应体
      String responseBody;
      try {
        responseBody = utf8.decode(response.bodyBytes);
        debugPrint('项目详情响应体(部分): ${responseBody.substring(0, min(200, responseBody.length))}...');
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
            final projectDetail = ProjectDetail.fromJson(data);
            
            debugPrint('成功获取项目详情: ${projectDetail.projectName}');
            
            return ProjectDetailResponse(
              success: true,
              message: message,
              projectDetail: projectDetail,
            );
          } catch (e) {
            debugPrint('解析项目详情数据出错: $e');
            return ProjectDetailResponse(
              success: false,
              message: '解析项目详情数据失败: $e',
            );
          }
        } else {
          debugPrint('获取项目详情失败: $message');
          return ProjectDetailResponse(
            success: false,
            message: message,
          );
        }
      } catch (e) {
        debugPrint('解析项目详情响应出错: $e');
        return ProjectDetailResponse(
          success: false,
          message: '解析响应数据失败: $e',
        );
      }
    } catch (e) {
      debugPrint('获取项目详情过程中发生错误: $e');
      return ProjectDetailResponse(
        success: false,
        message: '网络请求失败: $e',
      );
    }
  }

  // 帮助方法：计算总页数
  static int calculateTotalPages(int totalItems, int pageSize) {
    return (totalItems / pageSize).ceil();
  }
}

// 帮助函数：取较小值
int min(int a, int b) {
  return a < b ? a : b;
} 