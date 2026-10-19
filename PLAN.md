# Mini Trello / Kanban — Flutter + Supabase

Bài tập: dùng đủ 3 mảng của Supabase — **Database** (profiles/projects/tasks + RLS + Realtime), **Authentication** (email/password), **Storage** (ảnh đính kèm task). Clone đúng UI/flow trong ảnh demo của thầy, làm chắc phần bảo mật hơn bản demo.

Hai agent chạy song song:

| Agent | Vai | Sở hữu |
|---|---|---|
| **Claude Code** | Backend + data layer + tích hợp | `supabase/**`, `lib/data/supabase/**`, config native (Android/iOS), `test/data/**`, merge cuối |
| **Codex** | UI/UX toàn bộ màn hình | `lib/features/**`, `lib/widgets/**`, `lib/data/fake/**`, `test/widget/**` |

File chung (contract) do **Claude Code** viết ở Phase 0 và là người duy nhất được sửa: `pubspec.yaml`, `lib/main.dart`, `lib/app/**`, `lib/core/**`, `lib/models/**`, `lib/data/contracts/**`.

---

## 0. Kết nối Supabase (người làm: mày, ~10 phút)

1. **Tạo project** tại supabase.com → New project → region **Southeast Asia (Singapore)** → đặt DB password (lưu lại).
2. **Chạy schema**: Dashboard → **SQL Editor** → New query → dán toàn bộ `supabase/migrations/0001_init.sql` → **Run**. Kết quả phải là `Success. No rows returned`.
   - Script đã có sẵn: 3 bảng, index FK, trigger tạo profile, GRANT, RLS, bật Realtime cho `tasks`/`projects`, bucket `task-attachments` + 4 policy storage.
3. **Auth**: Authentication → Sign In / Providers → **Email** bật sẵn. Khi dev nên **tắt "Confirm email"** (SMTP mặc định của gói Free bị giới hạn số mail/giờ, đăng ký test vài lần là kẹt). Lúc demo cho thầy muốn bật lại thì bật.
4. **Lấy key**: bấm nút **Connect** trên thanh trên cùng → copy **Project URL** và **Publishable key** (`sb_publishable_...`). Nếu project cũ chỉ có legacy `anon` key thì dùng `anon`.
   **CẤM** dùng `secret` / `service_role` key trong app.
5. **Tạo `env.json`** ở root project Flutter (đã nằm trong `.gitignore`):
   ```json
   {
     "SUPABASE_URL": "https://<project-ref>.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_xxx"
   }
   ```
6. **Chạy app**: `flutter run --dart-define-from-file=env.json`
   VS Code thì thêm vào `.vscode/launch.json`: `"args": ["--dart-define-from-file=env.json"]`.
7. **(Tuỳ chọn) Cho Claude Code đụng thẳng DB qua Supabase MCP**:
   `claude mcp add --transport http supabase "https://mcp.supabase.com/mcp?project_ref=<project-ref>"` → trong Claude Code gõ `/mcp` → authenticate qua browser. Có MCP thì nó tự chạy `execute_sql`, `get_advisors` để verify thay vì bắt mày copy-paste.

Code khởi tạo (Phase 0 sẽ viết, để đây cho mày hiểu):
```dart
// lib/core/env.dart
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
}

// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  assert(Env.supabaseUrl.isNotEmpty, 'Thiếu --dart-define-from-file=env.json');
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseKey, // supabase_flutter bản cũ: đổi thành anonKey:
  );
  setupDependencies();           // lib/app/di.dart
  runApp(const MiniTrelloApp());
}
// mọi chỗ khác: Supabase.instance.client
```

---

## 1. Kiến trúc

```
lib/
├─ main.dart
├─ app/        di.dart (chọn repo thật/fake), router.dart (go_router + auth redirect), theme.dart
├─ core/       env.dart, app_exception.dart
├─ models/     app_user.dart, profile.dart, project.dart, task.dart (+ TaskStatus), picked_image.dart
├─ data/
│  ├─ contracts/   auth_repository.dart, project_repository.dart, task_repository.dart   ← CONTRACT
│  ├─ supabase/    (Claude Code) bản thật
│  └─ fake/        (Codex) bản in-memory để dựng UI không cần mạng
├─ features/   (Codex) auth/, projects/, board/
└─ widgets/    (Codex) widget dùng chung
supabase/migrations/0001_init.sql
```

