class StudentVerificationValidator {
  static const int maximumDocumentBytes = 10 * 1024 * 1024;
  static const Set<String> allowedExtensions = {'jpg', 'jpeg', 'png', 'pdf'};

  static bool isValidEmail(String value) {
    final email = value.trim();
    final atIndex = email.indexOf('@');
    return atIndex > 0 &&
        atIndex == email.lastIndexOf('@') &&
        atIndex < email.length - 3 &&
        email.substring(atIndex + 1).contains('.');
  }

  static String extensionFor(String fileName) {
    final separatorIndex = fileName.lastIndexOf('.');
    if (separatorIndex < 0 || separatorIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(separatorIndex + 1).toLowerCase();
  }

  static bool isAllowedDocument(String fileName) {
    return allowedExtensions.contains(extensionFor(fileName));
  }

  static bool isWithinSizeLimit(int byteLength) {
    return byteLength > 0 && byteLength <= maximumDocumentBytes;
  }

  static String contentTypeFor(String fileName) {
    switch (extensionFor(fileName)) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        throw ArgumentError.value(
          fileName,
          'fileName',
          'Only JPG, JPEG, PNG, and PDF documents are supported.',
        );
    }
  }
}
