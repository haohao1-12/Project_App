import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../utils/theme.dart';
import '../screens/project_detail_screen.dart';
import '../screens/project_detail_manager_screen.dart';
import '../screens/user_detail_screen.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final bool isLoading;
  final bool isManager;
  final VoidCallback onRefresh;

  const TaskList({
    Key? key,
    required this.tasks,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.isManager,
    required this.onRefresh,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无任务数据',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // 创建任务列表项
    List<Widget> listItems = [];
    
    // 添加任务卡片
    for (int i = 0; i < tasks.length; i++) {
      listItems.add(TaskCard(
        task: tasks[i],
        isManager: isManager,
        onTaskUpdated: onRefresh,
      ));
    }
    
    // 如果有多个页面，添加分页控件
    if (totalPages > 1) {
      listItems.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: currentPage > 1 
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                color: currentPage > 1 ? AppTheme.primaryColor : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                '$currentPage / $totalPages',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: currentPage < totalPages 
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                color: currentPage < totalPages ? AppTheme.primaryColor : Colors.grey,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: listItems,
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isManager;
  final VoidCallback onTaskUpdated;

  const TaskCard({
    Key? key,
    required this.task,
    required this.isManager,
    required this.onTaskUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.taskName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: task.getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: task.getStatusColor(),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        task.status == 0 ? Icons.access_time : Icons.check_circle,
                        color: task.getStatusColor(),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.getStatusText(),
                        style: TextStyle(
                          color: task.getStatusColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '截止日期: ${task.getFormattedDeadline()}',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.folder,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '所属项目: ',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                if (task.projectName != null)
                  InkWell(
                    onTap: () => _navigateToProjectDetail(context),
                    child: Text(
                      task.projectName!,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (isManager && task.memberName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '负责人: ',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    InkWell(
                      onTap: () => _navigateToUserDetail(context),
                      child: Text(
                        task.memberName!,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // 标记为完成按钮 - 只有在普通成员(非管理员)且任务状态为进行中时显示
            if (!isManager && task.status == 0)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markTaskAsCompleted(context),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('标记为完成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 导航到项目详情页面
  void _navigateToProjectDetail(BuildContext context) async {
    final userType = await AuthService.getUserType();
    bool? refreshNeeded;
    
    if (userType == '0') { // 项目经理视图
      refreshNeeded = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailManagerScreen(
            projectId: task.projectId,
          ),
        ),
      );
    } else { // 员工视图
      refreshNeeded = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailScreen(
            projectId: task.projectId,
          ),
        ),
      );
    }
    
    // 只有明确返回true时才刷新任务列表
    if (refreshNeeded == true) {
      onTaskUpdated();
    }
  }

  // 导航到用户详情页面
  void _navigateToUserDetail(BuildContext context) async {
    final bool? refreshNeeded = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(
          userId: task.assignedTo,
          userName: task.memberName ?? '',
        ),
      ),
    );
    
    // 只有明确返回true时才刷新任务列表
    if (refreshNeeded == true) {
      onTaskUpdated();
    }
  }
  
  // 标记任务为已完成
  void _markTaskAsCompleted(BuildContext context) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认完成'),
        content: const Text('确定要将此任务标记为已完成吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await TaskService.updateTaskStatus(
        taskId: task.id,
        projectId: task.projectId,
        status: 1, // 标记为已完成
      );

      // 关闭加载指示器
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (response.success) {
        // 更新成功，显示成功消息
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('任务已标记为完成'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 调用回调函数刷新任务列表
          onTaskUpdated();
        }
      } else {
        // 更新失败，显示错误消息
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('更新任务状态失败: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 关闭加载指示器
      if (context.mounted) {
        Navigator.pop(context);

        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新任务状态出错: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 