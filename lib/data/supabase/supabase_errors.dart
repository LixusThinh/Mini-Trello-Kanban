import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_exception.dart';

/// Đổi mọi lỗi từ Supabase/mạng thành [AppException] tiếng Việt.
AppException toAppException(Object error) {
  if (error is AppException) return error;
  if (_isNetworkError(error)) {
    return const AppException('Không có kết nối mạng. Vui lòng thử lại.');
  }
  if (error is AuthException) return _auth(error);
  if (error is PostgrestException) return _postgrest(error);
  if (error is StorageException) return _storage(error);
  if (error is RealtimeSubscribeException) {
    return const AppException('Mất kết nối realtime. Đang thử kết nối lại...');
  }
  return const AppException('Đã có lỗi xảy ra. Vui lòng thử lại.');
}

/// Chạy [action], lỗi nào cũng ném ra dưới dạng [AppException].
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e, st) {
    if (kDebugMode) debugPrint('[supabase] $e\n$st');
    throw toAppException(e);
  }
}

/// Lỗi trong stream realtime cũng thành [AppException] để UI hiện "Mất kết nối".
Stream<T> guardStream<T>(Stream<T> stream) =>
    stream.handleError((Object e, StackTrace st) {
      if (kDebugMode) debugPrint('[supabase stream] $e');
      throw toAppException(e);
    });

bool _isNetworkError(Object e) =>
    e is SocketException ||
    e is TimeoutException ||
    e is AuthRetryableFetchException ||
    // package:http ClientException (không phải dependency trực tiếp nên so theo tên).
    e.runtimeType.toString() == 'ClientException';

AppException _auth(AuthException e) {
  final msg = e.message.toLowerCase();
  switch (e.code) {
    case 'invalid_credentials':
      return const AppException('Email hoặc mật khẩu không đúng.');
    case 'email_not_confirmed':
      return const AppException(
        'Email chưa được xác nhận. Vui lòng kiểm tra hộp thư.',
      );
    case 'user_already_exists' || 'email_exists':
      return const AppException('Email này đã được đăng ký.');
    case 'weak_password':
      return const AppException('Mật khẩu phải có ít nhất 6 ký tự.');
    case 'email_address_invalid' || 'validation_failed':
      return const AppException('Email không hợp lệ.');
    case 'over_email_send_rate_limit' || 'over_request_rate_limit':
      return const AppException(
        'Bạn thao tác quá nhanh. Vui lòng đợi rồi thử lại.',
      );
    case 'signup_disabled':
      return const AppException('Hệ thống đang tạm khoá đăng ký.');
  }
  // Server cũ không trả code → so theo message.
  if (msg.contains('invalid login credentials')) {
    return const AppException('Email hoặc mật khẩu không đúng.');
  }
  if (msg.contains('email not confirmed')) {
    return const AppException(
      'Email chưa được xác nhận. Vui lòng kiểm tra hộp thư.',
    );
  }
  if (msg.contains('already registered')) {
    return const AppException('Email này đã được đăng ký.');
  }
  if (msg.contains('password should be at least')) {
    return const AppException('Mật khẩu phải có ít nhất 6 ký tự.');
  }
  return const AppException('Xác thực thất bại. Vui lòng thử lại.');
}

AppException _postgrest(PostgrestException e) => switch (e.code) {
  '42501' => const AppException('Bạn không có quyền thực hiện thao tác này.'),
  '23514' => const AppException(
    'Dữ liệu không hợp lệ (tiêu đề trống hoặc quá dài).',
  ),
  '23503' => const AppException('Dự án không còn tồn tại.'),
  'PGRST116' => const AppException('Không tìm thấy dữ liệu.'),
  'PGRST301' || 'PGRST303' => const AppException(
    'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
  ),
  _ => const AppException('Lỗi cơ sở dữ liệu. Vui lòng thử lại.'),
};

AppException _storage(StorageException e) => switch (e.statusCode) {
  '413' => const AppException('Ảnh vượt quá 5MB.'),
  '415' => const AppException('Chỉ hỗ trợ ảnh JPG, PNG, WEBP, HEIC.'),
  '401' || '403' => const AppException('Bạn không có quyền với ảnh này.'),
  _ => const AppException('Lỗi tải ảnh. Vui lòng thử lại.'),
};
