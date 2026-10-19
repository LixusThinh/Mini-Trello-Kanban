import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../app/theme.dart';
import '../../models/task.dart';
import '../../widgets/ui_helpers.dart';
import 'task_card.dart';

class TaskDetailSheet extends StatefulWidget {
  const TaskDetailSheet({super.key, required this.task});
  final Task task;
  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  late TaskStatus _status = widget.task.status;
  bool _busy = false;

  Future<void> _change(TaskStatus status) async {
    if (_busy || status == _status) return;
    setState(() => _busy = true);
    try {
      await taskRepo.updateStatus(widget.task.id, status);
      if (mounted) setState(() => _status = status);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Xoá công việc?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Công việc và ảnh đính kèm sẽ bị xoá vĩnh viễn.'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xoá công việc'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Huỷ'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await taskRepo.deleteTask(widget.task);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.task.attachmentUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Hero(
                  tag: 'task-image-${widget.task.id}',
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _FullImage(task: widget.task),
                      ),
                    ),
                    child: SizedBox(
                      height: 230,
                      child: TaskImage(url: widget.task.attachmentUrl!),
                    ),
                  ),
                ),
              ),
            ),
          Text(
            widget.task.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (widget.task.description?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(widget.task.description!),
            ),
          const SizedBox(height: 10),
          Text(
            'Tạo ngày ${dayMonth(widget.task.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 22),
          SegmentedButton<TaskStatus>(
            segments: [
              for (final status in TaskStatus.values)
                ButtonSegment(
                  value: status,
                  label: Text(shortStatus(status)),
                  icon: Icon(statusIcon(status)),
                ),
            ],
            selected: {_status},
            onSelectionChanged: _busy ? null : (value) => _change(value.first),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _busy ? null : _delete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            label: Text(
              'Xoá công việc',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}

class _FullImage extends StatelessWidget {
  const _FullImage({required this.task});
  final Task task;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.scrim,
    appBar: AppBar(foregroundColor: Theme.of(context).colorScheme.onSurface),
    body: Center(
      child: Hero(
        tag: 'task-image-${task.id}',
        child: InteractiveViewer(child: TaskImage(url: task.attachmentUrl!)),
      ),
    ),
  );
}
