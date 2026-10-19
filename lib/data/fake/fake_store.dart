import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../core/app_exception.dart';
import '../../models/app_user.dart';
import '../../models/profile.dart';
import '../../models/project.dart';
import '../../models/task.dart';

/// Kho dữ liệu dùng chung trong một lần chạy ứng dụng.
class FakeStore {
  FakeStore._() {
    accounts['demo@hutech.edu.vn'] = (
      user: const AppUser(id: 'demo-user', email: 'demo@hutech.edu.vn'),
      password: '123456',
      profile: const Profile(id: 'demo-user', fullName: 'Nguyễn Văn A'),
    );
    final now = DateTime.now();
    projects.add(
      Project(
        id: 'demo-project',
        title: 'Dự án Mini Trello',
        description: 'Cùng lên kế hoạch và theo dõi công việc mỗi ngày.',
        ownerId: 'demo-user',
        createdAt: now,
      ),
    );
    for (final status in TaskStatus.values) {
      tasks.add(
        Task(
          id: 'demo-${status.name}',
          projectId: 'demo-project',
          title: [
            'Lên ý tưởng giao diện',
            'Xây dựng bảng công việc',
            'Khởi tạo dự án',
          ][status.index],
          description: 'Công việc mẫu để khám phá bảng Kanban.',
          status: status,
          createdBy: 'demo-user',
          createdAt: now.add(Duration(seconds: status.index)),
        ),
      );
    }
  }
  static final instance = FakeStore._();
  static const delay = Duration(milliseconds: 300);
  final accounts =
      <String, ({AppUser user, String password, Profile profile})>{};
  final projects = <Project>[];
  final tasks = <Task>[];
  final changes = StreamController<void>.broadcast();
  AppUser? user;
  String newId() => const Uuid().v4();
  void notify() => changes.add(null);
  Stream<T> watch<T>(T Function() snapshot) => Stream<T>.multi((listener) {
    final subscription = changes.stream.listen((_) => listener.add(snapshot()));
    listener.add(snapshot());
    listener.onCancel = subscription.cancel;
  });
  AppUser requireUser() =>
      user ?? (throw const AppException('Vui lòng đăng nhập để tiếp tục'));
  Project requireProject(String id) {
    final owner = requireUser();
    for (final project in projects) {
      if (project.id == id && project.ownerId == owner.id) return project;
    }
    throw const AppException('Không tìm thấy dự án');
  }

  Task requireTask(String id) {
    for (final task in tasks) {
      if (task.id == id) {
        requireProject(task.projectId);
        return task;
      }
    }
    throw const AppException('Không tìm thấy công việc');
  }
}
