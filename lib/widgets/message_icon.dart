import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../screens/message_screen.dart';

class MessageIcon extends StatefulWidget {
  final VoidCallback? onTapped;
  final Key? messageIconKey;

  const MessageIcon({
    Key? key,
    this.onTapped,
    this.messageIconKey,
  }) : super(key: key);

  @override
  MessageIconState createState() => MessageIconState();
}

class MessageIconState extends State<MessageIcon> {
  int _unreadCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refreshUnreadCount() async {
    await _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await MessageService.getUnreadMessageCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      debugPrint('获取未读消息数量失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: widget.onTapped,
          tooltip: '消息',
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
} 