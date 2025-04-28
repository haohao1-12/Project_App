import 'package:flutter/material.dart';
import '../models/project_detail.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../utils/theme.dart';
import 'user_detail_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  ProjectDetail? _projectDetail;

  @override
  void initState() {
    super.initState();
    _loadProjectDetail();
  }

  // 加载项目详情
  Future<void> _loadProjectDetail() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ProjectService.getMemberProjectDetail(widget.projectId);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        
        if (response.success) {
          _projectDetail = response.projectDetail;
        } else {
          _errorMessage = response.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = '加载项目详情失败: $e';
      });
    }
  }

  // 刷新项目详情
  Future<void> _refreshProjectDetail() async {
    await _loadProjectDetail();
  }

  // 查看项目经理详情
  void _viewManagerDetail() {
    if (_projectDetail == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(
          userId: _projectDetail!.createBy,
          userName: _projectDetail!.managerName,
        ),
      ),
    );
  }

  // 更新任务状态
  Future<void> _updateTaskStatus(Task task) async {
    if (!mounted) return;
    
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
        projectId: _projectDetail!.id,
        status: 1, // 将状态更新为已完成
      );

      if (!mounted) return;
      
      // 关闭加载指示器
      Navigator.pop(context);
      
      if (response.success) {
        // 更新成功，显示成功提示并刷新项目详情
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('任务已标记为完成'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshProjectDetail();
      } else {
        // 更新失败，显示错误信息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新任务状态失败: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // 关闭加载指示器
      Navigator.pop(context);
      
      // 显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新任务状态出错: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProjectDetail,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorView();
    }

    if (_projectDetail == null) {
      return const Center(
        child: Text('找不到项目详情'),
      );
    }

    // 使用CustomScrollView代替嵌套的SingleChildScrollView
    return RefreshIndicator(
      onRefresh: _refreshProjectDetail,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProjectHeader(),
                const Divider(height: 32),
                _buildProjectInfo(),
                const SizedBox(height: 24),
                // 任务标题
                const Text(
                  '我的任务',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // 空任务或任务列表
                if (_projectDetail!.taskList.isEmpty)
                  _buildEmptyTasksView()
                else
                  ..._projectDetail!.taskList.map((task) => _buildTaskCard(task)).toList(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // 构建项目标题部分
  Widget _buildProjectHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _projectDetail!.projectName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 16),
            _buildStatusChip(),
          ],
        ),
      ],
    );
  }

  // 构建状态标签
  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _projectDetail!.getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _projectDetail!.getStatusColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _projectDetail!.status == 0 ? Icons.access_time : Icons.check_circle,
            color: _projectDetail!.getStatusColor(),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _projectDetail!.getStatusText(),
            style: TextStyle(
              color: _projectDetail!.getStatusColor(),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 构建项目信息部分
  Widget _buildProjectInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '项目信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildManagerItem(),
            _buildInfoItem(
              icon: Icons.calendar_today,
              label: '截止日期',
              value: _projectDetail!.getFormattedDeadline(),
            ),
          ],
        ),
      ),
    );
  }

  // 构建项目经理项（可点击）
  Widget _buildManagerItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          const Icon(
            Icons.person,
            color: AppTheme.textSecondaryColor,
            size: 20,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '项目经理',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: _viewManagerDetail,
                child: Row(
                  children: [
                    Text(
                      _projectDetail!.managerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor, // 使用主题色显示为链接
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
        ],
      ),
    );
  }

  // 构建信息项
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.textSecondaryColor,
            size: 20,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建空任务视图
  Widget _buildEmptyTasksView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无任务',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建任务卡片
  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
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
            // 仅当任务状态为进行中(0)时显示完成按钮
            if (task.status == 0)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateTaskStatus(task),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('标记为完成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 构建错误视图
  Widget _buildErrorView() {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
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
                    _errorMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _refreshProjectDetail,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
} 