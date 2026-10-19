import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/task.dart';

class ConnectionPill extends StatefulWidget {
  const ConnectionPill({super.key, required this.connected});
  final bool connected;
  @override
  State<ConnectionPill> createState() => _ConnectionPillState();
}

class _ConnectionPillState extends State<ConnectionPill>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final _opacity = Tween<double>(begin: .4, end: 1).animate(_controller);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.connected
        ? statusColor(TaskStatus.done)
        : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: widget.connected
                ? _opacity
                : const AlwaysStoppedAnimation(1),
            child: Text('●', style: TextStyle(color: color)),
          ),
          const SizedBox(width: 5),
          Text(
            widget.connected ? 'Trực tiếp' : 'Mất kết nối',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
