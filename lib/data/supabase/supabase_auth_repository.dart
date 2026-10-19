import '../../models/app_user.dart';
import '../../models/profile.dart';
import '../contracts/auth_repository.dart';

/// Stub Phase 0 — Claude Code implement trên nhánh feat/backend.
class SupabaseAuthRepository implements AuthRepository {
  @override
  AppUser? get currentUser => throw UnimplementedError();

  @override
  Stream<AppUser?> watchUser() => throw UnimplementedError();

  @override
  Future<void> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<Profile?> getMyProfile() => throw UnimplementedError();
}