**Package** (pin version, commit `pubspec.lock`): `supabase_flutter` (2.x mới nhất), `go_router`, `image_picker`, `uuid`. Không thêm state-management nặng — repo + `StreamBuilder` là đủ cho bài này.

**Realtime**: dùng `client.from('tasks').stream(primaryKey: ['id']).eq('project_id', id).order('created_at')`. Nó tự load lần đầu + nghe INSERT/UPDATE/DELETE, máy A đổi trạng thái thì máy B nhảy theo. Không tự viết channel tay.

**Storage**: bucket public `task-attachments`, path `{project_id}/{uuid}.{ext}`. Upload xong lấy `getPublicUrl` lưu vào `tasks.attachment_url`. Xoá task → xoá luôn object; xoá project → list folder `{project_id}/` rồi remove hết, sau đó mới delete row (tasks cascade theo).

---

## 2. Contract (Phase 0 — viết NGUYÊN VĂN thế này)

```dart
// models/task.dart
enum TaskStatus {
  todo('TODO', 'Cần làm (To Do)'),
  inProgress('IN_PROGRESS', 'Đang làm (In Progress)'),
  done('DONE', 'Hoàn thành (Done)');
  const TaskStatus(this.db, this.label);
  final String db;
  final String label;
  static TaskStatus fromDb(String v) => values.firstWhere((s) => s.db == v);
}

class AppUser  { final String id; final String email; }
class Profile  { final String id; final String fullName; final String? avatarUrl; }
class Project  { final String id; final String title; final String? description;
                 final String ownerId; final DateTime createdAt; }
class Task     { final String id; final String projectId; final String title;
                 final String? description; final TaskStatus status;
                 final String? attachmentUrl; final String createdBy; final DateTime createdAt; }
class PickedImage { final Uint8List bytes; final String fileName; final String mimeType; }
// tất cả model: const constructor + fromJson/toJson (snake_case <-> camelCase) + copyWith

// core/app_exception.dart — repo LUÔN ném cái này, message tiếng Việt, UI chỉ việc show SnackBar
class AppException implements Exception { final String message; const AppException(this.message); }

// data/contracts/auth_repository.dart
abstract class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> watchUser();
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String fullName, required String email, required String password});
  Future<void> signOut();
  Future<Profile?> getMyProfile();
}

// data/contracts/project_repository.dart
abstract class ProjectRepository {
  Stream<List<Project>> watchMyProjects();               // mới nhất trước
  Future<Project> createProject({required String title, String? description});
  Future<void> deleteProject(String projectId);          // xoá cả ảnh trong storage
}

// data/contracts/task_repository.dart
abstract class TaskRepository {
  Stream<List<Task>> watchTasks(String projectId);       // cũ nhất trước
  Future<Task> createTask({required String projectId, required String title,
      String? description, TaskStatus status = TaskStatus.todo, PickedImage? image});
  Future<void> updateStatus(String taskId, TaskStatus status);
  Future<void> deleteTask(Task task);                    // xoá cả ảnh
}
```

`lib/app/di.dart`: biến global `late final AuthRepository authRepo; late final ProjectRepository projectRepo; late final TaskRepository taskRepo;`. `setupDependencies()` đọc `const bool.fromEnvironment('USE_FAKE')` → `true` thì dùng `Fake*`, ngược lại dùng `Supabase*`. Phase 0 tạo sẵn stub `Fake*` và `Supabase*` (throw `UnimplementedError`) để cả 2 nhánh compile được.

`lib/app/router.dart`: `/login`, `/register`, `/projects`, `/projects/:id` (extra = `Project`). `redirect`: chưa login → `/login`; đã login mà đứng ở auth route → `/projects`. `refreshListenable` bám `authRepo.watchUser()`.

