import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../utils/encoding_helper.dart';
import 'login_screen.dart';
import 'project_list_screen.dart';  // 导入项目列表页面
import 'profile_screen.dart';  // 导入个人主页

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 加载用户信息
  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // 如果在获取用户信息时出错，可以选择返回登录页面
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('获取用户信息失败，请重新登录'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 退出登录
  Future<void> _logout() async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
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

    if (confirmed == true) {
      try {
        await AuthService.logout();
        // 退出登录后跳转到登录页面
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false, // 清除所有路由历史
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('退出登录失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 主要视图列表
    final List<Widget> _pages = [
      _buildProjectsPage(),
      _buildTasksPage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('项目管理系统'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: '项目',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: '任务',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  // 项目列表页面
  Widget _buildProjectsPage() {
    // 直接返回项目列表页面
    return const ProjectListScreen();
  }

  // 任务列表页面
  Widget _buildTasksPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.task_alt,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            '任务列表',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '查看和管理您的任务',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 跳转到任务列表页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('功能开发中...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.search),
            label: const Text('查看我的任务'),
          ),
        ],
      ),
    );
  }

  // 个人中心页面
  Widget _buildProfilePage() {
    // 使用新的ProfileScreen组件
    return const ProfileScreen();
  }
} 