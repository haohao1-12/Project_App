import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import '../models/project_detail.dart';
import '../models/project_detail_manager_view.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import '../utils/http_utils.dart';

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

class ProjectDetailManagerResponse {
  final bool success;
  final String message;
  final ProjectDetailManagerView? projectDetail;

  ProjectDetailManagerResponse({
    required this.success,
    required this.message,
    this.projectDetail,
  });
}

class ProjectResponse {
  final bool success;
  final String message;
  final Project? project;

  ProjectResponse({
    required this.success,
    required this.message,
    this.project,
  });
}

class AddProjectResponse {
  final bool success;
  final String message;
  final int? projectId;

  AddProjectResponse({
    required this.success,
    required this.message,
    this.projectId,
  });
}

class AddTaskResponse {
  final bool success;
  final String message;

  AddTaskResponse({
    required this.success,
    required this.message,
  });
}

class ProjectService {
  // 获取项目列表
  static Future<ProjectListResponse> getProjectList({required int page, int pageSize = 5}) async {
    try {
      debugPrint('发送获取项目列表请求: page=$page, pageSize=$pageSize');

      // 使用HttpUtils工具类发送请求
      final requestBody = {
        'page': page,
        'pageSize': pageSize,
      };
      
      final response = await HttpUtils.post(
        AppConstants.projectListEndpoint,
        body: requestBody,
      );

      debugPrint('项目列表响应状态码: ${response.statusCode}');

      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
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

  // 获取单个项目信息
  static Future<ProjectResponse> getProject(int projectId) async {
    try {
      debugPrint('发送获取单个项目信息请求: projectId=$projectId');

      // 使用HttpUtils工具类发送请求
      final response = await HttpUtils.get('${AppConstants.projectEndpoint}/$projectId');

      debugPrint('单个项目信息响应状态码: ${response.statusCode}');

      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          try {
            final Map<String, dynamic> data = responseData['data'];
            final project = Project.fromJson(data);
            
            debugPrint('成功获取项目信息: ${project.projectName}');
            
            return ProjectResponse(
              success: true,
              message: message,
              project: project,
            );
          } catch (e) {
            debugPrint('解析项目数据出错: $e');
            return ProjectResponse(
              success: false,
              message: '解析项目数据失败: $e',
            );
          }
        } else {
          debugPrint('获取项目信息失败: $message');
          return ProjectResponse(
            success: false,
            message: message,
          );
        }
      } catch (e) {
        debugPrint('解析项目信息响应出错: $e');
        return ProjectResponse(
          success: false,
          message: '解析响应数据失败: $e',
        );
      }
    } catch (e) {
      debugPrint('获取项目信息过程中发生错误: $e');
      return ProjectResponse(
        success: false,
        message: '网络请求失败: $e',
      );
    }
  }

