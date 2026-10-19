import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../widgets/ui_helpers.dart';

class AccountSheet extends StatefulWidget {
  const AccountSheet({super.key, required this.name, required this.email});
  final String name;
  final String email;
  @override
  State<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<AccountSheet> {
  bool _busy = false;
  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await authRepo.signOut();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(widget.email),
          const SizedBox(height: 24),
          SubmitButton(label: 'Đăng xuất', busy: _busy, onPressed: _signOut),
        ],
      ),
    ),
  );
}

class CreateProjectSheet extends StatefulWidget {
  const CreateProjectSheet({super.key});
  @override
  State<CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends State<CreateProjectSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await projectRepo.createProject(
        title: _title.text.trim(),
        description: _description.text.trim(),
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
                'Dự án mới',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _title,
                enabled: !_busy,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Tên dự án *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập tên dự án'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                enabled: !_busy,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 24),
              SubmitButton(label: 'Tạo dự án', busy: _busy, onPressed: _save),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<bool?> showDeleteSheet(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() onDelete,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  builder: (_) =>
      _DeleteSheet(title: title, message: message, onDelete: onDelete),
);

class _DeleteSheet extends StatefulWidget {
  const _DeleteSheet({
    required this.title,
    required this.message,
    required this.onDelete,
  });
  final String title;
  final String message;
  final Future<void> Function() onDelete;
  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> {
  bool _busy = false;
  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await widget.onDelete();
      if (mounted) Navigator.pop(context, true);
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(widget.message),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: _busy ? null : _delete,
            child: _busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Xoá'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
        ],
      ),
    ),
  );
}
