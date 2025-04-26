import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/project_service.dart';
import '../services/user_service.dart';
import '../utils/theme.dart';

class CreateTaskScreen extends StatefulWidget {
  final int projectId;

  const CreateTaskScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _employeeNameController = TextEditingController();
  
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isEmployeeVerified = false;
  int? _employeeId;
  bool _isCheckingEmployee = false;

  @override
  void dispose() {
    _taskNameController.dispose();
    _employeeNameController.dispose();
    super.dispose();
  }

  // 选择日期
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale('zh'),
    );
    
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  // 验证员工姓名
  Future<void> _verifyEmployeeName() async {
    final employeeName = _employeeNameController.text.trim();
    if (employeeName.isEmpty) {
      return;
    }

    setState(() {
      _isCheckingEmployee = true;
      _isEmployeeVerified = false;
      _employeeId = null;
    });

    try {
      final response = await UserService.queryUserByName(employeeName);

      if (!mounted) return;

      setState(() {
        _isCheckingEmployee = false;
        
        if (response.success && response.userId != null) {
          _isEmployeeVerified = true;
          _employeeId = response.userId;
        } else {
          _isEmployeeVerified = false;
          _employeeId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isCheckingEmployee = false;
        _isEmployeeVerified = false;
        _employeeId = null;
      });
    }
  }

  // 创建任务
  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isEmployeeVerified || _employeeId == null) {
      setState(() {
        _errorMessage = '请先验证员工姓名';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ProjectService.addTask(
        taskName: _taskNameController.text.trim(),
        assignedTo: _employeeId!,
        projectId: widget.projectId,
        deadline: _deadline,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务创建成功')),
        );
        Navigator.pop(context, true); // 返回项目创建界面，并传递刷新标志
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = '创建任务失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建新任务'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                
                TextFormField(
                  controller: _taskNameController,
                  decoration: const InputDecoration(
                    labelText: '任务名称',
                    hintText: '请输入任务名称',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入任务名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _employeeNameController,
                        decoration: InputDecoration(
                          labelText: '分配员工',
                          hintText: '请输入员工姓名',
                          border: const OutlineInputBorder(),
                          suffixIcon: _isCheckingEmployee
                              ? Container(
                                  width: 20,
                                  height: 20,
                                  padding: const EdgeInsets.all(8),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : _isEmployeeVerified
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : null,
                        ),
                        onChanged: (value) {
                          // 输入改变时重置验证状态
                          if (_isEmployeeVerified) {
                            setState(() {
                              _isEmployeeVerified = false;
                              _employeeId = null;
                            });
                          }
                        },
                        onEditingComplete: _verifyEmployeeName,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入员工姓名';
                          }
                          if (!_isEmployeeVerified) {
                            return '请验证员工姓名';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: ElevatedButton(
                        onPressed: _isCheckingEmployee ? null : _verifyEmployeeName,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('验证'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // 项目ID（只读）
                TextFormField(
                  initialValue: widget.projectId.toString(),
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '项目ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                
                const Text(
                  '截止日期',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy-MM-dd').format(_deadline),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    onPressed: _isLoading ? null : _createTask,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            '创建任务',
                            style: TextStyle(fontSize: 18),
                          ),
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