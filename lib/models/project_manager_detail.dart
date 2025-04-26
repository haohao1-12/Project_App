import 'package:flutter/material.dart';
import 'task_manager_view.dart';

/// 项目经理视图下的项目详情模型
class ProjectManagerDetail {
  final int id;
  final String projectName;
  final int status; // 0: 进行中, 1: 已完成
  final DateTime deadline;
  final List<TaskManagerView> tasks;

  ProjectManagerDetail({
    required this.id,
    required this.projectName,
    required this.status,
    required this.deadline,
    required this.tasks,
  });

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
    return status == 0 ? Colors.red : Colors.green;
  }

  // 计算任务完成率
  double getTaskCompletionRate() {
    if (tasks.isEmpty) return 0.0;
    
    int completedTasks = tasks.where((task) => task.status == 1).length;
    return completedTasks / tasks.length;
  }

  // 计算任务完成百分比文本
  String getTaskCompletionRateText() {
    return '${(getTaskCompletionRate() * 100).toStringAsFixed(0)}%';
  }
} 