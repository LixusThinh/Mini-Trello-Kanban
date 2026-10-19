import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/di.dart';
import '../../app/theme.dart';
import '../../models/picked_image.dart';
import '../../models/task.dart';
import '../../widgets/dashed_border.dart';
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
  final _description = TextEditingController();
  late TaskStatus _status = widget.initialStatus;
  PickedImage? _image;
  bool _busy = false;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file == null) return;
      final name = file.name;
      final ext = name.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        _ => 'application/octet-stream',
      };
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(
        () =>
            _image = PickedImage(bytes: bytes, fileName: name, mimeType: mime),
      );
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await taskRepo.createTask(
        projectId: widget.projectId,
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        status: _status,
        image: _image,
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
              const SizedBox(height: 20),
              TextFormField(
                controller: _title,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Tiêu đề *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập tiêu đề công việc'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                enabled: !_busy,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 18),
              SegmentedButton<TaskStatus>(
                segments: [
                  for (final s in TaskStatus.values)
                    ButtonSegment(
                      value: s,
                      label: Text(shortStatus(s)),
                      icon: Icon(statusIcon(s)),
                    ),
                ],
                selected: {_status},
                onSelectionChanged: _busy
                    ? null
                    : (v) => setState(() => _status = v.first),
              ),
              const SizedBox(height: 16),
              if (_image == null)
                DashedBorder(
                  child: InkWell(
                    onTap: _busy ? null : _pickImage,
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.all(22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined),
                          SizedBox(width: 10),
                          Text('Chạm để thêm ảnh'),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _image!.bytes,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _image = null),
                      icon: const Icon(Icons.close),
                      tooltip: 'Xoá ảnh',
                    ),
                  ],
                ),
              const SizedBox(height: 20),
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
