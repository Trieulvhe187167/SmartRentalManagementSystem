class AvatarPickerException implements Exception {
  final String message;
  const AvatarPickerException(this.message);

  @override
  String toString() => message;
}

Future<String?> pickAvatarData() async {
  throw const AvatarPickerException(
    'Thiết bị này chưa hỗ trợ chọn ảnh đại diện.',
  );
}
