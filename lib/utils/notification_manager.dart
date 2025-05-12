import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../widgets/task_notification.dart';

class NotificationManager {
  static NotificationManager? _instance;
  final List<OverlayEntry> _activeNotifications = [];
  bool _overlayBusy = false;
  
  // 私有构造函数
  NotificationManager._();
  
  // 单例获取方法
  static NotificationManager get instance {
    _instance ??= NotificationManager._();
    return _instance!;
  }
  
  // 显示新任务通知
  void showTaskNotification(BuildContext context, Message message) {
    // 检查context是否有效
    if (!context.mounted) {
      return;
    }
    
    // 检查Overlay是否可用
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      debugPrint('无法获取Overlay，当前context可能不包含Overlay');
      return;
    }
    
    // 如果Overlay正忙，稍后重试
    if (_overlayBusy) {
      Future.delayed(const Duration(milliseconds: 500), () {
        showTaskNotification(context, message);
      });
      return;
    }
    
    try {
      _overlayBusy = true;
      
      // 创建一个OverlayEntry变量引用
      late OverlayEntry entry;
      
      // 创建OverlayEntry
      entry = OverlayEntry(
        builder: (context) => Positioned(
          top: 70.0, // 位于顶部，避免与状态栏重叠
          right: 20.0,
          left: 20.0,
          child: Material(
            color: Colors.transparent,
            child: TaskNotification(
              message: message,
              onDismiss: () {
                _removeNotification(entry);
              },
            ),
          ),
        ),
      );
      
      // 添加到管理列表
      _activeNotifications.add(entry);
      
      // 显示通知
      overlay.insert(entry);
      
      // 重置忙碌状态
      _overlayBusy = false;
      
      // 5秒后自动移除
      Timer(const Duration(seconds: 5), () {
        _removeNotification(entry);
      });
    } catch (e) {
      _overlayBusy = false;
      debugPrint('显示通知时出错: $e');
      
      // 尝试使用更简单的方式显示通知
      _showFallbackNotification(context, message);
    }
  }
  
  // 备用通知显示方法（使用SnackBar）
  void _showFallbackNotification(BuildContext context, Message message) {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('新任务: ${message.taskName}'),
            action: SnackBarAction(
              label: '查看',
              onPressed: () {
                // 可以在这里添加导航到任务详情的代码
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('备用通知方法也失败了: $e');
    }
  }
  
  // 移除特定通知
  void _removeNotification(OverlayEntry entry) {
    if (_activeNotifications.contains(entry)) {
      try {
        entry.remove();
        _activeNotifications.remove(entry);
      } catch (e) {
        debugPrint('移除通知时出错: $e');
      }
    }
  }
  
  // 移除所有通知
  void removeAllNotifications() {
    // 复制一份以避免在遍历时修改集合
    final notifications = List<OverlayEntry>.from(_activeNotifications);
    for (final entry in notifications) {
      try {
        entry.remove();
      } catch (e) {
        debugPrint('移除通知时出错: $e');
      }
    }
    _activeNotifications.clear();
  }
} 