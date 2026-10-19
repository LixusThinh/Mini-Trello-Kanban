import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../app/theme.dart';
import '../../models/task.dart';
import '../../widgets/ui_helpers.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.draggable = false,
  });
  final Task task;
  final VoidCallback onTap;
  final bool draggable;
  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _busy = false;
  Future<bool> _move(DismissDirection direction) async {
    if (_busy) return false;
    final next =
        widget.task.status.index +
        (direction == DismissDirection.startToEnd ? 1 : -1);
    if (next < 0 || next >= TaskStatus.values.length) return false;
    setState(() => _busy = true);
    try {
      await taskRepo.updateStatus(widget.task.id, TaskStatus.values[next]);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    return false;
  }

  Widget _background(TaskStatus status, Alignment alignment) => Container(
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: statusColor(status).withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      shortStatus(status),
      style: TextStyle(color: statusColor(status), fontWeight: FontWeight.bold),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final direction = _busy
        ? DismissDirection.none
        : switch (task.status) {
            TaskStatus.todo => DismissDirection.startToEnd,
            TaskStatus.inProgress => DismissDirection.horizontal,
            TaskStatus.done => DismissDirection.endToStart,
          };
    final card = Dismissible(
      key: ValueKey('swipe-${task.id}'),
      direction: direction,
      confirmDismiss: _move,
      background: _background(
        TaskStatus.values[(task.status.index + 1).clamp(0, 2)],
        Alignment.centerLeft,
      ),
      secondaryBackground: _background(
        TaskStatus.values[(task.status.index - 1).clamp(0, 2)],
        Alignment.centerRight,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _busy ? null : widget.onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: statusColor(task.status)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (task.description?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 6),
                          Text(
                            task.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (_busy)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                ),
                if (task.attachmentUrl != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox.square(
                        dimension: 64,
                        child: TaskImage(url: task.attachmentUrl!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!widget.draggable) return card;
    return LongPressDraggable<Task>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width - 32,
          child: Opacity(opacity: .9, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: card),
      child: card,
    );
  }
}

class TaskImage extends StatelessWidget {
  const TaskImage({super.key, required this.url, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => Image.network(
    url,
    fit: fit,
    semanticLabel: 'Ảnh đính kèm công việc',
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : const Center(
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
    errorBuilder: (context, error, stackTrace) => ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          semanticLabel: 'Không tải được ảnh',
        ),
      ),
    ),
  );
}
