import '../../core/app_exception.dart';
import '../../models/picked_image.dart';
import '../../models/task.dart';
import '../contracts/task_repository.dart';
import 'fake_store.dart';

class FakeTaskRepository implements TaskRepository {
  final _store = FakeStore.instance;
  @override
  Stream<List<Task>> watchTasks(String projectId) => _store.watch(() {
    final visible = _store.projects.any(
      (p) => p.id == projectId && p.ownerId == _store.user?.id,
    );
    final result = _store.tasks
        .where((t) => visible && t.projectId == projectId)
        .toList();
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(result);
  });
  @override
  Future<Task> createTask({
    required String projectId,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    PickedImage? image,
  }) async {
    await Future<void>.delayed(FakeStore.delay);
    _store.requireProject(projectId);
    if (title.trim().isEmpty) {
      throw const AppException('Vui lòng nhập tiêu đề công việc');
    }
    final id = _store.newId();
    final task = Task(
      id: id,
      projectId: projectId,
      title: title.trim(),
      description: description?.trim(),
      status: status,
      // Ảnh minh hoạ public theo quy ước của chế độ giả.
      attachmentUrl: image == null
          ? null
          : 'https://picsum.photos/seed/$id/800/600',
      createdBy: _store.requireUser().id,
      createdAt: DateTime.now(),
    );
    _store.tasks.add(task);
    _store.notify();
    return task;
  }

  @override
  Future<void> updateStatus(String taskId, TaskStatus status) async {
    await Future<void>.delayed(FakeStore.delay);
    final task = _store.requireTask(taskId);
    _store.tasks[_store.tasks.indexOf(task)] = task.copyWith(status: status);
    _store.notify();
  }

  @override
  Future<void> deleteTask(Task task) async {
    await Future<void>.delayed(FakeStore.delay);
    _store.requireTask(task.id);
    _store.tasks.removeWhere((t) => t.id == task.id);
    _store.notify();
  }
}
