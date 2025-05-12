import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../utils/constants.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../utils/notification_manager.dart';

// 消息回调函数类型定义
typedef MessageCallback = void Function(Message message);

class WebSocketService {
  static WebSocketService? _instance;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final List<MessageCallback> _messageCallbacks = [];
  Timer? _reconnectTimer;
  Timer? _checkCallbacksTimer;
  BuildContext? _lastKnownContext;
  
  // 私有构造函数
  WebSocketService._();
  
  // 单例获取方法
  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }
  
  // 检查是否已连接
  bool get isConnected => _isConnected;

  // 注册最后已知的上下文，方便在没有回调时显示通知
  void registerContext(BuildContext context) {
    _lastKnownContext = context;
  }
  
  // 默认消息处理函数，在没有其他回调时使用
  void _defaultMessageHandler(Message message) {
    if (_lastKnownContext != null && _lastKnownContext!.mounted) {
      NotificationManager.instance.showTaskNotification(_lastKnownContext!, message);
    }
  }

  // 连接WebSocket
  Future<bool> connect() async {
    if (_isConnected) {
      return true;
    }
    
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        debugPrint('未找到登录令牌，无法连接WebSocket');
        return false;
      }
      
      // 构建WebSocket URL 和 Headers
      final wsUrl = '${AppConstants.wsBaseUrl}/ws';
      final headers = {'token': token};
      
      // 创建WebSocket连接，传递headers
      try {
        _channel = IOWebSocketChannel.connect(
          Uri.parse(wsUrl),
          headers: headers,
        );
      } catch (e) {
        debugPrint('创建WebSocket通道时出错: $e');
        return false;
      }
      
      // 设置消息监听
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      
      // 设置超时检查
      bool connectionEstablished = false;
      Timer? connectionTimer;
      
      connectionTimer = Timer(const Duration(seconds: 5), () {
        if (!connectionEstablished) {
          debugPrint('WebSocket连接超时');
          _channel?.sink.close();
          _isConnected = false;
        }
      });
      
      // 尝试发送一个ping消息来确认连接
      try {
        // 等待一小段时间，让连接有机会建立
        await Future.delayed(const Duration(milliseconds: 500));
        _channel?.sink.add('{"type":"ping"}');
        
        // 如果没有抛出异常，认为连接成功
        connectionEstablished = true;
        connectionTimer?.cancel();
        
        _isConnected = true;
        
        // 开始定期检查回调列表
        _startCallbackCheck();
        
        // 取消可能的重连定时器
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        
        return true;
      } catch (e) {
        debugPrint('发送测试消息时出错，连接可能未正确建立: $e');
        connectionTimer?.cancel();
        return false;
      }
    } catch (e) {
      debugPrint('WebSocket连接失败: $e');
      _setupReconnect();
      return false;
    }
  }
  
  // 定期检查回调列表
  void _startCallbackCheck() {
    _checkCallbacksTimer?.cancel();
    _checkCallbacksTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_messageCallbacks.isEmpty) {
        debugPrint('警告: 消息回调列表为空，可能导致消息无法显示');
      }
    });
  }
  
  // 关闭WebSocket连接
  void disconnect() {
    if (!_isConnected) return;
    
    _channel?.sink.close();
    _isConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _checkCallbacksTimer?.cancel();
    _checkCallbacksTimer = null;
  }
  
  // 添加消息回调
  void addMessageCallback(MessageCallback callback) {
    // 避免重复添加同一回调
    if (!_messageCallbacks.contains(callback)) {
      _messageCallbacks.add(callback);
    }
  }
  
  // 移除消息回调
  void removeMessageCallback(MessageCallback callback) {
    _messageCallbacks.remove(callback);
  }
  
  // 处理接收的消息
  void _onMessage(dynamic data) {
    try {
      // 解析JSON数据
      final Map<String, dynamic> jsonData = json.decode(data);
      
      // 如果是pong消息，直接返回
      if (jsonData['type'] == 'pong') {
        return;
      }
      
      // 创建消息对象，确保处理null值
      final message = Message(
        id: jsonData['id'] ?? 0,
        taskId: jsonData['taskId'] ?? 0,
        taskName: jsonData['taskName'] ?? '新任务',
        status: jsonData['status'] ?? 0,
        createTime: jsonData['createTime'] != null 
            ? (jsonData['createTime'] is String 
                ? DateTime.parse(jsonData['createTime']) 
                : DateTime.now())
            : DateTime.now(),
      );
      
      // 通知所有回调
      if (_messageCallbacks.isEmpty) {
        _defaultMessageHandler(message);
      } else {
        for (final callback in _messageCallbacks) {
          callback(message);
        }
      }
    } catch (e) {
      debugPrint('解析WebSocket消息出错: $e');
    }
  }
  
  // 处理错误
  void _onError(dynamic error) {
    debugPrint('WebSocket错误: $error');
    _isConnected = false;
    _setupReconnect();
  }
  
  // 处理连接关闭
  void _onDone() {
    debugPrint('WebSocket连接已关闭');
    _isConnected = false;
    _setupReconnect();
  }
  
  // 设置自动重连
  void _setupReconnect() {
    if (_reconnectTimer != null) return;
    
    // 30秒后尝试重连
    _reconnectTimer = Timer(const Duration(seconds: 30), () async {
      await connect();
    });
  }
} 