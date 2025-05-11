import 'package:flutter/material.dart';
import '../models/project_detail_manager_view.dart';
import '../models/task_manager_view.dart';
import '../services/project_service.dart';
import '../utils/theme.dart';
import 'user_detail_screen.dart';
import 'create_task_screen.dart';

class ProjectDetailManagerScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailManagerScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  State<ProjectDetailManagerScreen> createState() => _ProjectDetailManagerScreenState();
}

class _ProjectDetailManagerScreenState extends State<ProjectDetailManagerScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  ProjectDetailManagerView? _projectDetail;
  bool _dataChanged = false;

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
      final response = await ProjectService.getManagerProjectDetail(widget.projectId);

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

  // 查看团队成员详情
  void _viewMemberDetail(int memberId, String memberName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(
          userId: memberId,
          userName: memberName,
        ),
      ),
    );
  }

  // 批量添加任务
  void _addTasks() async {
    final bool? refreshNeeded = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskScreen(
          projectId: widget.projectId,
        ),
      ),
    );
    
    // 如果返回true，刷新项目详情并标记数据已更改
    if (refreshNeeded == true) {
      _dataChanged = true;
      _refreshProjectDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 只有在数据真正发生变化时才返回true
        Navigator.pop(context, _dataChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('项目详情（管理视图）'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshProjectDetail,
              tooltip: '刷新',
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // 只有在数据真正发生变化时才返回true
              Navigator.pop(context, _dataChanged);
            },
          ),
        ),
        body: _buildBody(),
        floatingActionButton: _isLoading || _projectDetail == null ? null : FloatingActionButton(
          onPressed: _addTasks,
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add),
          tooltip: '批量添加任务',
        ),
      ),
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

    return RefreshIndicator(
      onRefresh: _refreshProjectDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectHeader(),
            const Divider(height: 32),
            _buildProjectInfo(),
            const SizedBox(height: 24),
            _buildTaskListSection(),
          ],
        ),
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

  // 构建任务列表部分
  Widget _buildTaskListSection() {
    final tasks = _projectDetail!.tasks;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '任务列表',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          _buildEmptyTasksView()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
          ),
      ],
    );
  }

  // 构建空任务视图
  Widget _buildEmptyTasksView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
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
  Widget _buildTaskCard(TaskManagerView task) {
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
                  Icons.person,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _viewMemberDetail(task.memberId, task.memberName),
                  child: Row(
                    children: [
                      Text(
                        '执行人: ${task.memberName}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
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
            const SizedBox(height: 8),
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
          ],
        ),
      ),
    );
  }

  // 构建错误视图
  Widget _buildErrorView() {
    return Center(
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
    );
  }
} 