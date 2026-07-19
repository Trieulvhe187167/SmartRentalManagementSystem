// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

class AvatarPickerException implements Exception {
  final String message;
  const AvatarPickerException(this.message);

  @override
  String toString() => message;
}

Future<String?> pickAvatarData() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/webp';
  input.click();
  await input.onChange.first;
  final file = input.files?.firstOrNull;
  if (file == null) return null;
  if (file.size > 2 * 1024 * 1024) {
    throw const AvatarPickerException('Ảnh đại diện không được vượt quá 2 MB.');
  }
  if (!const {'image/png', 'image/jpeg', 'image/webp'}.contains(file.type)) {
    throw const AvatarPickerException('Chỉ hỗ trợ ảnh PNG, JPEG hoặc WebP.');
  }

  final reader = html.FileReader()..readAsDataUrl(file);
  await reader.onLoad.first;
  return reader.result as String?;
}
