import '../../models/project.dart';

/// Mọi lỗi ném ra là `AppException` (message tiếng Việt).
abstract class ProjectRepository {
  /// Mới nhất trước.
  Stream<List<Project>> watchMyProjects();
  Future<Project> createProject({required String title, String? description});

  /// Xoá cả ảnh trong storage.
  Future<void> deleteProject(String projectId);
}
