import 'package:flutter/material.dart';
import '../models/project.dart';
import '../screens/project_detail_screen.dart';
import '../screens/project_detail_manager_screen.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class ProjectList extends StatelessWidget {
  final List<Project> projects;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final bool isLoading;

  const ProjectList({
    Key? key,
    required this.projects,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无项目数据',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // 创建项目列表项
    List<Widget> listItems = [];
    
    // 添加项目卡片
    for (int i = 0; i < projects.length; i++) {
      listItems.add(ProjectCard(project: projects[i]));
    }
    
    // 如果有多个页面，添加分页控件
    if (totalPages > 1) {
      listItems.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: currentPage > 1 
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                color: currentPage > 1 ? AppTheme.primaryColor : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                '$currentPage / $totalPages',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: currentPage < totalPages 
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                color: currentPage < totalPages ? AppTheme.primaryColor : Colors.grey,
              ),
            ],
          ),
        )
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: listItems,
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.projectName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: project.getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: project.getStatusColor(),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        project.status == 0 ? Icons.access_time : Icons.check_circle,
                        color: project.getStatusColor(),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        project.getStatusText(),
                        style: TextStyle(
                          color: project.getStatusColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '截止日期: ${project.getFormattedDeadline()}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    // 根据用户类型决定使用哪个项目详情页面
                    final userType = await AuthService.getUserType();
                    if (userType == '0') { // 项目经理视图
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailManagerScreen(
                            projectId: project.id,
                          ),
                        ),
                      );
                    } else { // 员工视图
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailScreen(
                            projectId: project.id,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('查看详情'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 