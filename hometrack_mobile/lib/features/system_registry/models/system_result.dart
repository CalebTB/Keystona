import 'package:hometrack_mobile/core/errors/app_errors.dart';

// Feature-specific result type
sealed class SystemResult<T> {
  const SystemResult();
}

class SystemSuccess<T> extends SystemResult<T> {
  final T data;
  const SystemSuccess(this.data);
}

class SystemFailure<T> extends SystemResult<T> {
  final AppError error;
  const SystemFailure(this.error);
}
