import 'package:flutter/foundation.dart';
import '../utils/http_utils.dart';
import '../models/message.dart';
import '../models/task.dart';

class MessageListResponse {
  final bool success;
  final String message;
  final List<Message> messages;

  MessageListResponse({
    required this.success,
    required this.message,
    required this.messages,
  });
}

class TaskDetailResponse {
  final bool success;
  final String message;
  final Task? task;

  TaskDetailResponse({
    required this.success,
    required this.message,
    this.task,
  });
}

class MessageService {
  // 获取未读消息数量
  static Future<int> getUnreadMessageCount() async {
    try {
      debugPrint('获取未读消息数量');
      
      // 发送请求到获取未读消息数量的API
      final response = await HttpUtils.get('/message/count');
      
      debugPrint('获取未读消息数量响应状态码: ${response.statusCode}');
      
      // 解析响应
      final responseData = HttpUtils.parseResponse(response);
      
      if (HttpUtils.isSuccessful(responseData)) {
        final count = responseData['data'] as int? ?? 0;
        debugPrint('未读消息数量: $count');
        return count;
      } else {
        debugPrint('获取未读消息数量失败: ${responseData['message']}');
        return 0;
      }
    } catch (e) {
      debugPrint('获取未读消息数量过程中发生错误: $e');
      return 0;
    }
  }
  
  // 获取消息列表
  static Future<MessageListResponse> getMessageList() async {
    try {
      debugPrint('发送获取消息列表请求');
      
      // 发送GET请求
      final response = await HttpUtils.get('/message/queryMessageList');
      
      debugPrint('消息列表响应状态码: ${response.statusCode}');
      
      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          final List<Message> messages = [];
          
          if (responseData['data'] != null && responseData['data'] is List) {
            for (var messageJson in responseData['data']) {
              try {
                final message = Message.fromJson(messageJson);
                messages.add(message);
              } catch (e) {
                debugPrint('解析消息数据出错: $e');
              }
            }
          }
          
          debugPrint('成功获取消息列表: ${messages.length} 条消息');
          
          return MessageListResponse(
            success: true,
            message: message,
            messages: messages,
          );
        } else {
          debugPrint('获取消息列表失败: $message');
          return MessageListResponse(
            success: false,
            message: message,
            messages: [],
          );
        }
      } catch (e) {
        debugPrint('解析消息列表响应出错: $e');
        return MessageListResponse(
          success: false,
          message: '解析响应数据失败: $e',
          messages: [],
        );
      }
    } catch (e) {
      debugPrint('获取消息列表过程中发生错误: $e');
      return MessageListResponse(
        success: false,
        message: '网络请求失败: $e',
        messages: [],
      );
    }
  }
  
  // 获取任务详情
  static Future<TaskDetailResponse> getTaskById(int taskId) async {
    try {
      debugPrint('发送获取任务详情请求: taskId=$taskId');
      
      // 发送GET请求
      final response = await HttpUtils.get('/task/queryById/$taskId');
      
      debugPrint('任务详情响应状态码: ${response.statusCode}');
      
      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          if (responseData['data'] != null) {
            try {
              final task = Task.fromJson(responseData['data']);
              debugPrint('成功获取任务详情: ${task.taskName}');
              
              return TaskDetailResponse(
                success: true,
                message: message,
                task: task,
              );
            } catch (e) {
              debugPrint('解析任务详情数据出错: $e');
              return TaskDetailResponse(
                success: false,
                message: '解析任务详情数据失败: $e',
              );
            }
          } else {
            debugPrint('任务详情为空');
            return TaskDetailResponse(
              success: false,
              message: '任务详情为空',
            );
          }
        } else {
          debugPrint('获取任务详情失败: $message');
          return TaskDetailResponse(
            success: false,
            message: message,
          );
        }
      } catch (e) {
        debugPrint('解析任务详情响应出错: $e');
        return TaskDetailResponse(
          success: false,
          message: '解析响应数据失败: $e',
        );
      }
    } catch (e) {
      debugPrint('获取任务详情过程中发生错误: $e');
      return TaskDetailResponse(
        success: false,
        message: '网络请求失败: $e',
      );
    }
  }

  // 标记消息为已读
  static Future<bool> markMessageAsRead(int messageId) async {
    try {
      debugPrint('发送标记消息为已读请求: messageId=$messageId');
      
      // 发送PUT或POST请求（根据后端API设计）
      // 此处假设使用PUT请求，实际应根据后端API调整
      final response = await HttpUtils.post(
        '/message/markAsRead',
        body: {
          'id': messageId,
        },
      );
      
      debugPrint('标记消息为已读响应状态码: ${response.statusCode}');
      
      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          debugPrint('成功标记消息为已读');
          return true;
        } else {
          debugPrint('标记消息为已读失败: $message');
          return false;
        }
      } catch (e) {
        debugPrint('解析标记消息为已读响应出错: $e');
        return false;
      }
    } catch (e) {
      debugPrint('标记消息为已读过程中发生错误: $e');
      return false;
    }
  }

  // 更新消息状态（已读/未读）
  static Future<bool> updateMessageStatus(int messageId, int status) async {
    try {
      debugPrint('发送更新消息状态请求: messageId=$messageId, status=$status');
      
      // 发送请求到更新消息接口
      final response = await HttpUtils.post(
        '/message/update',
        body: {
          'id': messageId,
          'status': status,
        },
      );
      
      debugPrint('更新消息状态响应状态码: ${response.statusCode}');
      
      // 解析响应
      try {
        final responseData = HttpUtils.parseResponse(response);
        
        final bool success = responseData['success'] == true;
        final String message = responseData['message'] ?? '未知消息';
        
        if (HttpUtils.isSuccessful(responseData)) {
          debugPrint('成功更新消息状态');
          return true;
        } else {
          debugPrint('更新消息状态失败: $message');
          return false;
        }
      } catch (e) {
        debugPrint('解析更新消息状态响应出错: $e');
        return false;
      }
    } catch (e) {
      debugPrint('更新消息状态过程中发生错误: $e');
      return false;
    }
  }
} 