`lib/app/theme.dart`: Material 3, `ColorScheme.fromSeed(seedColor: Color(0xFF2E6B4F))`, nền `Color(0xFFF1F7F1)`, nút chính bo tròn full (StadiumBorder) màu xanh đậm, FAB extended màu mint `Color(0xFFA8EBCB)`, input `OutlineInputBorder` bo 8.

---

## 3. Phân việc

### Phase 0 — Claude Code (tuần tự, làm xong mới chia nhánh)
- [ ] `flutter create --org vn.edu.hutech --platforms android,ios mini_trello`
- [ ] `git init`, `.gitignore` thêm `env.json`; tạo `env.example.json`
- [ ] Thêm package, viết toàn bộ file contract ở mục 2 + stub
- [ ] `flutter analyze` sạch → commit `chore: contract v1` → tag `contract-v1`
- [ ] `git worktree add ../mt-backend -b feat/backend` và `git worktree add ../mt-ui -b feat/ui`

### Nhánh A — Claude Code (`feat/backend`)
- [ ] Copy `supabase/migrations/0001_init.sql` vào repo; nếu có MCP thì apply + chạy `get_advisors`, sửa hết cảnh báo Security
- [ ] `SupabaseAuthRepository`: `signUp(..., data: {'full_name': fullName})`; map `AuthException` → `AppException` tiếng Việt (sai mật khẩu, email đã tồn tại, mật khẩu < 6 ký tự, chưa xác nhận email); `getMyProfile` đọc bảng `profiles`
- [ ] `SupabaseProjectRepository`: stream `projects` filter `owner_id`; create không truyền `owner_id` (DB default `auth.uid()`); delete = list+remove storage folder → delete row
- [ ] `SupabaseTaskRepository`: stream theo `project_id`; create = upload ảnh (`uploadBinary` với `FileOptions(contentType: mime)`) → `getPublicUrl` → insert; nếu insert lỗi thì remove ảnh vừa up (không để rác); delete = remove object (parse path từ URL) → delete row
- [ ] Native: Android `INTERNET` permission trong `AndroidManifest.xml`; iOS `NSPhotoLibraryUsageDescription` + `NSCameraUsageDescription` trong `Info.plist`
- [ ] Test RLS bằng SQL (mục 4) với 2 user
- [ ] Unit test map JSON ↔ model trong `test/data/`

### Nhánh B — Codex (`feat/ui`), chạy bằng `flutter run --dart-define=USE_FAKE=true`
- [ ] `Fake*Repository` in-memory dùng `StreamController.broadcast`, seed 1 user + 1 project + 3 task, delay 300ms giả mạng
- [ ] **LoginScreen**: icon lưới 2x2 có dấu "+", tiêu đề "Mini Trello / Kanban", phụ đề "Đăng nhập để quản lý dự án & công việc", field Email (icon thư), Mật khẩu (icon khoá, nút ẩn/hiện), nút "Đăng nhập", dòng "Chưa có tài khoản? **Đăng ký ngay**"
- [ ] **RegisterScreen**: "Tạo tài khoản mới" / "Điền thông tin bên dưới để bắt đầu", Họ và tên, Email, Mật khẩu, nút "Tạo tài khoản"; validate email hợp lệ, mật khẩu ≥ 6
- [ ] **ProjectsScreen**: AppBar "Dự án của tôi" + dòng nhỏ full_name, nút logout; empty state icon folder + "Chưa có dự án nào" + "Nhấn nút "+" bên dưới để tạo dự án đầu tiên của bạn!"; card dự án (icon tròn xanh nhạt, title đậm, description, nút xoá đỏ có dialog xác nhận); FAB "+ Dự án mới" → dialog nhập tên/mô tả
- [ ] **BoardScreen**: AppBar tên project + chấm xanh "Realtime Active" (đỏ "Mất kết nối" khi stream lỗi); 3 cột cuộn ngang, mỗi cột ~85% bề rộng màn hình: header nền nhạt + chấm màu (To Do xanh dương, In Progress cam, Done xanh lá) + badge đếm số task
- [ ] **TaskCard**: title đậm, description xám, ảnh (bo góc, `Image.network` có loading/error builder, tap mở full-screen), nút "x" xoá (dialog xác nhận); hàng action: TODO → "→ Bắt đầu"; IN_PROGRESS → "←" và "✓ Hoàn thành"; DONE → "←"
- [ ] Cuối mỗi cột "+ Thêm công việc" (mở form với status = cột đó); FAB "Thêm Task"
- [ ] **AddTaskDialog**: "Thêm công việc mới" + nút X; Tiêu đề công việc * / Mô tả chi tiết (multiline) / Trạng thái (dropdown 3 giá trị); nút outline "📎 Đính kèm ảnh" + tên file; preview ảnh; nút "Tạo công việc" (loading, disable khi đang gửi). Ảnh: `image_picker` `imageQuality: 80, maxWidth: 1600` → `PickedImage`
- [ ] Mọi `AppException` → SnackBar; mọi nút gửi có trạng thái loading
- [ ] (Bonus) kéo thả card giữa cột bằng `LongPressDraggable` + `DragTarget` → `updateStatus`
- [ ] Widget test cho Login validate + Board render 3 cột với fake repo

