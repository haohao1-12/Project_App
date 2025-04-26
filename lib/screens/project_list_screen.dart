import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../utils/theme.dart';
import '../widgets/project_list.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({Key? key}) : super(key: key);

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  // 项目列表数据
  List<Project> _projects = [];
  int _totalProjects = 0;
  int _currentPage = 1;
  bool _isLoading = true;
  String _errorMessage = '';
  
  // 分页常量
  static const int pageSize = 5;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  // 加载项目数据
  Future<void> _loadProjects() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ProjectService.getProjectList(
        page: _currentPage,
        pageSize: pageSize,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        
        if (response.success) {
          _projects = response.projects;
          _totalProjects = response.total;
        } else {
          _errorMessage = response.message;
          _projects = [];
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = '加载项目列表失败: $e';
        _projects = [];
      });
    }
  }

  // 切换页面
  void _changePage(int newPage) {
    if (newPage < 1 || newPage > _totalPages) return;
    
    setState(() {
      _currentPage = newPage;
    });
    
    _loadProjects();
  }

  // 计算总页数
  int get _totalPages => ProjectService.calculateTotalPages(_totalProjects, pageSize);

  // 刷新项目列表
  Future<void> _refreshProjects() async {
    await _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProjects,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _errorMessage.isNotEmpty
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _refreshProjects,
              child: ProjectList(
                projects: _projects,
                currentPage: _currentPage,
                totalPages: _totalPages,
                onPageChanged: _changePage,
                isLoading: _isLoading,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 实现创建新项目功能
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('创建新项目功能尚未实现'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
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
              onPressed: _refreshProjects,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
} 