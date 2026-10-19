import '../../core/app_exception.dart';
import '../../models/app_user.dart';
import '../../models/profile.dart';
import '../contracts/auth_repository.dart';
import 'fake_store.dart';

class FakeAuthRepository implements AuthRepository {
  final _store = FakeStore.instance;
  @override
  AppUser? get currentUser => _store.user;
  @override
  Stream<AppUser?> watchUser() => _store.watch(() => _store.user);
  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(FakeStore.delay);
    final account = _store.accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AppException('Email hoặc mật khẩu không đúng');
    }
    _store.user = account.user;
    _store.notify();
  }

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(FakeStore.delay);
    if (password.length < 6) {
      throw const AppException('Mật khẩu phải có ít nhất 6 ký tự');
    }
    final normalized = email.trim().toLowerCase();
    if (_store.accounts.containsKey(normalized)) {
      throw const AppException('Email này đã được đăng ký');
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      throw const AppException('Email không hợp lệ');
    }
    if (fullName.trim().isEmpty) {
      throw const AppException('Vui lòng nhập họ và tên');
    }
    final user = AppUser(id: _store.newId(), email: normalized);
    _store.accounts[normalized] = (
      user: user,
      password: password,
      profile: Profile(id: user.id, fullName: fullName.trim()),
    );
    _store.user = user;
    _store.notify();
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(FakeStore.delay);
    _store.user = null;
    _store.notify();
  }

  @override
  Future<Profile?> getMyProfile() async {
    await Future<void>.delayed(FakeStore.delay);
    return _store.accounts[_store.requireUser().email]?.profile;
  }
}
