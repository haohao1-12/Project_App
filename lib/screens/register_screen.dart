import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/image_picker_widget.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  File? _avatarFile;
  String? _avatarUrl; // 存储上传后的头像URL
  String? _selectedUserType;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _uploadStatusText = ''; // 用于显示头像上传状态

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // 修改_navigateBackToLogin方法
  void _navigateBackToLogin(BuildContext context) {
    // 返回到登录页面，并传递用户名
    Navigator.of(context).pop({
      'username': _usernameController.text,
      'registered': true,
    });
  }

  // 处理图片选择和上传结果
  void _handleImageSelected(File file, String? imageUrl) {
    setState(() {
      _avatarFile = file;
      _avatarUrl = imageUrl;
    });
  }

  // 处理上传状态更新
  void _handleUploadStatusChanged(String status) {
    setState(() {
      _uploadStatusText = status;
    });
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await AuthService.register(
          username: _usernameController.text,
          password: _passwordController.text,
          email: _emailController.text,
          userType: _selectedUserType ?? AppConstants.userTypes[1], // 默认为员工
          userProfile: _bioController.text,
          imageUrl: _avatarUrl ?? "https://image/214514", // 使用已上传的头像URL或默认URL
        );

        setState(() {
          _isLoading = false;
        });

        if (response.success) {
          // 保存用户信息到本地（如果有的话）
          if (response.user != null && response.token != null) {
            try {
              await AuthService.saveUserAndToken(response.user!, response.token!);
            } catch (e) {
              debugPrint('保存用户信息时出错: $e');
              // 继续执行，这不是关键步骤
            }
          }
          
          // 注册成功，使用过渡动画返回登录页面
          if (mounted) {
            // 先显示一个本地成功消息
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.green,
              ),
            );
            
            // 短暂延迟后返回登录页面
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) {
                _navigateBackToLogin(context);
              }
            });
          }
        } else {
          // 显示错误信息
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.unknownErrorMessage),
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
      appBar: AppBar(
        title: const Text('注册'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // 头像选择和上传
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ImagePickerWidget(
                        selectedImage: _avatarFile,
                        imageUrl: _avatarUrl,
                        onImageSelected: _handleImageSelected,
                        onUploadStatusChanged: _handleUploadStatusChanged,
                      ),
                      
                      // 头像上传状态提示
                      if (_uploadStatusText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Center(
                            child: Text(
                              _uploadStatusText,
                              style: TextStyle(
                                color: _uploadStatusText.contains('失败') || _uploadStatusText.contains('错误')
                                    ? Colors.red 
                                    : _uploadStatusText.contains('成功')
                                        ? Colors.green
                                        : AppTheme.primaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  // 用户名
                  CustomTextField(
                    label: '用户名',
                    hint: '请输入用户名',
                    controller: _usernameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入用户名';
                      }
                      if (value.length < AppConstants.usernameMinLength) {
                        return '用户名至少${AppConstants.usernameMinLength}个字符';
                      }
                      if (value.length > AppConstants.usernameMaxLength) {
                        return '用户名不能超过${AppConstants.usernameMaxLength}个字符';
                      }
                      return null;
                    },
                  ),
                  
                  // 密码
                  CustomTextField(
                    label: '密码',
                    hint: '请输入密码',
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
                      if (value.length < AppConstants.passwordMinLength) {
                        return '密码至少${AppConstants.passwordMinLength}个字符';
                      }
                      if (value.length > AppConstants.passwordMaxLength) {
                        return '密码不能超过${AppConstants.passwordMaxLength}个字符';
                      }
                      return null;
                    },
                  ),
                  
                  // 邮箱
                  CustomTextField(
                    label: '电子邮箱',
                    hint: '请输入您的电子邮箱',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入电子邮箱';
                      }
                      final emailRegex = RegExp(
                          r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                      if (!emailRegex.hasMatch(value)) {
                        return '请输入有效的电子邮箱';
                      }
                      return null;
                    },
                  ),
                  
                  // 用户类型
                  CustomDropdown(
                    label: '用户类型',
                    hint: '请选择用户类型',
                    items: AppConstants.userTypes,
                    value: _selectedUserType,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedUserType = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请选择用户类型';
                      }
                      return null;
                    },
                  ),
                  
                  // 个人简介
                  CustomTextField(
                    label: '个人简介',
                    hint: '请简单介绍一下自己',
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: AppConstants.bioMaxLength,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 注册按钮
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _register,
                          child: const Text('注册'),
                        ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 