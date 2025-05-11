import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/http_utils.dart';
import '../utils/constants.dart';
import '../models/task.dart';

// 定义任务响应类
class TaskUpdateResponse {
  final bool success;
  final String message;

  TaskUpdateResponse({
    required this.success,
    required this.message,
  });
}

// 定义任务列表响应类
class TaskListResponse {
  final bool success;
  final String message;
  final List<Task> tasks;
  final int total;

  TaskListResponse({
    required this.success,
    required this.message,
    required this.tasks,
    required this.total,
  });
}

class TaskService {
  // 更新任务状态
  static Future<TaskUpdateResponse> updateTaskStatus({
    required int taskId,
    required int projectId,
    required int status,
  }) async {
    try {
      final response = await HttpUtils.post(
        '/task/updateTask',
        body: {
          'id': taskId,
          'projectId': projectId,
          'status': status,
        },
      );

      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] ?? false;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          debugPrint('成功更新任务状态: taskId=$taskId');
          return TaskUpdateResponse(
            success: true,
            message: message,
          );
        } else {
          debugPrint('更新任务状态失败: $message');
          return TaskUpdateResponse(
            success: false,
            message: message,
          );
        }
      } catch (e) {
        debugPrint('解析更新任务状态响应出错: $e');
        return TaskUpdateResponse(
          success: false,
          message: '解析响应数据失败: $e',
        );
      }
    } catch (e) {
      debugPrint('更新任务状态异常: $e');
      return TaskUpdateResponse(
        success: false,
        message: '更新任务状态发生错误: $e',
      );
    }
  }

  // 获取任务列表
  static Future<TaskListResponse> getTaskList({
    required int page,
    int pageSize = 5,
  }) async {
    try {
      debugPrint('发送获取任务列表请求: page=$page, pageSize=$pageSize');

      // 发送请求
      final response = await HttpUtils.post(
        '/task/queryTaskList',
        body: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      debugPrint('任务列表响应状态码: ${response.statusCode}');

      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          final Map<String, dynamic> data = responseData['data'];
          final int total = data['total'] ?? 0;
          
          final List<Task> tasks = [];
          if (data['records'] != null && data['records'] is List) {
            for (var taskJson in data['records']) {
              try {
                final task = Task.fromJson(taskJson);
                tasks.add(task);
              } catch (e) {
                debugPrint('解析任务数据出错: $e');
              }
            }
          }
          
          debugPrint('成功获取任务列表: ${tasks.length} 个任务，总计 $total 个任务');
          
          return TaskListResponse(
            success: true,
            message: message,
            tasks: tasks,
            total: total,
          );
        } else {
          debugPrint('获取任务列表失败: $message');
          return TaskListResponse(
            success: false,
            message: message,
            tasks: [],
            total: 0,
          );
        }
      } catch (e) {
        debugPrint('解析任务列表响应出错: $e');
        return TaskListResponse(
          success: false,
          message: '解析响应数据失败: $e',
          tasks: [],
          total: 0,
        );
      }
    } catch (e) {
      debugPrint('获取任务列表过程中发生错误: $e');
      return TaskListResponse(
        success: false,
        message: '网络请求失败: $e',
        tasks: [],
        total: 0,
      );
    }
  }

  // 计算总页数
  static int calculateTotalPages(int totalItems, int pageSize) {
    return (totalItems / pageSize).ceil();
  }
} 