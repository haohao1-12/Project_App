import 'package:flutter/material.dart';

class Task {
  final int id;
  final String taskName;
  final int projectId;
  final int assignedTo;
  final int status; // 0: 进行中, 1: 已完成
  final DateTime deadline;
  final int createBy;
  final DateTime? createTime;
  final int updateBy;
  final DateTime? updateTime;

  Task({
    required this.id,
    required this.taskName,
    required this.projectId,
    required this.assignedTo,
    required this.status,
    required this.deadline,
    required this.createBy,
    this.createTime,
    required this.updateBy,
    this.updateTime,
  });

  // 从JSON创建Task对象
  factory Task.fromJson(Map<String, dynamic> json) {
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

    // 解析createTime
    DateTime? createTimeDate;
    try {
      if (json['createTime'] != null) {
        if (json['createTime'] is List) {
          List<dynamic> createTimeValues = json['createTime'];
          createTimeDate = DateTime(
            createTimeValues[0] as int,  // 年
            createTimeValues[1] as int,  // 月
            createTimeValues[2] as int,  // 日
            createTimeValues.length > 3 ? createTimeValues[3] as int : 0,  // 时
            createTimeValues.length > 4 ? createTimeValues[4] as int : 0,  // 分
            createTimeValues.length > 5 ? createTimeValues[5] as int : 0,  // 秒
          );
        } else {
          // 如果不是列表，尝试解析字符串格式
          createTimeDate = DateTime.parse(json['createTime'].toString());
        }
      }
    } catch (e) {
      debugPrint('解析任务createTime出错: $e, 使用空值');
      createTimeDate = null;
    }

    // 解析updateTime
    DateTime? updateTimeDate;
    try {
      if (json['updateTime'] != null) {
        if (json['updateTime'] is List) {
          List<dynamic> updateTimeValues = json['updateTime'];
          updateTimeDate = DateTime(
            updateTimeValues[0] as int,  // 年
            updateTimeValues[1] as int,  // 月
            updateTimeValues[2] as int,  // 日
            updateTimeValues.length > 3 ? updateTimeValues[3] as int : 0,  // 时
            updateTimeValues.length > 4 ? updateTimeValues[4] as int : 0,  // 分
            updateTimeValues.length > 5 ? updateTimeValues[5] as int : 0,  // 秒
          );
        } else {
          // 如果不是列表，尝试解析字符串格式
          updateTimeDate = DateTime.parse(json['updateTime'].toString());
        }
      }
    } catch (e) {
      debugPrint('解析任务updateTime出错: $e, 使用空值');
      updateTimeDate = null;
    }

    return Task(
      id: json['id'] as int,
      taskName: json['taskName'] as String,
      projectId: json['projectId'] as int,
      assignedTo: json['assignedTo'] as int,
      status: json['status'] as int,
      deadline: deadlineDate,
      createBy: json['createBy'] as int,
      createTime: createTimeDate,
      updateBy: json['updateBy'] as int,
      updateTime: updateTimeDate,
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