import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../utils/theme.dart';
import '../services/message_service.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import '../widgets/task_detail_dialog.dart';
import '../services/auth_service.dart';

class MessageListItem extends StatelessWidget {
  final Message message;
  final Function() onTap;
  final Function() onMarkAsRead;
  
  const MessageListItem({
    Key? key,
    required this.message,
    required this.onTap,
    required this.onMarkAsRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (message.status == 0)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (message.status == 0) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.taskName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue, // 使任务名看起来像链接
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (message.status == 0)
                      IconButton(
                        icon: const Icon(
                          Icons.done_all,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        tooltip: '标记为已读',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onMarkAsRead,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.getFormattedCreateTime(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 查看任务详情
  void _viewTaskDetail(BuildContext context) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // 获取任务详情
      final response = await MessageService.getTaskById(message.taskId);
      
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (response.success && response.task != null) {
        // 如果消息是未读状态，尝试标记为已读
        if (message.status == 0) {
          try {
            await MessageService.markMessageAsRead(message.id);
          } catch (e) {
            debugPrint('标记消息为已读失败: $e');
          }
        }
        
        // 获取用户类型
        final userType = await AuthService.getUserType();
        final isManager = userType == '0'; // userType为0表示项目经理
        
        // 显示任务详情对话框
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => TaskDetailDialog(
              task: response.task!,
              showMemberName: isManager, // 只有项目经理才显示成员名称
            ),
          );
        }
        
        // 如果有回调，执行回调（用于刷新消息列表等）
        if (onTap != null) {
          onTap();
        }
      } else {
        // 显示错误信息
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('获取任务详情失败: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.pop(context);
        
        // 显示错误信息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取任务详情出错: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 