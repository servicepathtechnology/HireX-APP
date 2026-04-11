/// Base exception for all HireX app errors.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class ServerException extends AppException {
  const ServerException(super.message);
}

/// Maps Firebase Auth error codes to user-friendly messages.
String mapFirebaseError(String code) {
  return switch (code) {
    'user-not-found' => 'No account found with this email.',
    'wrong-password' => 'Incorrect password. Please try again.',
    'too-many-requests' => 'Too many attempts. Please try again in a few minutes.',
    'user-disabled' => 'This account has been disabled. Contact support.',
    'email-already-in-use' => 'An account with this email already exists.',
    'weak-password' => 'Password is too weak. Use at least 8 characters.',
    'invalid-email' => 'Please enter a valid email address.',
    'network-request-failed' => 'Network error. Check your connection.',
    'email-not-verified' => 'Please verify your email before signing in.',
    _ => 'Something went wrong. Please try again.',
  };
}
