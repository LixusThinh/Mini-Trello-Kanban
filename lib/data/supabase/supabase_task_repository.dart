import '../../models/picked_image.dart';
import '../../models/task.dart';
import '../contracts/task_repository.dart';

/// Stub Phase 0 — Claude Code implement trên nhánh feat/backend.
class SupabaseTaskRepository implements TaskRepository {
  @override
  Stream<List<Task>> watchTasks(String projectId) => throw UnimplementedError();

  @override
  Future<Task> createTask({
    required String projectId,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    PickedImage? image,
  }) => throw UnimplementedError();

  @override
  Future<void> updateStatus(String taskId, TaskStatus status) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTask(Task task) => throw UnimplementedError();
}
