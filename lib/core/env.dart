/// Giá trị build-time, đọc từ `--dart-define-from-file=env.json`.
/// Không bao giờ hardcode URL/key, không bao giờ dùng service_role/secret key.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// `--dart-define=USE_FAKE=true` → dùng repo in-memory, không cần mạng.
  static const useFake = bool.fromEnvironment('USE_FAKE');
}
