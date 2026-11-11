import 'dart:async';

import 'package:docnook/core/failures.dart';

/// The outcome of an operation: a value or a [DocNookFailure]. Engines and
/// repositories return this instead of throwing, so every caller must decide
/// what the user sees when something goes wrong.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(DocNookFailure failure) = Err<T>;

  /// Runs [body], turning anything it throws into an [Err].
  static Future<Result<T>> guard<T>(FutureOr<T> Function() body) async {
    try {
      return Ok(await body());
    } on Object catch (error) {
      return Err(DocNookFailure.from(error));
    }
  }

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  DocNookFailure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  /// Returns the value or throws the failure. For use inside [guard] bodies
  /// and isolates, where a thrown failure is caught and re-wrapped.
  T get orThrow => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };

  R when<R>({
    required R Function(T value) ok,
    required R Function(DocNookFailure failure) err,
  }) => switch (this) {
    Ok(:final value) => ok(value),
    Err(:final failure) => err(failure),
  };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final DocNookFailure failure;
}
