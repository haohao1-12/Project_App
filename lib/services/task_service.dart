import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/http_utils.dart';
import '../utils/constants.dart';

// 定义任务响应类
class TaskUpdateResponse {
  final bool success;
  final String message;

  TaskUpdateResponse({
    required this.success,
    required this.message,
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
} 