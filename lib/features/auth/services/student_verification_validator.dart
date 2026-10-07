class StudentVerificationValidator {
  static bool isValidStudentId(String value) => value.trim().isNotEmpty;

  static bool isValidEmail(String value) {
    final email = value.trim();
    return RegExp(
      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
      r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
      r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
    ).hasMatch(email);
  }
}
