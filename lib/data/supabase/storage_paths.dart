import '../../core/app_exception.dart';

const attachmentsBucket = 'task-attachments';

/// Khớp `file_size_limit` của bucket trong 0001_init.sql.
const maxAttachmentBytes = 5 * 1024 * 1024;

/// Khớp `allowed_mime_types` của bucket trong 0001_init.sql.
const _extByMime = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/heic': 'heic',
};

/// Đuôi file cho ảnh; ném [AppException] nếu bucket không nhận loại ảnh này.
String extensionForMime(String mimeType) {
  final ext = _extByMime[mimeType.toLowerCase()];
  if (ext == null) {
    throw const AppException('Chỉ hỗ trợ ảnh JPG, PNG, WEBP, HEIC.');
  }
  return ext;
}

/// `{project_id}/{uuid}.{ext}`
String attachmentPath(String projectId, String id, String ext) =>
    '$projectId/$id.$ext';

/// Lấy object path từ public URL:
/// `https://x.supabase.co/storage/v1/object/public/task-attachments/<path>`.
/// Trả null nếu URL không thuộc bucket này.
String? objectPathFromPublicUrl(String url) {
  final segments = Uri.tryParse(url)?.pathSegments;
  if (segments == null) return null;
  final i = segments.indexOf(attachmentsBucket);
  if (i < 1 || segments[i - 1] != 'public' || i == segments.length - 1) {
    return null;
  }
  return segments.sublist(i + 1).join('/');
}
