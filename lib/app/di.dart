import '../core/env.dart';
import '../data/contracts/auth_repository.dart';
import '../data/contracts/project_repository.dart';
import '../data/contracts/task_repository.dart';
import '../data/fake/fake_auth_repository.dart';
import '../data/fake/fake_project_repository.dart';
import '../data/fake/fake_task_repository.dart';
import '../data/supabase/supabase_auth_repository.dart';
import '../data/supabase/supabase_project_repository.dart';
import '../data/supabase/supabase_task_repository.dart';

// UI chỉ gọi repository qua 3 biến này, không import supabase_flutter.
late final AuthRepository authRepo;
late final ProjectRepository projectRepo;
late final TaskRepository taskRepo;

/// `USE_FAKE=true` → repo in-memory; ngược lại → Supabase.
/// Widget test gọi `setupDependencies(useFake: true)` (một lần mỗi file test).
void setupDependencies({bool useFake = Env.useFake}) {
  if (useFake) {
    authRepo = FakeAuthRepository();
    projectRepo = FakeProjectRepository();
    taskRepo = FakeTaskRepository();
  } else {
    authRepo = SupabaseAuthRepository();
    projectRepo = SupabaseProjectRepository();
    taskRepo = SupabaseTaskRepository();
  }
}
