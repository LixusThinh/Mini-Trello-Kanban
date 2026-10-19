import '../../core/app_exception.dart';
import '../../models/project.dart';
import '../contracts/project_repository.dart';
import 'fake_store.dart';

class FakeProjectRepository implements ProjectRepository {
  final _store = FakeStore.instance;
  @override
  Stream<List<Project>> watchMyProjects() => _store.watch(() {
    final result = _store.projects
        .where((p) => p.ownerId == _store.user?.id)
        .toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  });
  @override
  Future<Project> createProject({
    required String title,
    String? description,
  }) async {
    await Future<void>.delayed(FakeStore.delay);
    final user = _store.requireUser();
    if (title.trim().isEmpty) {
      throw const AppException('Vui lòng nhập tên dự án');
    }
    final project = Project(
      id: _store.newId(),
      title: title.trim(),
      description: description?.trim(),
      ownerId: user.id,
      createdAt: DateTime.now(),
    );
    _store.projects.add(project);
    _store.notify();
    return project;
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await Future<void>.delayed(FakeStore.delay);
    _store.requireProject(projectId);
    _store.tasks.removeWhere((t) => t.projectId == projectId);
    _store.projects.removeWhere((p) => p.id == projectId);
    _store.notify();
  }
}
