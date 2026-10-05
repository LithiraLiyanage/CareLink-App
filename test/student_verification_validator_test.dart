import 'package:carelink_app/features/auth/services/student_verification_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudentVerificationValidator', () {
    test('accepts the supported document extensions case-insensitively', () {
      expect(
        StudentVerificationValidator.isAllowedDocument('student-id.JPG'),
        isTrue,
      );
      expect(
        StudentVerificationValidator.isAllowedDocument('student-id.jpeg'),
        isTrue,
      );
      expect(
        StudentVerificationValidator.isAllowedDocument('student-id.png'),
        isTrue,
      );
      expect(
        StudentVerificationValidator.isAllowedDocument('student-id.pdf'),
        isTrue,
      );
    });

    test('rejects unsupported or missing document extensions', () {
      expect(
        StudentVerificationValidator.isAllowedDocument('student-id.docx'),
        isFalse,
      );
      expect(
        StudentVerificationValidator.isAllowedDocument('student-id'),
        isFalse,
      );
    });

    test('enforces a non-empty 10 MB maximum document size', () {
      expect(StudentVerificationValidator.isWithinSizeLimit(0), isFalse);
      expect(StudentVerificationValidator.isWithinSizeLimit(1), isTrue);
      expect(
        StudentVerificationValidator.isWithinSizeLimit(
          StudentVerificationValidator.maximumDocumentBytes,
        ),
        isTrue,
      );
      expect(
        StudentVerificationValidator.isWithinSizeLimit(
          StudentVerificationValidator.maximumDocumentBytes + 1,
        ),
        isFalse,
      );
    });

    test('maps supported files to Firebase Storage content types', () {
      expect(
        StudentVerificationValidator.contentTypeFor('photo.jpeg'),
        'image/jpeg',
      );
      expect(
        StudentVerificationValidator.contentTypeFor('photo.png'),
        'image/png',
      );
      expect(
        StudentVerificationValidator.contentTypeFor('proof.pdf'),
        'application/pdf',
      );
    });

    test('validates university email shape', () {
      expect(
        StudentVerificationValidator.isValidEmail('student@campus.edu'),
        isTrue,
      );
      expect(StudentVerificationValidator.isValidEmail('student'), isFalse);
      expect(
        StudentVerificationValidator.isValidEmail('student@campus'),
        isFalse,
      );
    });
  });
}
