import 'package:flutter/material.dart';

import '../../models/project.dart';

/// Placeholder Phase 0 để router compile — Codex thay nội dung trên nhánh feat/ui.
/// Giữ nguyên tên class + constructor: lib/app/router.dart gọi `BoardScreen(project: project)`.
class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(project.title)));
}
