import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/project_service.dart';
import '../services/user_service.dart';
import '../utils/theme.dart';

class Task {
  String taskName;
  int assignedTo;
  String assignedToName;
  DateTime deadline;

  Task({
    required this.taskName,
    required this.assignedTo,
    required this.assignedToName,
    required this.deadline,
  });

  Map<String, dynamic> toJson(int projectId) {
    return {
      'taskName': taskName,
      'assignedTo': assignedTo,
      'projectId': projectId,
      'deadline': "${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')} 00:00:00",
    };
  }
}

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
  final List<Task> _tasks = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // 当前任务编辑状态
  Task? _currentEditingTask;
  int? _editingTaskIndex;
  
  void _editTask(int index) {
    setState(() {
      _currentEditingTask = Task(
        taskName: _tasks[index].taskName,
        assignedTo: _tasks[index].assignedTo,
        assignedToName: _tasks[index].assignedToName,
        deadline: _tasks[index].deadline,
      );
      _editingTaskIndex = index;
      _showAddTaskDialog();
    });
  }
  
  void _addNewTask() {
    setState(() {
      _currentEditingTask = null;
      _editingTaskIndex = null;
      _showAddTaskDialog();
    });
  }
  
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  Future<void> _submitTasks() async {
    if (_tasks.isEmpty) {
      setState(() {
        _errorMessage = '请至少添加一个任务';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 将任务列表转换为请求体格式
      final taskList = _tasks.map((task) => task.toJson(widget.projectId)).toList();
      
      // 调用批量创建任务接口
      final response = await ProjectService.addBatchTasks(taskList);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('批量创建任务成功')),
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
        _errorMessage = '批量创建任务失败: $e';
      });
    }
  }

  // 显示添加/编辑任务对话框
  Future<void> _showAddTaskDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TaskFormDialog(
          task: _currentEditingTask,
          onSubmit: (Task task) {
            setState(() {
              if (_editingTaskIndex != null) {
                // 更新现有任务
                _tasks[_editingTaskIndex!] = task;
              } else {
                // 添加新任务
                _tasks.add(task);
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建任务'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewTask,
            tooltip: '添加新任务',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          
          Expanded(
            child: _tasks.isEmpty
                ? const Center(
                    child: Text(
                      '点击右上角的"+"添加任务',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return TaskCard(
                        task: task,
                        onEdit: () => _editTask(index),
                        onDelete: () => _deleteTask(index),
                      );
                    },
                  ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                onPressed: _isLoading ? null : _submitTasks,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '批量提交任务',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.taskName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: '删除任务',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '分配给: ${task.assignedToName}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '截止日期: ${DateFormat('yyyy-MM-dd').format(task.deadline)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskFormDialog extends StatefulWidget {
  final Task? task;
  final Function(Task) onSubmit;

  const TaskFormDialog({
    Key? key,
    this.task,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _employeeNameController = TextEditingController();
  
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));
  bool _isEmployeeVerified = false;
  int? _employeeId;
  bool _isCheckingEmployee = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // 如果是编辑任务，填充表单数据
    if (widget.task != null) {
      _taskNameController.text = widget.task!.taskName;
      _employeeNameController.text = widget.task!.assignedToName;
      _deadline = widget.task!.deadline;
      _employeeId = widget.task!.assignedTo;
      _isEmployeeVerified = true;
    }
  }

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
      _errorMessage = '';
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
          _errorMessage = '找不到该员工';
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isCheckingEmployee = false;
        _isEmployeeVerified = false;
        _employeeId = null;
        _errorMessage = '验证员工失败: $e';
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isEmployeeVerified || _employeeId == null) {
      setState(() {
        _errorMessage = '请先验证员工姓名';
      });
      return;
    }

    // 创建任务对象
    final task = Task(
      taskName: _taskNameController.text.trim(),
      assignedTo: _employeeId!,
      assignedToName: _employeeNameController.text.trim(),
      deadline: _deadline,
    );

    // 提交任务并关闭对话框
    widget.onSubmit(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? '添加新任务' : '编辑任务'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入任务名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _employeeNameController,
                      decoration: InputDecoration(
                        labelText: '分配员工',
                        hintText: '请输入员工姓名',
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('验证'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text(
                '截止日期',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('保存'),
        ),
      ],
    );
  }
} 