### Phase 2 — Claude Code (tích hợp)
- [ ] Merge `feat/backend` → `main`, rồi `feat/ui` → `main`; `flutter analyze` + `flutter test` sạch
- [ ] Chạy thật với `env.json`, đi hết checklist mục 4
- [ ] Viết `README.md`: cách setup Supabase + chạy app + ảnh chụp màn hình

**Luật chung cho cả 2 agent**: không sửa file ngoài vùng mình sở hữu. Cần đổi contract → Codex ghi yêu cầu vào `CONTRACT_REQUESTS.md`, Claude Code quyết rồi bump tag `contract-v2`. Commit nhỏ, message dạng `feat(board): ...`.

---

## 4. Kiểm thử nghiệm thu

**RLS bằng SQL Editor** (thay UUID thật của 2 user A, B):
```sql
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"<UUID_B>","role":"authenticated"}';
select count(*) from public.projects;   -- B KHÔNG được thấy project của A
select count(*) from public.tasks;      -- tương tự
insert into public.tasks (project_id, title) values ('<PROJECT_ID_CUA_A>', 'hack'); -- phải lỗi RLS
rollback;
```

**Checklist trên app**
- [ ] Đăng ký → có row trong `auth.users` VÀ `profiles` (full_name đúng)
- [ ] Đăng nhập sai mật khẩu → báo lỗi tiếng Việt, không crash
- [ ] Tắt app mở lại vẫn còn đăng nhập; logout → về màn login
- [ ] Tạo / xoá project; user B không thấy project của A
- [ ] Tạo task có ảnh → file nằm ở `task-attachments/{project_id}/...`, ảnh hiện trên card
- [ ] Chạy 2 máy (hoặc máy + emulator) cùng account: máy A bấm "Bắt đầu" → máy B nhảy cột ngay
- [ ] Xoá task → file ảnh trong Storage cũng mất; xoá project → cả folder mất
- [ ] Dashboard → Advisors → Security: không còn cảnh báo (đặc biệt không có cảnh báo "Clients can list all files")

---

## 5. Khác biệt so với bản demo của thầy (để mày giải thích khi vấn đáp)
- Bucket public nhưng **không** có policy SELECT rộng → hết cái cảnh báo màu cam "Clients can list all files in this bucket" trong ảnh demo.
- `status` có `CHECK` chỉ nhận `TODO / IN_PROGRESS / DONE`, title có check độ dài.
- Index cho mọi cột khoá ngoại; policy bọc `(select auth.uid())` để không bị gọi lại từng dòng.
- GRANT tường minh: từ 30/10/2026 Supabase không tự expose bảng mới trong `public` ra Data API nữa, thiếu GRANT là app trả lỗi permission denied.
- Profile tạo bằng trigger phía DB, client không tự insert → không ai giả mạo profile người khác được.
