import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/theme.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;
  final String? userName;

  const UserDetailScreen({
    Key? key,
    required this.userId,
    this.userName,
  }) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  User? _userDetail;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }

  // 加载用户详情
  Future<void> _loadUserDetail() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await UserService.getUserById(widget.userId);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        
        if (response.success) {
          _userDetail = response.user;
        } else {
          _errorMessage = response.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = '加载用户详情失败: $e';
      });
    }
  }

  // 刷新用户详情
  Future<void> _refreshUserDetail() async {
    await _loadUserDetail();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 返回false或null，因为在用户详情页不会修改任务状态
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.userName != null ? '${widget.userName}的资料' : '用户详情'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshUserDetail,
              tooltip: '刷新',
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // 返回false或null，因为在用户详情页不会修改任务状态
              Navigator.pop(context, false);
            },
          ),
        ),
        body: _buildBody(),
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

    if (_userDetail == null) {
      return const Center(
        child: Text('找不到用户信息'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUserDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            _buildUserHeader(),
            const SizedBox(height: 24),
            _buildUserInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Column(
      children: [
        _buildAvatar(),
        const SizedBox(height: 16),
        Text(
          _userDetail!.userName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildUserTypeChip(),
      ],
    );
  }

  Widget _buildAvatar() {
    return Hero(
      tag: 'user-avatar-${widget.userId}',
      child: CircleAvatar(
        radius: 60,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        backgroundImage: _userDetail!.imageUrl != null && _userDetail!.imageUrl!.isNotEmpty
            ? NetworkImage(_userDetail!.imageUrl!)
            : null,
        child: _userDetail!.imageUrl == null || _userDetail!.imageUrl!.isEmpty
            ? const Icon(
                Icons.person,
                size: 60,
                color: AppTheme.primaryColor,
              )
            : null,
      ),
    );
  }

  Widget _buildUserTypeChip() {
    Color chipColor;
    String userTypeText = _userDetail!.getUserTypeText();

    // 根据用户类型设置不同颜色
    if (_userDetail!.userType == 0 || _userDetail!.userType == '0') {
      chipColor = Colors.blue;  // 项目经理
    } else if (_userDetail!.userType == 1 || _userDetail!.userType == '1') {
      chipColor = Colors.green; // 员工
    } else {
      chipColor = Colors.grey;  // 未知身份
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: chipColor,
          width: 1,
        ),
      ),
      child: Text(
        userTypeText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
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
              value: _userDetail!.email ?? '未设置',
            ),
            if (_userDetail!.userProfile != null && _userDetail!.userProfile!.isNotEmpty)
              _buildProfileSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        const Text(
          '个人简介',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _userDetail!.userProfile ?? '',
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
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
              onPressed: _refreshUserDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
} 