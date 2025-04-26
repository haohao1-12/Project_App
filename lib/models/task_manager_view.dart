import 'package:flutter/material.dart';

/// 项目经理视图下的任务模型
class TaskManagerView {
  final int id;
  final String taskName;
  final String memberName;
  final int memberId;
  final int status; // 0: 进行中, 1: 已完成
  final DateTime deadline;

  TaskManagerView({
    required this.id,
    required this.taskName,
    required this.memberName,
    required this.memberId,
    required this.status,
    required this.deadline,
  });

  // 从JSON创建TaskManagerView对象
  factory TaskManagerView.fromJson(Map<String, dynamic> json) {
    // 解析deadline
    DateTime deadlineDate;
    try {
      if (json['deadline'] is List) {
        List<dynamic> deadlineValues = json['deadline'];
        deadlineDate = DateTime(
          deadlineValues[0] as int,  // 年
          deadlineValues[1] as int,  // 月
          deadlineValues[2] as int,  // 日
          deadlineValues.length > 3 ? deadlineValues[3] as int : 0,  // 时
          deadlineValues.length > 4 ? deadlineValues[4] as int : 0,  // 分
          deadlineValues.length > 5 ? deadlineValues[5] as int : 0,  // 秒
        );
      } else {
        // 如果不是列表，尝试解析字符串格式
        deadlineDate = DateTime.parse(json['deadline'].toString());
      }
    } catch (e) {
      debugPrint('解析任务deadline出错: $e, 使用当前日期');
      deadlineDate = DateTime.now();
    }

    return TaskManagerView(
      id: json['id'] as int,
      taskName: json['taskName'] as String,
      memberName: json['memberName'] as String,
      memberId: json['memberId'] as int,
      status: json['status'] as int,
      deadline: deadlineDate,
    );
  }

  // 格式化日期为易读格式
  String getFormattedDeadline() {
    return '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}';
  }

  // 获取任务状态文本
  String getStatusText() {
    return status == 0 ? '进行中' : '已完成';
  }

  // 获取任务状态颜色
  Color getStatusColor() {
    return status == 0 ? Colors.orange : Colors.green;
  }
} 