class PasswordValidator {
  static String? validateNewPassword(String? value, {String? currentPassword}) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    if (value.length < 8 || value.length > 72) {
      return 'Mật khẩu phải có từ 8 đến 72 ký tự';
    }
    if (!RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Mật khẩu phải có ít nhất một chữ cái và một chữ số';
    }
    if (currentPassword != null && value == currentPassword) {
      return 'Mật khẩu mới phải khác mật khẩu hiện tại';
    }
    return null;
  }

  static String? validateConfirmation(String? value, String newPassword) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới';
    }
    if (value != newPassword) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }
}
