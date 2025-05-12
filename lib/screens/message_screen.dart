import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../models/message.dart';
import '../models/task.dart';
import '../widgets/message_list_item.dart';
import '../widgets/task_detail_dialog.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // 加载消息列表
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await MessageService.getMessageList();
      final count = await MessageService.getUnreadMessageCount();
      
      setState(() {
        _messages = response.messages;
        _unreadCount = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载消息失败: $e';
        _isLoading = false;
      });
    }
  }

  // 刷新消息列表
  Future<void> _refreshMessages() async {
    try {
      final response = await MessageService.getMessageList();
      final count = await MessageService.getUnreadMessageCount();
      
      setState(() {
        _messages = response.messages;
        _unreadCount = count;
      });
      
      return Future.value();
    } catch (e) {
      setState(() {
        _errorMessage = '刷新消息失败: $e';
      });
      return Future.error(e);
    }
  }

  // 标记消息为已读
  Future<void> _markMessageAsRead(Message message) async {
    try {
      final success = await MessageService.updateMessageStatus(message.id, 1);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已标记为已读'),
            duration: Duration(seconds: 1),
          ),
        );
        
        // 刷新消息列表和未读计数
        await _refreshMessages();
        
        // 刷新全局未读计数
        await AuthService.updateUnreadMessageCount();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('标记为已读失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('标记为已读出错: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 查看任务详情
  void _viewTaskDetail(Message message) async {
    final task = await _getTaskDetail(message.taskId);
    
    if (task != null && mounted) {
      // 获取用户类型
      final userType = await AuthService.getUserType();
      final isManager = userType == '0'; // 只有项目经理(userType=0)才显示负责人
      
      showDialog(
        context: context,
        builder: (context) => TaskDetailDialog(
          task: task,
          showMemberName: isManager, // 只有项目经理才显示成员名称
        ),
      );
      
      // 自动将消息标记为已读
      if (message.status == 0) {
        await _markMessageAsRead(message);
      }
    }
  }

  // 获取任务详情
  Future<Task?> _getTaskDetail(int taskId) async {
    try {
      final response = await MessageService.getTaskById(taskId);
      if (response.success && response.task != null) {
        return response.task;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('获取任务详情失败: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取任务详情出错: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('我的消息'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _messages.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _refreshMessages,
                      child: ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return MessageListItem(
                            message: message,
                            onTap: () => _viewTaskDetail(message),
                            onMarkAsRead: () => _markMessageAsRead(message),
                          );
                        },
                      ),
                    ),
    );
  }
  
  // 构建空消息视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无消息',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当有新的任务通知时，会在这里显示',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
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
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
} 