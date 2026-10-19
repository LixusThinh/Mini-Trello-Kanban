import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../models/task.dart';

void showAppError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        error is AppException
            ? error.message
            : 'Có lỗi xảy ra. Vui lòng thử lại.',
      ),
    ),
  );
}

String shortStatus(TaskStatus status) => switch (status) {
  TaskStatus.todo => 'Cần làm',
  TaskStatus.inProgress => 'Đang làm',
  TaskStatus.done => 'Xong',
};

String dayMonth(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });
  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label),
  );
}
