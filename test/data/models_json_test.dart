import 'package:flutter_test/flutter_test.dart';
import 'package:mini_trello/models/project.dart';
import 'package:mini_trello/models/task.dart';

void main() {
  test('TaskStatus.fromDb khớp CHECK constraint của DB', () {
    expect(TaskStatus.values.map((s) => s.db), ['TODO', 'IN_PROGRESS', 'DONE']);
    for (final s in TaskStatus.values) {
      expect(TaskStatus.fromDb(s.db), s);
    }
  });

  test('Task fromJson/toJson round-trip (snake_case)', () {
    final json = {
      'id': 't1',
      'project_id': 'p1',
      'title': 'Viết báo cáo',
      'description': null,
      'status': 'IN_PROGRESS',
      'attachment_url': null,
      'created_by': 'u1',
      'created_at': '2026-10-19T01:02:03.000Z',
    };
    final task = Task.fromJson(json);
    expect(task.status, TaskStatus.inProgress);
    expect(task.toJson(), json);
  });

  test('Project fromJson đọc owner_id/created_at', () {
    final p = Project.fromJson({
      'id': 'p1',
      'title': 'Đồ án',
      'description': 'mô tả',
      'owner_id': 'u1',
      'created_at': '2026-10-19T01:02:03+00:00',
    });
    expect(p.ownerId, 'u1');
    expect(p.createdAt.toUtc(), DateTime.utc(2026, 10, 19, 1, 2, 3));
  });
}
