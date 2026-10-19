# AGENTS.md — luật chung cho Claude Code và Codex

Đọc `PLAN.md` trước khi làm bất cứ thứ gì. Đó là nguồn sự thật duy nhất.

## Vai trò
- **Claude Code**: Phase 0 (contract), nhánh `feat/backend`, Phase 2 (merge + nghiệm thu). Sở hữu `supabase/**`, `lib/data/supabase/**`, `android/**`, `ios/**`, `test/data/**` và toàn bộ file contract (`pubspec.yaml`, `lib/main.dart`, `lib/app/**`, `lib/core/**`, `lib/models/**`, `lib/data/contracts/**`).
- **Codex**: nhánh `feat/ui`. Sở hữu `lib/features/**`, `lib/widgets/**`, `lib/data/fake/**`, `test/widget/**`.

## Luật
1. Không sửa file ngoài vùng sở hữu. Cần đổi contract → ghi vào `CONTRACT_REQUESTS.md`, dừng phần bị chặn, làm việc khác.
2. UI chỉ gọi repository qua `lib/app/di.dart`, không bao giờ import `supabase_flutter` trong `lib/features/**`.
3. Repository chỉ ném `AppException` (message tiếng Việt). UI hiện bằng SnackBar.
4. Không hardcode URL/key. Chỉ đọc qua `Env` (`--dart-define-from-file=env.json`). Không bao giờ dùng service_role/secret key.
5. Supabase thay đổi nhanh: trước khi dùng API nào của `supabase_flutter`, kiểm tra docs hiện tại (`https://supabase.com/docs/reference/dart/introduction`), không code theo trí nhớ.
6. Trước khi commit: `dart format .`, `flutter analyze` (0 issue), `flutter test`.
7. Commit nhỏ, conventional commits: `feat(board): ...`, `fix(auth): ...`.
8. UI text tiếng Việt có dấu, đúng như liệt kê trong `PLAN.md` mục 3.
