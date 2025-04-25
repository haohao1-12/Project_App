import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../utils/encoding_helper.dart';
import 'login_screen.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '退出登录',
          ),
        ],
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            '项目列表',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '您当前是${_getUserTypeText()}，${_getUserTypeText() == "项目经理" ? "可以创建和管理项目" : "可以查看分配给您的项目"}',
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 跳转到项目列表页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('功能开发中...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.search),
            label: const Text('查看所有项目'),
          ),
          if (_getUserTypeText() == "项目经理")
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: 跳转到创建项目页面
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('功能开发中...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('创建新项目'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 头像
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.inputFillColor,
            backgroundImage: _currentUser?.imageUrl != null
                ? NetworkImage(_currentUser!.imageUrl!)
                : null,
            child: _currentUser?.imageUrl == null
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: AppTheme.textSecondaryColor,
                  )
                : null,
          ),
          const SizedBox(height: 24),
          // 用户名
          Text(
            EncodingHelper.fixEncoding(_currentUser?.username) ?? '未知用户',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // 用户类型
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryLightColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _getUserTypeText(),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // 个人信息卡片
          _buildInfoCard(
            title: '个人信息',
            children: [
              _buildInfoItem(
                icon: Icons.email,
                title: '邮箱',
                value: _currentUser?.email ?? '未设置',
              ),
              _buildInfoItem(
                icon: Icons.info,
                title: '简介',
                value: _currentUser?.userProfile ?? '这个人很懒，什么都没写',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 账号设置卡片
          _buildInfoCard(
            title: '账号设置',
            children: [
              // 修改密码
              InkWell(
                onTap: () {
                  // TODO: 跳转到修改密码页面
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('功能开发中...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 8.0,
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.lock,
                        color: AppTheme.textSecondaryColor,
                      ),
                      SizedBox(width: 16),
                      Text(
                        '修改密码',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              // 编辑个人资料
              InkWell(
                onTap: () {
                  // TODO: 跳转到编辑个人资料页面
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('功能开发中...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 8.0,
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.edit,
                        color: AppTheme.textSecondaryColor,
                      ),
                      SizedBox(width: 16),
                      Text(
                        '编辑个人资料',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              // 退出登录
              InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 8.0,
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.logout,
                        color: Colors.red,
                      ),
                      SizedBox(width: 16),
                      Text(
                        '退出登录',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建信息卡片
  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // 构建信息项
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 获取用户类型文本
  String _getUserTypeText() {
    if (_currentUser?.userType == null) {
      return '未知类型';
    }
    
    // userType可能是整数、字符串形式的数字或直接是类型名称
    if (_currentUser!.userType == 0 || _currentUser!.userType == '0' || _currentUser!.userType == '项目经理') {
      return '项目经理';
    } else if (_currentUser!.userType == 1 || _currentUser!.userType == '1' || _currentUser!.userType == '员工') {
      return '员工';
    } else {
      return '未知类型：${_currentUser!.userType}';
    }
  }
} 