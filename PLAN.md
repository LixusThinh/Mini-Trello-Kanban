# Mini Trello / Kanban — Flutter + Supabase

Bài tập: dùng đủ 3 mảng của Supabase — **Database** (profiles/projects/tasks + RLS + Realtime), **Authentication** (email/password), **Storage** (ảnh đính kèm task). Giữ đủ **chức năng/flow** của bản demo của thầy nhưng **giao diện tự thiết kế, khác hoàn toàn** (bộ nhận diện "Indigo Focus", contract-v2), và làm chắc phần bảo mật hơn bản demo.

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

`lib/app/theme.dart` (**contract-v2, "Indigo Focus"**): Material 3, seed indigo `0xFF4F46E5` + accent violet `0xFF7C3AED` (`AppColors.heroGradient`), nền sáng `0xFFF6F5FB` / tối `0xFF0F0E17`, có **dark mode** (`themeMode: system`). Nút bo góc 14 cao 52 (không stadium), input **filled không viền** bo 14, card bo 20 viền mảnh không đổ bóng, bottom sheet bo 28 có drag handle, SnackBar floating. Màu trạng thái `statusColor()`: Cần làm slate `0xFF64748B`, Đang làm pink `0xFFEC4899`, Hoàn thành teal `0xFF14B8A6`; icon `statusIcon()`. Bảng gradient thẻ dự án `AppColors.projectPalette`.

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
> **Giao diện tự thiết kế ("Indigo Focus") — KHÔNG được giống bản demo của thầy.** Cấm: icon lưới 2x2, màu xanh lá/mint, nút stadium, AppBar "Dự án của tôi", danh sách dự án dạng list có nút xoá đỏ, 3 cột cuộn ngang 85% màn hình, nút "→ Bắt đầu"/"✓ Hoàn thành", chữ "Realtime Active", AddTaskDialog dạng dialog. Chỉ dùng màu/kiểu từ `lib/app/theme.dart` (đẹp ở cả light lẫn dark mode).

- [ ] **Auth (Login + Register dùng chung 1 widget khung)**: nửa trên là hero gradient `AppColors.heroGradient` cao ~38% màn hình, chứa logo tự vẽ (3 thanh dọc cao thấp khác nhau như 3 cột kanban, màu trắng, bo góc) + chữ "Mini Trello" + slogan "Sắp xếp công việc, gọn như kéo thẻ."; nửa dưới là sheet bo góc trên 28 đè lên hero, chứa form.
  - **LoginScreen**: tiêu đề "Chào mừng trở lại", Email (prefix `alternate_email`), Mật khẩu (prefix `key_rounded`, suffix ẩn/hiện), nút "Đăng nhập", dòng dưới "Lần đầu dùng Mini Trello?" + TextButton "Tạo tài khoản".
  - **RegisterScreen**: tiêu đề "Bắt đầu miễn phí", Họ và tên, Email, Mật khẩu (có thanh độ mạnh mật khẩu 3 nấc dưới field), nút "Tạo tài khoản", dòng dưới "Đã có tài khoản?" + "Đăng nhập". Validate email hợp lệ, mật khẩu ≥ 6, họ tên không trống.
- [ ] **ProjectsScreen** (không AppBar truyền thống):
  - Header trong `SafeArea`: dòng nhỏ ngày hôm nay ("Thứ Hai, 19/10"), dòng lớn "Xin chào, {tên} 👋" (tên = `full_name`, rỗng thì lấy phần trước @ của email); bên phải avatar tròn chữ cái đầu → bấm mở bottom sheet tài khoản (họ tên, email, nút "Đăng xuất").
  - Dòng thống kê: "{n} dự án".
  - **Lưới 2 cột**: ô đầu tiên là thẻ "Dự án mới" viền đứt (dashed, tự vẽ bằng CustomPainter) có icon `add_rounded` → mở bottom sheet tạo dự án (Tên dự án *, Mô tả, nút "Tạo dự án"). Các ô sau là thẻ dự án nền gradient từ `AppColors.projectPalette[project.id.hashCode.abs() % length]`, chữ trắng: tiêu đề đậm (2 dòng), mô tả (2 dòng, mờ), góc dưới "Tạo {dd/MM}". Bấm → board. **Nhấn giữ** → bottom sheet hành động có "Xoá dự án" (màu error) → xác nhận bằng bottom sheet thứ 2 ("Xoá "{tên}"? Mọi công việc và ảnh đính kèm sẽ bị xoá vĩnh viễn.").
  - Empty state (chỉ có ô "Dự án mới"): minh hoạ bằng icon `dashboard_customize_rounded` lớn + "Bắt đầu với dự án đầu tiên" + "Mỗi dự án là một bảng công việc riêng.".
