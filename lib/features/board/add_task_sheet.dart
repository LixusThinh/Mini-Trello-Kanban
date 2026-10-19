import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../models/task.dart';
import '../../widgets/ui_helpers.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({
    super.key,
    required this.projectId,
    required this.initialStatus,
  });
  final String projectId;
  final TaskStatus initialStatus;
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await taskRepo.createTask(
        projectId: widget.projectId,
        title: _title.text.trim(),
        status: widget.initialStatus,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Công việc mới',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _title,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Tiêu đề *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập tiêu đề công việc'
                    : null,
              ),
              const SizedBox(height: 24),
              SubmitButton(
                label: 'Lưu công việc',
                busy: _busy,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
