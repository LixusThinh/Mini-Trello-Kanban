import '../../models/app_user.dart';
import '../../models/profile.dart';

/// Mọi lỗi ném ra là `AppException` (message tiếng Việt).
abstract class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> watchUser();
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<Profile?> getMyProfile();
}
