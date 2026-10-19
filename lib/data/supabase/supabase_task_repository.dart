import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_exception.dart';
import '../../models/picked_image.dart';
import '../../models/task.dart';
import '../contracts/task_repository.dart';
import 'storage_paths.dart';
import 'supabase_errors.dart';

class SupabaseTaskRepository implements TaskRepository {
  SupabaseClient get _db => Supabase.instance.client;
  StorageFileApi get _bucket => _db.storage.from(attachmentsBucket);

  @override
  Stream<List<Task>> watchTasks(String projectId) => guardStream(
    _db
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('created_at', ascending: true) // cũ nhất trước
        .map((rows) => rows.map(Task.fromJson).toList()),
  );

  @override
  Future<Task> createTask({
    required String projectId,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    PickedImage? image,
  }) => guard(() async {
    String? path;
    String? url;
    if (image != null) {
      if (image.bytes.length > maxAttachmentBytes) {
        throw const AppException('Ảnh vượt quá 5MB.');
      }
      final ext = extensionForMime(image.mimeType);
      path = attachmentPath(projectId, const Uuid().v4(), ext);
      await _bucket.uploadBinary(
        path,
        image.bytes,
        fileOptions: FileOptions(contentType: image.mimeType),
      );
      url = _bucket.getPublicUrl(path);
    }
    final desc = description?.trim();
    try {
      // created_by không truyền: DB default auth.uid(), RLS kiểm tra lại.
      final row = await _db
          .from('tasks')
          .insert({
            'project_id': projectId,
            'title': title.trim(),
            'description': (desc == null || desc.isEmpty) ? null : desc,
            'status': status.db,
            'attachment_url': url,
          })
          .select()
          .single();
      return Task.fromJson(row);
    } catch (_) {
      // Insert hỏng → dọn ảnh vừa upload, không để rác trong Storage.
      if (path != null) {
        try {
          await _bucket.remove([path]);
        } catch (_) {}
      }
      rethrow;
    }
  });

  @override
  Future<void> updateStatus(String taskId, TaskStatus status) =>
      guard(() async {
        final updated = await _db
            .from('tasks')
            .update({'status': status.db})
            .eq('id', taskId)
            .select('id');
        if (updated.isEmpty) {
          throw const AppException(
            'Không tìm thấy công việc hoặc bạn không có quyền sửa.',
          );
        }
      });

  @override
  Future<void> deleteTask(Task task) => guard(() async {
    final url = task.attachmentUrl;
    final path = url == null ? null : objectPathFromPublicUrl(url);
    if (path != null) await _bucket.remove([path]);
    final deleted = await _db
        .from('tasks')
        .delete()
        .eq('id', task.id)
        .select('id');
    if (deleted.isEmpty) {
      throw const AppException(
        'Không tìm thấy công việc hoặc bạn không có quyền xoá.',
      );
    }
  });
}
