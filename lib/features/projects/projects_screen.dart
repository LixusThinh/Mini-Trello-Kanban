import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/project.dart';
import '../../widgets/dashed_border.dart';
import '../../widgets/ui_helpers.dart';
import 'project_sheets.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late final _projects = projectRepo.watchMyProjects();
  String _name = '';
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await authRepo.getMyProfile();
      if (mounted) setState(() => _name = profile?.fullName.trim() ?? '');
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _actions(Project project) async {
    final remove = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Xoá dự án',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.pop(context, true),
          ),
        ),
      ),
    );
    if (remove == true && mounted) {
      await showDeleteSheet(
        context,
        title: 'Xoá "${project.title}"?',
        message: 'Mọi công việc và ảnh đính kèm sẽ bị xoá vĩnh viễn.',
        onDelete: () => projectRepo.deleteProject(project.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = authRepo.currentUser?.email ?? '';
    final name = _name.isNotEmpty ? _name : email.split('@').first;
    final now = DateTime.now();
    final weekday = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ][now.weekday - 1];
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Project>>(
          stream: _projects,
          builder: (context, snapshot) {
            final projects = snapshot.data ?? [];
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$weekday, ${dayMonth(now)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Xin chào, $name 👋',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              tooltip: 'Tài khoản',
                              onPressed: () => showModalBottomSheet<void>(
                                context: context,
                                builder: (_) =>
                                    AccountSheet(name: name, email: email),
                              ),
                              icon: CircleAvatar(
                                child: Text(
                                  name.isEmpty
                                      ? '?'
                                      : name.characters.first.toUpperCase(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '${projects.length} dự án',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: LinearProgressIndicator(),
                          ),
                        if (snapshot.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Không tải được dự án. Vui lòng thử lại.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) => SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: constraints.crossAxisExtent < 360
                            ? 210
                            : 220,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == 0) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const CreateProjectSheet(),
                              ),
                              child: const DashedBorder(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_rounded, size: 36),
                                    SizedBox(height: 12),
                                    Text('Dự án mới'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        final project = projects[index - 1];
                        return Semantics(
                          button: true,
                          hint: 'Nhấn giữ để mở hành động dự án',
                          child: Material(
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.antiAlias,
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors:
                                      AppColors.projectPalette[project
                                              .id
                                              .hashCode
                                              .abs() %
                                          AppColors.projectPalette.length],
                                ),
                              ),
                              child: InkWell(
                                onTap: () => context.push(
                                  Routes.board(project.id),
                                  extra: project,
                                ),
                                onLongPress: () => _actions(project),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.view_kanban_outlined,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        project.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        project.description ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: .8,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Tạo ${dayMonth(project.createdAt)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }, childCount: projects.length + 1),
                    ),
                  ),
                ),
                if (projects.isEmpty &&
                    !snapshot.hasError &&
                    snapshot.connectionState != ConnectionState.waiting)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.dashboard_customize_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bắt đầu với dự án đầu tiên',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Mỗi dự án là một bảng công việc riêng.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}
