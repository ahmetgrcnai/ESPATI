/// A generic Result type for handling success and failure states.
///
/// Used throughout the app to wrap repository responses, ensuring
/// the UI always handles both success and error cases explicitly.
///
/// Usage:
/// ```dart
/// final result = await repository.getPosts();
/// switch (result) {
///   case Success(:final data):
///     // use data
///   case Failure(:final message):
///     // show error
/// }
/// ```
sealed class Result<T> {
  const Result();
}

/// Holds the successful result data of type [T].
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Holds an error [message] and an optional [exception].
class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;
  const Failure(this.message, {this.exception});
}
