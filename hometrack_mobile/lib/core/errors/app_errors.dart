// Shared error classes used across features
sealed class AppError {
  final String message;
  const AppError(this.message);
}

class NetworkError extends AppError {
  const NetworkError()
      : super(
            'No internet connection. Please check your network and try again.');
}

class UnauthorizedError extends AppError {
  const UnauthorizedError() : super('Session expired. Please sign in again.');
}

class PhotoUploadError extends AppError {
  const PhotoUploadError() : super('Failed to upload photo. Please try again.');
}

class NotFoundError extends AppError {
  const NotFoundError()
      : super('System not found. It may have been deleted.');
}

class InvalidDataError extends AppError {
  const InvalidDataError(super.message);
}

class UnknownError extends AppError {
  const UnknownError(super.message);
}
