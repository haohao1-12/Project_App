import 'package:flutter/material.dart';
import '../models/message.dart';
import '../utils/theme.dart';
import '../screens/task_detail_screen.dart';

class TaskNotification extends StatelessWidget {
  final Message message;
  final VoidCallback? onDismiss;

  const TaskNotification({
    Key? key,
    required this.message,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 确保安全渲染，即使taskName为空
    final String displayName = message.taskName.isNotEmpty ? message.taskName : '新任务';
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '新任务提醒',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDismiss,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
                children: [
                  const TextSpan(text: '您获得一个新任务：'),
                  WidgetSpan(
                    child: InkWell(
                      onTap: () => _viewTaskDetail(context),
                      child: Text(
                        displayName,  // 使用安全的显示名称
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 查看任务详情 - 直接使用taskId导航到任务详情页面
  void _viewTaskDetail(BuildContext context) {
    // 关闭通知
    onDismiss?.call();
    
    // 导航到任务详情页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen.fromTaskId(taskId: message.taskId),
      ),
    );
  }
} 