- [ ] **BoardScreen**:
  - AppBar: nút back, tiêu đề tên dự án, phụ đề mô tả (1 dòng); bên phải **pill trạng thái kết nối**: "● Trực tiếp" (teal, chấm nhấp nháy nhẹ) khi stream ổn, "● Mất kết nối" (error) khi stream lỗi.
  - Dưới AppBar: thẻ tiến độ "{done}/{total} việc đã xong" + `LinearProgressIndicator` bo tròn màu teal.
  - **3 tab** (`TabBar` dạng pill/segmented, mỗi tab: icon `statusIcon` + tên ngắn "Cần làm" / "Đang làm" / "Xong" + badge đếm màu `statusColor`), `TabBarView` vuốt ngang được; mỗi tab là danh sách dọc.
  - Empty state mỗi tab: "Chưa có việc nào ở đây".
  - FAB vuông bo 14 icon `add_task_rounded` → mở AddTaskSheet với status = tab đang chọn.
- [ ] **TaskCard**: Card có **sọc màu trạng thái bên trái** (4px), tiêu đề đậm, mô tả 2 dòng; nếu có ảnh: thumbnail vuông 64 bo 12 bên phải (`Image.network` có loading/error builder). **Vuốt sang phải** → chuyển sang trạng thái kế tiếp, **vuốt sang trái** → trạng thái trước (Dismissible `confirmDismiss` gọi `updateStatus` rồi trả `false`; nền vuốt hiện màu + tên trạng thái đích; không vuốt được nếu không có trạng thái đó). **Bấm thẻ** → TaskDetailSheet.
- [ ] **TaskDetailSheet** (bottom sheet): ảnh lớn (bấm → xem full-screen có `InteractiveViewer` + `Hero`), tiêu đề, mô tả, ngày tạo; chọn trạng thái bằng `SegmentedButton` 3 giá trị (đổi là gọi `updateStatus`); nút text "Xoá công việc" màu error → xác nhận → `deleteTask`.
- [ ] **AddTaskSheet** (bottom sheet cao, `isScrollControlled`, đẩy lên theo bàn phím): tiêu đề "Công việc mới"; Tiêu đề * / Mô tả (multiline); trạng thái bằng `SegmentedButton` (không dropdown); ô chọn ảnh viền đứt "Chạm để thêm ảnh" (sau khi chọn: preview bo 16 + nút xoá ảnh nhỏ ở góc); nút "Lưu công việc" (loading, disable khi đang gửi). Ảnh: `image_picker` `imageQuality: 80, maxWidth: 1600` → `PickedImage` (mime suy từ đuôi file: jpg/jpeg→image/jpeg, png, webp, heic).
- [ ] Mọi `AppException` → SnackBar floating; mọi nút gửi có trạng thái loading
- [ ] (Bonus) kéo thả: `LongPressDraggable` thẻ thả lên **tab** khác (tab là `DragTarget`, sáng lên khi kéo qua) → `updateStatus`
- [ ] Widget test cho Login validate + Board render 3 tab với fake repo

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
- **Giao diện tự thiết kế** ("Indigo Focus"): có dark mode, hero gradient ở màn auth, lưới dự án gradient, board dạng tab có thanh tiến độ, vuốt thẻ để đổi trạng thái, thêm/xem task bằng bottom sheet thay vì dialog.
- Bucket public nhưng **không** có policy SELECT rộng → hết cái cảnh báo màu cam "Clients can list all files in this bucket" trong ảnh demo.
- `status` có `CHECK` chỉ nhận `TODO / IN_PROGRESS / DONE`, title có check độ dài.
- Index cho mọi cột khoá ngoại; policy bọc `(select auth.uid())` để không bị gọi lại từng dòng.
- GRANT tường minh: từ 30/10/2026 Supabase không tự expose bảng mới trong `public` ra Data API nữa, thiếu GRANT là app trả lỗi permission denied.
- Profile tạo bằng trigger phía DB, client không tự insert → không ai giả mạo profile người khác được.
