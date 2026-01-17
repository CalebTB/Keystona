/// Result types for property operations
///
/// Uses sealed classes for exhaustive pattern matching and type-safe error handling.
/// Follows auth MVP pattern for consistency.
///
/// Base sealed class for property operation results
sealed class PropertyResult<T> {
  const PropertyResult();
}

/// Successful property operation result
class PropertySuccess<T> extends PropertyResult<T> {
  final T data;
  const PropertySuccess(this.data);
}

/// Failed property operation result
class PropertyFailure<T> extends PropertyResult<T> {
  final PropertyError error;
  const PropertyFailure(this.error);
}

/// Base sealed class for property errors
///
/// All property errors extend this class to enable exhaustive pattern matching
sealed class PropertyError {
  final String message;
  const PropertyError(this.message);
}

/// Network connectivity error
class NetworkError extends PropertyError {
  const NetworkError()
      : super('No internet connection. Please check your network and try again.');
}

/// Photo upload failed
class PhotoUploadError extends PropertyError {
  const PhotoUploadError() : super('Failed to upload photo. Please try again.');
}

/// Invalid property data submitted
class InvalidPropertyDataError extends PropertyError {
  const InvalidPropertyDataError()
      : super('Invalid property information. Please check your inputs.');
}

/// Property not found in database
class PropertyNotFoundError extends PropertyError {
  const PropertyNotFoundError() : super('Property not found.');
}

/// User session expired or not authenticated
class UnauthorizedError extends PropertyError {
  const UnauthorizedError() : super('Session expired. Please sign in again.');
}

/// Unknown/unexpected error
class UnknownError extends PropertyError {
  const UnknownError(String message) : super(message);
}
