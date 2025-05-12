import 'package:flutter/material.dart';

class Message {
  final int id;
  final int taskId;
  final String taskName;
  final int status; // 0: 未读, 1: 已读
  final DateTime createTime;

  Message({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.status,
    required this.createTime,
  });

  // 从JSON创建Message对象
  factory Message.fromJson(Map<String, dynamic> json) {
    debugPrint('Message.fromJson: 开始解析消息数据');
    debugPrint('收到的JSON数据: $json');
    
    // 解析createTime
    DateTime createTimeDate;
    try {
      if (json['createTime'] is List) {
        // 处理数组格式的日期
        List<dynamic> createTimeValues = json['createTime'];
        createTimeDate = DateTime(
          createTimeValues[0] as int,  // 年
          createTimeValues[1] as int,  // 月
          createTimeValues[2] as int,  // 日
          createTimeValues.length > 3 ? createTimeValues[3] as int : 0,  // 时
          createTimeValues.length > 4 ? createTimeValues[4] as int : 0,  // 分
          createTimeValues.length > 5 ? createTimeValues[5] as int : 0,  // 秒
        );
      } else if (json['createTime'] is String) {
        // 处理字符串格式的日期
        createTimeDate = DateTime.parse(json['createTime'].toString());
      } else {
        // 默认使用当前日期
        createTimeDate = DateTime.now();
      }
    } catch (e) {
      debugPrint('解析消息createTime出错: $e, 使用当前日期');
      createTimeDate = DateTime.now();
    }

    // 安全地获取整数字段
    int safeId = 0;
    int safeTaskId = 0;
    int safeStatus = 0;
    
    try {
      if (json['id'] != null) {
        safeId = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
      }
      
      if (json['taskId'] != null) {
        safeTaskId = json['taskId'] is int ? json['taskId'] : int.tryParse(json['taskId'].toString()) ?? 0;
      }
      
      if (json['status'] != null) {
        safeStatus = json['status'] is int ? json['status'] : int.tryParse(json['status'].toString()) ?? 0;
      }
    } catch (e) {
      debugPrint('解析整数字段出错: $e');
    }
    
    // 安全地获取任务名
    String safeTaskName = json['taskName'] is String ? json['taskName'] : '新任务通知';
    
    debugPrint('Message.fromJson: 解析完成, id=$safeId, taskId=$safeTaskId, taskName=$safeTaskName');
    
    return Message(
      id: safeId,
      taskId: safeTaskId,
      taskName: safeTaskName,
      status: safeStatus,
      createTime: createTimeDate,
    );
  }

  // 格式化日期为易读格式
  String getFormattedCreateTime() {
    return '${createTime.year}-${createTime.month.toString().padLeft(2, '0')}-${createTime.day.toString().padLeft(2, '0')}';
  }

  // 获取消息状态文本
  String getStatusText() {
    return status == 0 ? '未读' : '已读';
  }

  // 获取消息状态颜色
  Color getStatusColor() {
    return status == 0 ? Colors.red : Colors.green;
  }
} 