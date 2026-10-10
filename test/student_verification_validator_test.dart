import 'package:carelink_app/features/auth/services/student_verification_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudentVerificationValidator', () {
    test('requires a non-empty student ID', () {
      expect(StudentVerificationValidator.isValidStudentId('  '), isFalse);
      expect(StudentVerificationValidator.isValidStudentId('S12345'), isTrue);
    });

    test('validates university email format', () {
      expect(
        StudentVerificationValidator.isValidEmail('student@campus.edu'),
        isTrue,
      );
      expect(
        StudentVerificationValidator.isValidEmail(
          'student.name+care@campus.edu',
        ),
        isTrue,
      );
      expect(StudentVerificationValidator.isValidEmail('student'), isFalse);
      expect(
        StudentVerificationValidator.isValidEmail('student@campus'),
        isFalse,
      );
      expect(
        StudentVerificationValidator.isValidEmail('student@@campus.edu'),
        isFalse,
      );
    });
  });
}
