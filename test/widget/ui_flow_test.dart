import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_trello/app/di.dart';
import 'package:mini_trello/app/theme.dart';
import 'package:mini_trello/features/auth/login_screen.dart';
import 'package:mini_trello/features/board/board_screen.dart';
import 'package:mini_trello/models/project.dart';

void main() {
  setUpAll(() => setupDependencies(useFake: true));

  testWidgets('Đăng nhập kiểm tra email và độ dài mật khẩu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: const LoginScreen()),
    );
    await tester.tap(find.text('Đăng nhập').first);
    await tester.pump();
    expect(find.text('Vui lòng nhập email hợp lệ'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'an@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Đăng nhập').first);
    await tester.pump();
    expect(find.text('Mật khẩu phải có ít nhất 6 ký tự'), findsOneWidget);
  });

  testWidgets('Bảng công việc hiển thị đủ ba trạng thái', (tester) async {
    final project = Project(
      id: 'demo-project',
      title: 'Dự án Mini Trello',
      description: 'Bảng kiểm thử',
      ownerId: 'demo-user',
      createdAt: DateTime(2026, 10, 19),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: BoardScreen(project: project),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Cần làm'), findsOneWidget);
    expect(find.text('Đang làm'), findsOneWidget);
    expect(find.text('Xong'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
