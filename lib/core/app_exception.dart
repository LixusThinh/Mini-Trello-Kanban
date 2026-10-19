/// Repository LUÔN ném lỗi kiểu này, message tiếng Việt. UI chỉ việc show SnackBar.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}
