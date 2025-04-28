import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/theme.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';  // 导入登录页面

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // 加载用户个人信息
  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await UserService.getUserProfile();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        
        if (response.success) {
          _user = response.user;
        } else {
          _errorMessage = response.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = '加载用户信息失败: $e';
      });
    }
  }

  // 刷新用户个人信息
  Future<void> _refreshUserProfile() async {
    await _loadUserProfile();
  }

  // 跳转到编辑个人资料页面
  Future<void> _navigateToEditProfile() async {
    if (_user == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _user!),
      ),
    );
    
    // 如果成功更新，刷新个人资料
    if (result == true) {
      _refreshUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

    if (_user == null) {
      return const Center(
        child: Text('未找到用户信息'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUserProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildProfileInfo(),
              const SizedBox(height: 24),
              // 添加编辑按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToEditProfile,
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑个人资料'),
                ),
              ),
              const SizedBox(height: 16),
              // 添加退出登录按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('退出登录'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建个人信息头部
  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          // 头像
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: _user!.imageUrl != null && _user!.imageUrl!.isNotEmpty
                ? NetworkImage(_user!.imageUrl!)
                : null,
            child: _user!.imageUrl == null || _user!.imageUrl!.isEmpty
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey[400],
                  )
                : null,
          ),
          const SizedBox(height: 16),
          // 用户名
          Text(
            _user!.userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // 用户身份
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _getUserTypeColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getUserTypeColor(),
                width: 1,
              ),
            ),
            child: Text(
              _user!.getUserTypeText(),
              style: TextStyle(
                color: _getUserTypeColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 获取用户类型对应的颜色
  Color _getUserTypeColor() {
    if (_user!.userType == 0 || _user!.userType == '0') {
      return Colors.blue; // 项目经理
    } else {
      return Colors.orange; // 员工
    }
  }

  // 构建个人信息详情
  Widget _buildProfileInfo() {
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
              '个人信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.email,
              label: '邮箱',
              value: _user!.email ?? '未设置',
            ),
            _buildInfoItem(
              icon: Icons.info_outline,
              label: '个人简介',
              value: _user!.userProfile ?? '未设置',
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
                  ),
                ),
              ],
            ),
          ),
        ],
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
              onPressed: _refreshUserProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
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
} 