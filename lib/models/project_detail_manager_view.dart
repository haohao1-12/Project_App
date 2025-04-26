import 'package:flutter/material.dart';
import 'task_manager_view.dart';

class ProjectDetailManagerView {
  final int id;
  final String projectName;
  final int status; // 0: 进行中, 1: 已完成
  final DateTime deadline;
  final List<TaskManagerView> tasks;

  ProjectDetailManagerView({
    required this.id,
    required this.projectName,
    required this.status,
    required this.deadline,
    required this.tasks,
  });

  // 从JSON创建ProjectDetailManagerView对象
  factory ProjectDetailManagerView.fromJson(Map<String, dynamic> json) {
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
        );
      } else {
        // 如果不是列表，尝试解析字符串格式
        deadlineDate = DateTime.parse(json['deadline'].toString());
      }
    } catch (e) {
      debugPrint('解析项目详情deadline出错: $e, 使用当前日期');
      deadlineDate = DateTime.now();
    }

    // 解析任务列表
    List<TaskManagerView> taskList = [];
    if (json['data'] != null && json['data'] is List) {
      for (var taskJson in json['data']) {
        try {
          taskList.add(TaskManagerView.fromJson(taskJson));
        } catch (e) {
          debugPrint('解析任务出错: $e');
        }
      }
    }

    return ProjectDetailManagerView(
      id: json['id'] as int,
      projectName: json['projectName'] as String,
      status: json['status'] as int,
      deadline: deadlineDate,
      tasks: taskList,
    );
  }

  // 格式化日期为易读格式
  String getFormattedDeadline() {
    return '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}';
  }

  // 获取项目状态文本
  String getStatusText() {
    return status == 0 ? '进行中' : '已完成';
  }

  // 获取项目状态颜色
  Color getStatusColor() {
    return status == 0 ? Colors.orange : Colors.green;
  }
} 