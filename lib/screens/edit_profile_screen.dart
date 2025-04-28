import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/image_picker_widget.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _userNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  bool _isLoading = false;
  bool _hasChanges = false;
  String _errorMessage = '';
  
  // 头像相关
  File? _avatarFile;
  String? _avatarUrl;
  String _uploadStatusText = '';
  
  @override
  void initState() {
    super.initState();
    // 初始化文本控制器并填充当前用户信息
    _userNameController = TextEditingController(text: widget.user.userName);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _bioController = TextEditingController(text: widget.user.userProfile ?? '');
    
    // 设置当前头像URL
    _avatarUrl = widget.user.imageUrl;
    
    // 监听文本变化
    _userNameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _bioController.addListener(_checkForChanges);
  }
  
  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  // 检查是否有变更
  void _checkForChanges() {
    final userNameChanged = _userNameController.text != widget.user.userName;
    final emailChanged = _emailController.text != (widget.user.email ?? '');
    final bioChanged = _bioController.text != (widget.user.userProfile ?? '');
    final avatarChanged = _avatarUrl != widget.user.imageUrl;
    
    final hasChanges = userNameChanged || emailChanged || bioChanged || avatarChanged;
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }
  
  // 处理图片选择和上传结果
  void _handleImageSelected(File file, String? imageUrl) {
    setState(() {
      _avatarFile = file;
      _avatarUrl = imageUrl;
      _hasChanges = true;
    });
  }
  
  // 处理上传状态更新
  void _handleUploadStatusChanged(String status) {
    setState(() {
      _uploadStatusText = status;
    });
  }
  
  // 保存更新的个人信息
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有检测到任何变更'),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // 构建更新参数
      final userName = _userNameController.text != widget.user.userName ? _userNameController.text : null;
      final email = _emailController.text != (widget.user.email ?? '') ? _emailController.text : null;
      final userProfile = _bioController.text != (widget.user.userProfile ?? '') ? _bioController.text : null;
      final imageUrl = _avatarUrl != widget.user.imageUrl ? _avatarUrl : null;
      
      // 调用用户服务更新信息
      final response = await UserService.updateUserProfile(
        userName: userName,
        email: email,
        userProfile: userProfile,
        imageUrl: imageUrl,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
          
          // 延迟返回，让用户看到成功消息
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              Navigator.pop(context, true); // 返回true表示成功更新
            }
          });
        }
      } else {
        setState(() {
          _errorMessage = response.message;
        });
        
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
        _errorMessage = '更新个人信息失败: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑个人资料'),
        actions: [
          // 保存按钮
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _hasChanges ? _saveProfile : null,
                  tooltip: '保存',
                ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // 头像选择
                Center(
                  child: Column(
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
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 用户名
                CustomTextField(
                  label: '用户名',
                  hint: '请输入用户名',
                  controller: _userNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    if (value.length < AppConstants.userNameMinLength) {
                      return '用户名至少${AppConstants.userNameMinLength}个字符';
                    }
                    if (value.length > AppConstants.userNameMaxLength) {
                      return '用户名不能超过${AppConstants.userNameMaxLength}个字符';
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
                      return null; // 邮箱可选
                    }
                    final emailRegex = RegExp(
                        r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                    if (!emailRegex.hasMatch(value)) {
                      return '请输入有效的电子邮箱';
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
                
                const SizedBox(height: 24),
                
                // 保存按钮（整宽）
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
                    icon: const Icon(Icons.save),
                    label: const Text('保存更改'),
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