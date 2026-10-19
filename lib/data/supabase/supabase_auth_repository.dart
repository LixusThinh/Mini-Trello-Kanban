import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_exception.dart';
import '../../models/app_user.dart';
import '../../models/profile.dart';
import '../contracts/auth_repository.dart';
import 'supabase_errors.dart';

class SupabaseAuthRepository implements AuthRepository {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  static AppUser? _toAppUser(User? u) =>
      u == null ? null : AppUser(id: u.id, email: u.email ?? '');

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Stream<AppUser?> watchUser() => guardStream(
    _auth.onAuthStateChange.map((s) => _toAppUser(s.session?.user)),
  );

  @override
  Future<void> signIn({required String email, required String password}) =>
      guard(
        () => _auth.signInWithPassword(email: email.trim(), password: password),
      );

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) => guard(() async {
    if (password.length < 6) {
      throw const AppException('Mật khẩu phải có ít nhất 6 ký tự.');
    }
    final res = await _auth.signUp(
      email: email.trim(),
      password: password,
      // Chỉ để hiển thị: trigger private.handle_new_user chép vào profiles.full_name.
      data: {'full_name': fullName.trim()},
    );
    // Khi bật "Confirm email", email đã tồn tại không báo lỗi mà trả user không có identity.
    if (res.user?.identities?.isEmpty ?? false) {
      throw const AppException('Email này đã được đăng ký.');
    }
    if (res.session == null) {
      throw const AppException(
        'Đăng ký thành công! Vui lòng xác nhận email rồi đăng nhập.',
      );
    }
  });

  @override
  Future<void> signOut() => guard(() => _auth.signOut());

  @override
  Future<Profile?> getMyProfile() => guard(() async {
    final uid = _auth.currentUser?.id;
    if (uid == null) return null;
    final row = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, avatar_url')
        .eq('id', uid)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  });
}
