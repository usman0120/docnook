/// Every way a DocNook operation can fail. Each kind maps to exactly one
/// friendly message and one next-step action in the UI (BLUEPRINT 5.2).
enum FailureKind {
  unsupported,
  corrupt,
  passwordRequired,
  wrongPassword,
  tooLarge,
  permissionDenied,
  outOfSpace,
  cancelled,
  unknown,
}

/// A failure carried through [Result]. Pure data: safe to send across isolates.
///
/// [debugDetail] is for debug builds only. It must never hold file paths,
/// document content or passwords, because release logs record only [kind].
final class DocNookFailure implements Exception {
  const DocNookFailure(this.kind, {this.debugDetail});

  const DocNookFailure.unsupported({String? detail})
    : this(FailureKind.unsupported, debugDetail: detail);
  const DocNookFailure.corrupt({String? detail})
    : this(FailureKind.corrupt, debugDetail: detail);
  const DocNookFailure.passwordRequired()
    : this(FailureKind.passwordRequired);
  const DocNookFailure.wrongPassword() : this(FailureKind.wrongPassword);
  const DocNookFailure.tooLarge({String? detail})
    : this(FailureKind.tooLarge, debugDetail: detail);
  const DocNookFailure.permissionDenied({String? detail})
    : this(FailureKind.permissionDenied, debugDetail: detail);
  const DocNookFailure.outOfSpace() : this(FailureKind.outOfSpace);
  const DocNookFailure.cancelled() : this(FailureKind.cancelled);
  const DocNookFailure.unknown({String? detail})
    : this(FailureKind.unknown, debugDetail: detail);

  final FailureKind kind;
  final String? debugDetail;

  /// Stable code stored in `jobs.error_code` and written to release logs.
  String get code => kind.name;

  /// Converts anything thrown into a failure, recognising out-of-space and
  /// permission errors from the file system.
  static DocNookFailure from(Object error) {
    if (error is DocNookFailure) return error;
    final text = error.toString();
    if (text.contains('ENOSPC') || text.contains('No space left')) {
      return const DocNookFailure.outOfSpace();
    }
    if (text.contains('EACCES') ||
        text.contains('EPERM') ||
        text.contains('Permission denied')) {
      return const DocNookFailure.permissionDenied();
    }
    if (error is FormatException) {
      return DocNookFailure.corrupt(detail: error.message);
    }
    return DocNookFailure.unknown(detail: error.runtimeType.toString());
  }

  @override
  bool operator ==(Object other) =>
      other is DocNookFailure && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;

  @override
  String toString() => 'DocNookFailure($code)';
}
