import '../../models/project.dart';
import '../contracts/project_repository.dart';

/// Stub Phase 0 — Codex implement trên nhánh feat/ui (in-memory, StreamController.broadcast).
/// Giữ constructor không tham số: lib/app/di.dart gọi `FakeXxxRepository()`.
class FakeProjectRepository implements ProjectRepository {
  @override
  Stream<List<Project>> watchMyProjects() => throw UnimplementedError();

  @override
  Future<Project> createProject({required String title, String? description}) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProject(String projectId) => throw UnimplementedError();
}
