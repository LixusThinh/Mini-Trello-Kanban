import 'dart:convert';
import 'dart:typed_data';

/// Ảnh người dùng chọn (image_picker) trước khi upload lên Storage.
class PickedImage {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  const PickedImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  /// `bytes` được mã hoá base64 trong JSON.
  factory PickedImage.fromJson(Map<String, dynamic> json) => PickedImage(
    bytes: base64Decode(json['bytes'] as String),
    fileName: json['file_name'] as String,
    mimeType: json['mime_type'] as String,
  );

  Map<String, dynamic> toJson() => {
    'bytes': base64Encode(bytes),
    'file_name': fileName,
    'mime_type': mimeType,
  };

  PickedImage copyWith({
    Uint8List? bytes,
    String? fileName,
    String? mimeType,
  }) => PickedImage(
    bytes: bytes ?? this.bytes,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
  );
}
