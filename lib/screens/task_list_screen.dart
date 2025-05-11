import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/task_list.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // 任务列表数据
  List<Task> _tasks = [];
  int _totalTasks = 0;
  int _currentPage = 1;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isManager = false; // 用户是否为项目经理
  
  // 分页常量
  static const int pageSize = 5;

  @override
  void initState() {
    super.initState();
    _checkUserType();
    _loadTasks();
  }

  // 检查用户类型
  Future<void> _checkUserType() async {
    String? userType = await AuthService.getUserType();
    setState(() {
      _isManager = userType == '0'; // userType为0表示项目经理
    });
    debugPrint('当前用户类型: $userType, 是否为项目经理: $_isManager');
  }

  // 加载任务数据
  Future<void> _loadTasks() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await TaskService.getTaskList(
        page: _currentPage,
        pageSize: pageSize,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        
        if (response.success) {
          _tasks = response.tasks;
          _totalTasks = response.total;
        } else {
          _errorMessage = response.message;
          _tasks = [];
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = '加载任务列表失败: $e';
        _tasks = [];
      });
    }
  }

  // 切换页面
  void _changePage(int newPage) {
    if (newPage < 1 || newPage > _totalPages) return;
    
    setState(() {
      _currentPage = newPage;
    });
    
    _loadTasks();
  }

  // 计算总页数
  int get _totalPages => TaskService.calculateTotalPages(_totalTasks, pageSize);

  // 刷新任务列表
  Future<void> _refreshTasks() async {
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _errorMessage.isNotEmpty
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _refreshTasks,
              child: TaskList(
                tasks: _tasks,
                currentPage: _currentPage,
                totalPages: _totalPages,
                onPageChanged: _changePage,
                isLoading: _isLoading,
                isManager: _isManager,
                onRefresh: _refreshTasks,
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
              onPressed: _refreshTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
} 