import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';

typedef ImageSelectedCallback = void Function(File file, String? imageUrl);

class ImagePickerWidget extends StatefulWidget {
  final File? selectedImage;
  final String? imageUrl;
  final ImageSelectedCallback onImageSelected;
  final Function(String) onUploadStatusChanged;

  const ImagePickerWidget({
    Key? key,
    this.selectedImage,
    this.imageUrl,
    required this.onImageSelected,
    required this.onUploadStatusChanged,
  }) : super(key: key);

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source, 
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      
      // 立即开始上传图片
      setState(() {
        _isUploading = true;
      });
      
      // 更新上传状态
      widget.onUploadStatusChanged('正在上传头像...');
      
      try {
        // 调用上传服务
        final uploadResponse = await AuthService.uploadImage(imageFile);
        
        setState(() {
          _isUploading = false;
        });
        
        if (uploadResponse.success && uploadResponse.imageUrl != null) {
          // 上传成功，返回文件和URL
          widget.onUploadStatusChanged('头像上传成功');
          widget.onImageSelected(imageFile, uploadResponse.imageUrl);
        } else {
          // 上传失败，但仍然返回文件
          widget.onUploadStatusChanged('头像上传失败: ${uploadResponse.message}');
          widget.onImageSelected(imageFile, null);
        }
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        
        // 上传出错，但仍然返回文件
        widget.onUploadStatusChanged('头像上传出错: $e');
        widget.onImageSelected(imageFile, null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '头像',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '选择后将立即上传到阿里云OSS',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _isUploading ? null : () => _showImageSourceDialog(context),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.inputFillColor,
                  backgroundImage: widget.selectedImage != null
                      ? FileImage(widget.selectedImage!) as ImageProvider
                      : null,
                  child: widget.selectedImage == null
                      ? const Icon(
                          Icons.add_a_photo,
                          size: 30,
                          color: AppTheme.textSecondaryColor,
                        )
                      : null,
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (widget.selectedImage != null && widget.imageUrl != null && !_isUploading)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_done,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                if (widget.selectedImage != null && widget.imageUrl == null && !_isUploading)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _isUploading ? null : () => _showImageSourceDialog(context),
            icon: const Icon(Icons.photo_camera),
            label: Text(widget.selectedImage == null ? '选择头像' : '更换头像'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
} 