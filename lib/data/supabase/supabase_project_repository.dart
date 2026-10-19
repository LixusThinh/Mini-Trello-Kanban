import '../../models/project.dart';
import '../contracts/project_repository.dart';

/// Stub Phase 0 — Claude Code implement trên nhánh feat/backend.
class SupabaseProjectRepository implements ProjectRepository {
  @override
  Stream<List<Project>> watchMyProjects() => throw UnimplementedError();

  @override
  Future<Project> createProject({required String title, String? description}) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProject(String projectId) => throw UnimplementedError();
}
