import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../app/theme.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../widgets/connection_pill.dart';
import '../../widgets/ui_helpers.dart';
import 'add_task_sheet.dart';
import 'task_card.dart';
import 'task_detail_sheet.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.project});
  final Project project;
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);
  late final _tasks = taskRepo.watchTasks(widget.project.id);
  Object? _lastStreamError;
  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Task>>(
    stream: _tasks,
    builder: (context, snapshot) {
      if (snapshot.hasError && !identical(_lastStreamError, snapshot.error)) {
        _lastStreamError = snapshot.error;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showAppError(context, snapshot.error!);
        });
      } else if (!snapshot.hasError) {
        _lastStreamError = null;
      }
      final tasks = snapshot.data ?? [];
      final done = tasks.where((t) => t.status == TaskStatus.done).length;
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.project.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.project.description?.isNotEmpty ?? false)
                Text(
                  widget.project.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ConnectionPill(
                connected: snapshot.hasData && !snapshot.hasError,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$done/${tasks.length} việc đã xong',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: tasks.isEmpty ? 0 : done / tasks.length,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(14),
                        color: statusColor(TaskStatus.done),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(),
            if (snapshot.hasError)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Không tải được công việc. Vui lòng thử lại.'),
              ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabs,
                dividerHeight: 0,
                labelPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(11),
                ),
                tabs: [
                  for (final status in TaskStatus.values)
                    Tab(
                      height: 56,
                      child: DragTarget<Task>(
                        onWillAcceptWithDetails: (details) =>
                            details.data.status != status,
                        onAcceptWithDetails: (details) async {
                          try {
                            await taskRepo.updateStatus(
                              details.data.id,
                              status,
                            );
                          } catch (e) {
                            if (context.mounted) showAppError(context, e);
                          }
                        },
                        builder: (context, candidates, _) => AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          decoration: candidates.isEmpty
                              ? null
                              : BoxDecoration(
                                  color: statusColor(status)
                                      .withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    statusIcon(status),
                                    size: 17,
                                    color: statusColor(status),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor(status)
                                          .withValues(alpha: .15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${tasks.where((t) => t.status == status).length}',
                                      style: TextStyle(
                                        color: statusColor(status),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                shortStatus(status),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  for (final status in TaskStatus.values)
                    _taskList(tasks.where((t) => t.status == status).toList()),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Thêm công việc',
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => AddTaskSheet(
              projectId: widget.project.id,
              initialStatus: TaskStatus.values[_tabs.index],
            ),
          ),
          child: const Icon(Icons.add_task_rounded),
        ),
      );
    },
  );
  Widget _taskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text('Chưa có việc nào ở đây'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => TaskCard(
        task: tasks[index],
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => TaskDetailSheet(task: tasks[index]),
        ),
        draggable: true,
      ),
    );
  }
}
