import '../../models/picked_image.dart';
import '../../models/task.dart';

/// Mọi lỗi ném ra là `AppException` (message tiếng Việt).
abstract class TaskRepository {
  /// Cũ nhất trước.
  Stream<List<Task>> watchTasks(String projectId);
  Future<Task> createTask({
    required String projectId,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    PickedImage? image,
  });
  Future<void> updateStatus(String taskId, TaskStatus status);

  /// Xoá cả ảnh.
  Future<void> deleteTask(Task task);
}
