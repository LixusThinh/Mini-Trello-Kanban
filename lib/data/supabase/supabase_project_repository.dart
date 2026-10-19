import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_exception.dart';
import '../../models/project.dart';
import '../contracts/project_repository.dart';
import 'storage_paths.dart';
import 'supabase_errors.dart';

class SupabaseProjectRepository implements ProjectRepository {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Stream<List<Project>> watchMyProjects() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      return Stream.error(const AppException('Bạn chưa đăng nhập.'));
    }
    return guardStream(
      _db
          .from('projects')
          .stream(primaryKey: ['id'])
          .eq('owner_id', uid)
          .order('created_at') // mặc định giảm dần → mới nhất trước
          .map((rows) => rows.map(Project.fromJson).toList()),
    );
  }

  @override
  Future<Project> createProject({required String title, String? description}) =>
      guard(() async {
        final desc = description?.trim();
        // owner_id không truyền: DB default auth.uid(), RLS kiểm tra lại.
        final row = await _db
            .from('projects')
            .insert({
              'title': title.trim(),
              'description': (desc == null || desc.isEmpty) ? null : desc,
            })
            .select()
            .single();
        return Project.fromJson(row);
      });

  @override
  Future<void> deleteProject(String projectId) => guard(() async {
    // Xoá ảnh trước (policy storage cần project còn tồn tại), xoá theo lô 100.
    final bucket = _db.storage.from(attachmentsBucket);
    while (true) {
      final files = await bucket.list(
        path: projectId,
        searchOptions: const SearchOptions(limit: 100),
      );
      if (files.isEmpty) break;
      await bucket.remove([for (final f in files) '$projectId/${f.name}']);
    }
    // tasks xoá theo ON DELETE CASCADE.
    final deleted = await _db
        .from('projects')
        .delete()
        .eq('id', projectId)
        .select('id');
    if (deleted.isEmpty) {
      throw const AppException(
        'Không tìm thấy dự án hoặc bạn không có quyền xoá.',
      );
    }
  });
}
