import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart'; // 导入主页面

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // 清除之前的登录数据（仅用于调试阶段）
    AuthService.clearAllUserData().then((_) {
      _checkLoggedInStatus();
    });
  }

  // 检查用户是否已登录
  Future<void> _checkLoggedInStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn && mounted) {
      // 如果用户已登录，直接进入主页
      _navigateToHome();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // 前往主页
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }
  
  // 去注册页面
  void _goToRegisterPage() async {
    // 使用await等待注册页面关闭
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
    
    // 检查注册结果
    if (result != null && result is Map) {
      // 如果返回了用户名，自动填充
      if (result.containsKey('username')) {
        setState(() {
          _usernameController.text = result['username'].toString();
        });
      }
      
      // 如果标记为已注册，显示成功消息
      if (result.containsKey('registered') && result['registered'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('注册成功，请登录'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  // 登录方法
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await AuthService.login(
          username: _usernameController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (response.success) {
          // 登录成功，显示成功消息并跳转到主页
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('登录成功'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
          
          // 延迟跳转，让用户看到成功消息
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _navigateToHome();
            }
          });
        } else {
          // 登录失败，显示错误消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('登录失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                
                // 标题
                const Text(
                  '欢迎回来',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                
                const Text(
                  '请登录您的账号',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // 用户名输入框
                CustomTextField(
                  label: '用户名',
                  hint: '请输入您的用户名',
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    return null;
                  },
                ),
                
                // 密码输入框
                CustomTextField(
                  label: '密码',
                  hint: '请输入您的密码',
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  suffix: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // 登录按钮
                _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('登录'),
                    ),
                
                const SizedBox(height: 24),
                
                // 注册新账号
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '没有账号？',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: _goToRegisterPage,
                        child: const Text('立即注册'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 