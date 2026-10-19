import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/board/board_screen.dart';
import '../features/projects/projects_screen.dart';
import '../models/project.dart';
import 'di.dart';

abstract final class Routes {
  static const login = '/login';
  static const register = '/register';
  static const projects = '/projects';

  /// Điều hướng: `context.push(Routes.board(p.id), extra: p)`.
  static String board(String projectId) => '/projects/$projectId';
}

GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.projects,
  refreshListenable: _StreamListenable(authRepo.watchUser()),
  redirect: (context, state) {
    final loggedIn = authRepo.currentUser != null;
    final loc = state.matchedLocation;
    final onAuthRoute = loc == Routes.login || loc == Routes.register;
    if (!loggedIn) return onAuthRoute ? null : Routes.login;
    if (onAuthRoute) return Routes.projects;
    // /projects/:id cần extra = Project; mất extra (vd. restore state) → về danh sách.
    if (state.pathParameters.containsKey('id') && state.extra is! Project) {
      return Routes.projects;
    }
    return null;
  },
  routes: [
    GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
    GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
    GoRoute(
      path: Routes.projects,
      builder: (_, _) => const ProjectsScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => BoardScreen(project: state.extra! as Project),
        ),
      ],
    ),
  ],
);

/// Biến stream đăng nhập/đăng xuất thành Listenable cho `refreshListenable`.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
