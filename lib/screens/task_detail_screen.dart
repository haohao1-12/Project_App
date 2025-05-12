import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../services/message_service.dart';
import '../screens/project_detail_screen.dart';
import '../screens/project_detail_manager_screen.dart';
import '../screens/user_detail_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task? task;
  final int? taskId;
  final bool shouldLoadTask;

  const TaskDetailScreen({
    Key? key,
    required this.task,
  }) : taskId = null, shouldLoadTask = false, super(key: key);
  
  // 通过taskId创建的构造函数
  const TaskDetailScreen.fromTaskId({
    Key? key,
    required this.taskId,
  }) : task = null, shouldLoadTask = true, super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isLoading = false;
  bool _isLoadingTask = false;
  bool _isManager = false;
  Task? _task;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkUserType();
    if (widget.shouldLoadTask && widget.taskId != null) {
      _loadTaskDetails();
    } else {
      _task = widget.task;
    }
  }

  // 加载任务详情
  Future<void> _loadTaskDetails() async {
    setState(() {
      _isLoadingTask = true;
      _errorMessage = null;
    });

    try {
      final response = await MessageService.getTaskById(widget.taskId!);
      if (mounted) {
        setState(() {
          _isLoadingTask = false;
          if (response.success && response.task != null) {
            _task = response.task;
          } else {
            _errorMessage = response.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTask = false;
          _errorMessage = '加载任务详情失败: $e';
        });
      }
    }
  }

  // 检查用户类型
  Future<void> _checkUserType() async {
    final userType = await AuthService.getUserType();
    setState(() {
      _isManager = userType == '0'; // userType为0表示项目经理
    });
  }

  // 更新任务状态
  Future<void> _updateTaskStatus() async {
    if (_isLoading || _task == null) return;
    
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

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await TaskService.updateTaskStatus(
        taskId: _task!.id,
        projectId: _task!.projectId,
        status: 1, // 标记为已完成
      );

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        // 成功更新任务状态
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('任务已标记为完成'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 返回并传递更新成功标志
        Navigator.pop(context, true);
      } else {
        // 更新失败
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新任务状态失败: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新任务状态出错: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 导航到项目详情页面
  void _navigateToProjectDetail() async {
    if (_task == null) return;
    
    final userType = await AuthService.getUserType();
    bool? refreshNeeded;
    
    if (userType == '0') { // 项目经理视图
      refreshNeeded = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailManagerScreen(
            projectId: _task!.projectId,
          ),
        ),
      );
    } else { // 员工视图
      refreshNeeded = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailScreen(
            projectId: _task!.projectId,
          ),
        ),
      );
    }
    
    // 只有明确返回true时才关闭当前页面
    if (refreshNeeded == true) {
      Navigator.pop(context, true);
    }
  }

  // 导航到用户详情页面
  void _navigateToUserDetail() async {
    if (!_isManager || _task?.memberName == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(
          userId: _task!.assignedTo,
          userName: _task!.memberName ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
      ),
      body: _isLoading || _isLoadingTask
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _task == null
                  ? const Center(child: Text('无法加载任务详情'))
                  : _buildBody(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '发生未知错误',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.shouldLoadTask ? _loadTaskDetails : () => Navigator.pop(context),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '任务信息',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProjectItem(),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: '截止日期',
                    value: _task!.getFormattedDeadline(),
                  ),
                  if (_isManager && _task!.memberName != null) ...[
                    const SizedBox(height: 12),
                    _buildMemberItem(),
                  ],
                ],
              ),
            ),
          ),
          // 只有未完成的任务且不是项目经理时显示标记为完成按钮
          if (_task!.status == 0 && !_isManager)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _updateTaskStatus,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('标记为完成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _task!.taskName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _task!.getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _task!.getStatusColor(),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _task!.status == 0 ? Icons.access_time : Icons.check_circle,
                    color: _task!.getStatusColor(),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _task!.getStatusText(),
                    style: TextStyle(
                      color: _task!.getStatusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.folder,
          size: 18,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '所属项目',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: _navigateToProjectDetail,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _task!.projectName ?? '未知项目',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.person,
          size: 18,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '负责人',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: _navigateToUserDetail,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _task!.memberName!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 