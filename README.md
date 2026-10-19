# Mini Trello

Ứng dụng Kanban viết bằng Flutter, dùng đủ 3 mảng của Supabase:

- **Database**: bảng `profiles`, `projects`, `tasks`, có Row Level Security (RLS) và Realtime.
- **Authentication**: đăng nhập bằng email/mật khẩu.
- **Storage**: ảnh đính kèm task.

Giao diện tự thiết kế, gọi là "Indigo Focus": tông indigo/violet, có dark mode, board chia tab, vuốt thẻ để đổi trạng thái.

- Chạy được trên Android và iOS.
- Flutter 3.47, `supabase_flutter` 2.18.3, `go_router` 18.1.0, `image_picker` 1.2.4.

## 1. Cài đặt Supabase

1. **Tạo project** trên [supabase.com](https://supabase.com): chọn New project, region **Southeast Asia (Singapore)**.
2. **Chạy schema**: vào Dashboard → **SQL Editor** → New query, dán toàn bộ [`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql) rồi bấm **Run**. Kết quả đúng là `Success. No rows returned`.
   Script này tạo:
   - 3 bảng, index cho các khoá ngoại;
   - trigger tự tạo profile khi đăng ký;
   - quyền truy cập (GRANT) và RLS;
   - Realtime cho `tasks`/`projects`;
   - bucket `task-attachments` kèm 4 policy storage.
3. **Auth**: vào Authentication → Sign In / Providers và bật **Email**. Lúc dev nên tắt **Confirm email**, vì SMTP mặc định của gói Free giới hạn số mail mỗi giờ.
4. **Lấy key**: bấm nút **Connect** ở thanh trên cùng, copy **Project URL** và **Publishable key** (`sb_publishable_...`).
   Không bao giờ dùng `secret` hay `service_role` key trong app.
5. **Tạo `env.json`** ở thư mục gốc, chép từ [`env.example.json`](env.example.json). File này đã có trong `.gitignore`, không commit lên git.
   ```json
   {
     "SUPABASE_URL": "https://<project-ref>.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_xxx"
   }
   ```

## 2. Chạy app

```bash
flutter pub get

# Chạy với Supabase thật
flutter run --dart-define-from-file=env.json

# Chạy không cần mạng: repo giả trong bộ nhớ, có sẵn dữ liệu mẫu
flutter run --dart-define=USE_FAKE=true
#   tài khoản mẫu: demo@hutech.edu.vn / 123456

# Build APK debug
flutter build apk --debug --dart-define-from-file=env.json
```

VS Code: thêm `"args": ["--dart-define-from-file=env.json"]` vào `.vscode/launch.json`.

## 3. Kiểm tra

```bash
dart format .
flutter analyze   # phải ra 0 issue
flutter test      # gồm unit test map JSON/lỗi và widget test Login + Board
```

**Test RLS bằng SQL Editor.** Cần 2 user thật A và B (đăng ký qua app), thay UUID thật vào chỗ trong ngoặc nhọn:

```sql
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"<UUID_B>","role":"authenticated"}';
select count(*) from public.projects;   -- B KHÔNG được thấy project của A
select count(*) from public.tasks;      -- tương tự
insert into public.tasks (project_id, title) values ('<PROJECT_ID_CUA_A>', 'hack'); -- phải lỗi RLS
rollback;
```

Checklist nghiệm thu đầy đủ nằm ở [`PLAN.md`](PLAN.md) mục 4.

## 4. Kiến trúc

```
lib/
├─ main.dart        khởi tạo Supabase (bỏ qua khi USE_FAKE), gọi setupDependencies(), runApp
├─ app/             di.dart (chọn repo thật hoặc giả), router.dart (go_router + chuyển hướng theo trạng thái đăng nhập), theme.dart
├─ core/            env.dart (đọc --dart-define), app_exception.dart
├─ models/          AppUser, Profile, Project, Task (+ TaskStatus), PickedImage
├─ data/
│  ├─ contracts/    interface AuthRepository / ProjectRepository / TaskRepository
│  ├─ supabase/     bản thật: realtime .stream(), upload Storage, map lỗi sang tiếng Việt
│  └─ fake/         bản giả trong bộ nhớ để dựng UI không cần mạng
├─ features/        auth/, projects/, board/: màn hình (không import supabase_flutter)
└─ widgets/         widget dùng chung
supabase/migrations/0001_init.sql
```

- UI chỉ gọi repository qua `lib/app/di.dart`. Repository luôn ném `AppException` có message tiếng Việt, UI chỉ việc hiện SnackBar.
- **Realtime**: `from('tasks').stream(primaryKey: ['id']).eq('project_id', id)`. Máy A đổi trạng thái task thì máy B tự cập nhật theo.
- **Storage**:
  - Ảnh nằm ở `task-attachments/{project_id}/{uuid}.{ext}`.
  - Nếu ghi task vào DB lỗi thì xoá luôn ảnh vừa upload.
  - Xoá task thì xoá ảnh của task đó; xoá project thì xoá cả folder ảnh của project.

## 5. Khác biệt so với bản demo

- Giao diện tự thiết kế ("Indigo Focus"):
  - có dark mode;
  - màn đăng nhập có dải gradient phía trên;
  - dự án hiện dạng lưới gradient;
  - board chia tab, có thanh tiến độ;
  - vuốt hoặc kéo thả thẻ để đổi trạng thái;
  - thêm và xem task bằng bottom sheet.
- Bucket public nhưng **không có** policy SELECT mở cho mọi người, nên không còn cảnh báo "Clients can list all files in this bucket".
- `status` có `CHECK` chỉ nhận `TODO / IN_PROGRESS / DONE`, `title` có giới hạn độ dài.
- Mọi khoá ngoại đều có index. Policy viết `(select auth.uid())` để Postgres không gọi lại hàm cho từng dòng.
- GRANT ghi rõ ràng: từ 30/10/2026 Supabase không tự mở bảng mới trong schema `public` ra Data API nữa.
- Profile do trigger phía DB tạo, client không tự insert được nên không ai giả mạo profile người khác.

## Ghi chú build trên Windows

Project nằm ở ổ D: còn pub cache nằm ở ổ C:, nên `android/gradle.properties` phải đặt `kotlin.incremental=false`. Bỏ dòng này đi thì Gradle báo lỗi "Could not close incremental caches".
