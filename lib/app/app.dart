import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme.dart';

class MiniTrelloApp extends StatefulWidget {
  const MiniTrelloApp({super.key});

  @override
  State<MiniTrelloApp> createState() => _MiniTrelloAppState();
}

class _MiniTrelloAppState extends State<MiniTrelloApp> {
  // Tạo sau setupDependencies() vì router đọc authRepo.
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Mini Trello',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: _router,
  );
}
