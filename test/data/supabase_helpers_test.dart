import 'package:flutter_test/flutter_test.dart';
import 'package:mini_trello/core/app_exception.dart';
import 'package:mini_trello/data/supabase/storage_paths.dart';
import 'package:mini_trello/data/supabase/supabase_errors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('storage paths', () {
    test('objectPathFromPublicUrl lấy đúng {project_id}/{file}', () {
      expect(
        objectPathFromPublicUrl(
          'https://abc.supabase.co/storage/v1/object/public/task-attachments/p1/f1.jpg',
        ),
        'p1/f1.jpg',
      );
    });

    test('objectPathFromPublicUrl bỏ query string', () {
      expect(
        objectPathFromPublicUrl(
          'https://abc.supabase.co/storage/v1/object/public/task-attachments/p1/f1.png?t=1',
        ),
        'p1/f1.png',
      );
    });

    test('objectPathFromPublicUrl trả null với URL ngoài bucket', () {
      expect(objectPathFromPublicUrl('https://picsum.photos/200'), isNull);
      expect(
        objectPathFromPublicUrl(
          'https://abc.supabase.co/storage/v1/object/public/other/p1/f1.jpg',
        ),
        isNull,
      );
    });

    test('extensionForMime khớp allowed_mime_types của bucket', () {
      expect(extensionForMime('image/jpeg'), 'jpg');
      expect(extensionForMime('image/PNG'), 'png');
      expect(extensionForMime('image/webp'), 'webp');
      expect(extensionForMime('image/heic'), 'heic');
      expect(() => extensionForMime('image/gif'), throwsA(isA<AppException>()));
    });

    test('attachmentPath theo quy ước {project_id}/{uuid}.{ext}', () {
      expect(attachmentPath('p1', 'u1', 'jpg'), 'p1/u1.jpg');
    });
  });

  group('toAppException', () {
    String msg(Object e) => toAppException(e).message;

    test('sai mật khẩu', () {
      expect(
        msg(const AuthApiException('x', code: 'invalid_credentials')),
        'Email hoặc mật khẩu không đúng.',
      );
      expect(
        msg(const AuthException('Invalid login credentials')),
        'Email hoặc mật khẩu không đúng.',
      );
    });

    test('email đã tồn tại', () {
      expect(
        msg(const AuthApiException('x', code: 'user_already_exists')),
        'Email này đã được đăng ký.',
      );
    });

    test('mật khẩu yếu', () {
      expect(
        msg(
          AuthWeakPasswordException(
            message: 'weak',
            statusCode: '422',
            reasons: const ['length'],
          ),
        ),
        'Mật khẩu phải có ít nhất 6 ký tự.',
      );
    });

    test('chưa xác nhận email', () {
      expect(
        msg(const AuthApiException('x', code: 'email_not_confirmed')),
        'Email chưa được xác nhận. Vui lòng kiểm tra hộp thư.',
      );
    });

    test('RLS từ chối', () {
      expect(
        msg(const PostgrestException(message: 'x', code: '42501')),
        'Bạn không có quyền thực hiện thao tác này.',
      );
    });

    test('AppException đi thẳng qua', () {
      const e = AppException('giữ nguyên');
      expect(toAppException(e), same(e));
    });
  });
}