  // 获取项目详情（成员视图）
  static Future<ProjectDetailResponse> getMemberProjectDetail(int projectId) async {
    try {
      debugPrint('发送获取成员视图项目详情请求: projectId=$projectId');

      // 使用HttpUtils工具类发送请求
      final response = await HttpUtils.get('${AppConstants.memberProjectDetailEndpoint}/$projectId');

      debugPrint('项目详情响应状态码: ${response.statusCode}');

      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          final Map<String, dynamic> data = responseData['data'];
          
          try {
            final projectDetail = ProjectDetail.fromJson(data);
            
            debugPrint('成功获取成员视图项目详情: ${projectDetail.projectName}');
            
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

  // 获取项目详情（项目经理视图）
  static Future<ProjectDetailManagerResponse> getManagerProjectDetail(int projectId) async {
    try {
      debugPrint('发送获取经理视图项目详情请求: projectId=$projectId');

      // 先获取项目基本信息
      String projectName = '未命名项目';
      int status = 0;
      DateTime deadline = DateTime.now();
      
      try {
        // 尝试获取单个项目信息
        final projectResponse = await getProject(projectId);
        if (projectResponse.success && projectResponse.project != null) {
          final project = projectResponse.project!;
          projectName = project.projectName;
          status = project.status;
          deadline = project.deadline;
          
          debugPrint('找到项目基本信息: $projectName, 状态: $status');
        } else {
          // 如果无法获取单个项目信息，尝试从项目列表中获取
          debugPrint('无法获取单个项目信息，尝试从项目列表获取');
          final projectListResponse = await getProjectList(page: 1, pageSize: 100);
          if (projectListResponse.success) {
            // 查找匹配的项目
            final matchingProjects = projectListResponse.projects.where((p) => p.id == projectId).toList();
            if (matchingProjects.isNotEmpty) {
              final project = matchingProjects.first;
              projectName = project.projectName;
              status = project.status;
              deadline = project.deadline;
              
              debugPrint('从项目列表中找到项目基本信息: $projectName, 状态: $status');
            }
          }
        }
      } catch (e) {
        debugPrint('获取项目基本信息失败: $e，将使用默认值');
      }

      // 使用HttpUtils工具类发送请求
      final response = await HttpUtils.get('${AppConstants.managerProjectDetailEndpoint}/$projectId');

      debugPrint('经理视图项目详情响应状态码: ${response.statusCode}');

      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          try {
            // 补充项目ID和其他必要信息到响应数据
            final Map<String, dynamic> modifiedData = {
              'id': projectId,
              'projectName': projectName,  // 使用从项目列表中获取的名称
              'status': status,  // 使用从项目列表中获取的状态
              'deadline': deadline,  // 使用从项目列表中获取的截止日期
              'data': responseData['data']
            };
            
            final projectDetail = ProjectDetailManagerView.fromJson(modifiedData);
            
            debugPrint('成功获取经理视图项目详情，包含 ${projectDetail.tasks.length} 个任务');
            
            return ProjectDetailManagerResponse(
              success: true,
              message: message,
              projectDetail: projectDetail,
            );
          } catch (e) {
            debugPrint('解析经理视图项目详情数据出错: $e');
            return ProjectDetailManagerResponse(
              success: false,
              message: '解析项目详情数据失败: $e',
            );
          }
        } else {
          debugPrint('获取经理视图项目详情失败: $message');
          return ProjectDetailManagerResponse(
            success: false,
            message: message,
          );
        }
      } catch (e) {
        debugPrint('解析经理视图项目详情响应出错: $e');
        return ProjectDetailManagerResponse(
          success: false,
          message: '解析响应数据失败: $e',
        );
      }
    } catch (e) {
      debugPrint('获取经理视图项目详情过程中发生错误: $e');
      return ProjectDetailManagerResponse(
        success: false,
        message: '网络请求失败: $e',
      );
    }
  }

  // 帮助方法：计算总页数
  static int calculateTotalPages(int totalItems, int pageSize) {
    return (totalItems / pageSize).ceil();
  }
  
  // 添加项目
  static Future<AddProjectResponse> addProject({
    required String projectName,
    required DateTime deadline,
  }) async {
    try {
      debugPrint('发送创建项目请求: projectName=$projectName, deadline=$deadline');

      // 格式化截止日期为"yyyy-MM-dd HH:mm:ss"格式
      String formattedDeadline = "${deadline.year}-"
          "${deadline.month.toString().padLeft(2, '0')}-"
          "${deadline.day.toString().padLeft(2, '0')} "
          "00:00:00";

      // 使用HttpUtils工具类发送请求
      final requestBody = {
        'projectName': projectName,
        'deadline': formattedDeadline,
      };
      
      debugPrint('创建项目请求体: $requestBody');
      final response = await HttpUtils.post(
        '${AppConstants.baseUrl}/project/addProject',
        body: requestBody,
      );

      debugPrint('创建项目响应状态码: ${response.statusCode}');

      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          final int? projectId = responseData['data'];
          
          debugPrint('成功创建项目，ID: $projectId');
          
          return AddProjectResponse(
            success: true,
            message: message,
            projectId: projectId,
          );
        } else {
          debugPrint('创建项目失败: $message');
          return AddProjectResponse(
            success: false,
            message: message,
          );
        }
      } catch (e) {
        debugPrint('解析创建项目响应出错: $e');
        return AddProjectResponse(
          success: false,
          message: '解析响应数据失败: $e',
        );
      }
    } catch (e) {
      debugPrint('创建项目过程中发生错误: $e');
      return AddProjectResponse(
        success: false,
        message: '网络请求失败: $e',
      );
    }
  }
  
  // 添加任务
  static Future<AddTaskResponse> addTask({
    required String taskName,
    required int assignedTo,
    required int projectId,
    required DateTime deadline,
  }) async {
    try {
      debugPrint('发送创建任务请求: taskName=$taskName, assignedTo=$assignedTo, projectId=$projectId, deadline=$deadline');

      // 格式化截止日期为"yyyy-MM-dd HH:mm:ss"格式
      String formattedDeadline = "${deadline.year}-"
          "${deadline.month.toString().padLeft(2, '0')}-"
          "${deadline.day.toString().padLeft(2, '0')} "
          "00:00:00";

      // 使用HttpUtils工具类发送请求
      final requestBody = {
        'taskName': taskName,
        'assignedTo': assignedTo,
        'projectId': projectId,
        'deadline': formattedDeadline,
      };
      
      debugPrint('创建任务请求体: $requestBody');
      final response = await HttpUtils.post(
        '${AppConstants.baseUrl}/task/addTask',
        body: requestBody,
      );

      debugPrint('创建任务响应状态码: ${response.statusCode}');

      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          debugPrint('成功创建任务');
          
          return AddTaskResponse(
            success: true,
            message: message,
          );
        } else {
          debugPrint('创建任务失败: $message');
          return AddTaskResponse(
            success: false,
            message: message,
          );
        }
      } catch (e) {
        debugPrint('解析创建任务响应出错: $e');
        return AddTaskResponse(
          success: false,
          message: '解析响应数据失败: $e',
        );
      }
    } catch (e) {
      debugPrint('创建任务过程中发生错误: $e');
      return AddTaskResponse(
        success: false,
        message: '网络请求失败: $e',
      );
    }
  }
}

// 帮助函数：取较小值
int min(int a, int b) {
  return a < b ? a : b;
} 