import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import '../utils/notification_manager.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../utils/encoding_helper.dart';
import '../screens/project_list_screen.dart';
import '../screens/task_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../widgets/message_icon.dart';
import 'message_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  User? _currentUser;
  bool _isLoading = true;
  final GlobalKey<MessageIconState> _messageIconKey = GlobalKey<MessageIconState>();
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // 我们会在 didChangeDependencies 中设置 WebSocket 连接
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里初始化 WebSocket 连接，因为此时 context 已可用
    _setupWebSocketConnection();
  }

  @override
  void dispose() {
    // 确保在销毁时移除回调
    WebSocketService.instance.removeMessageCallback(_handleNewTaskMessage);
    // 关闭WebSocket连接
    WebSocketService.instance.disconnect();
    super.dispose();
  }

  // 设置WebSocket连接
  Future<void> _setupWebSocketConnection() async {
    // 确保用户已登录后再建立连接
    bool isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) return;
    
    // 注册当前上下文，以便在默认处理函数中使用
    WebSocketService.instance.registerContext(context);
    
    // 首先添加消息回调，无论是否已连接
    WebSocketService.instance.addMessageCallback(_handleNewTaskMessage);
    
    // 检查是否已连接
    if (WebSocketService.instance.isConnected) {
      return;
    }
    
    // 连接WebSocket
    bool connected = await WebSocketService.instance.connect();
    
    if (mounted && !connected) {
      // 如果连接失败，显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法连接到消息服务，某些通知功能可能不可用。'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // 5秒后尝试重新连接
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _setupWebSocketConnection();
        }
      });
      
      return;
    }
    
    // 检查用户类型
    _checkUserType();
  }

  // 检查用户类型
  Future<void> _checkUserType() async {
    final userType = await AuthService.getUserType();
    setState(() {
      _isManager = userType == '0'; // userType为0表示项目经理
    });
  }

  // 处理新任务消息
  void _handleNewTaskMessage(Message message) {
    // 更新未读消息数量
    _messageIconKey.currentState?.refreshUnreadCount();
    
    // 允许所有用户看到通知，不再判断是否为管理员
    if (mounted) {
      // 显示新任务通知
      NotificationManager.instance.showTaskNotification(context, message);
    }
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
        // 断开WebSocket连接
        WebSocketService.instance.disconnect();
        
        // 移除所有活动通知
        NotificationManager.instance.removeAllNotifications();
        
        // 退出登录
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
    
    // 根据当前选中的索引确定标题
    final List<String> _titles = const [
      '项目列表',
      '任务列表',
      '个人主页',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // 消息图标
          MessageIcon(
            key: _messageIconKey,
            onTapped: _onMessageTapped,
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

  void _onMessageTapped() {
    // 在从消息页面返回时刷新消息图标
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MessageScreen()),
    ).then((_) {
      // 当从MessageScreen返回时，刷新未读消息计数
      _messageIconKey.currentState?.refreshUnreadCount();
    });
  }

  // 项目列表页面
  Widget _buildProjectsPage() {
    // 直接返回项目列表页面
    return const ProjectListScreen();
  }

  // 任务列表页面
  Widget _buildTasksPage() {
    // 直接返回任务列表页面
    return const TaskListScreen();
  }

  // 个人中心页面
  Widget _buildProfilePage() {
    return const ProfileScreen();
  }
} 