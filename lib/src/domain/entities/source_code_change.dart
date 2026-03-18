sealed class SourceCodeChange {
  const SourceCodeChange({required this.method});

  final String method;
}

class SourceCodeChangeOk extends SourceCodeChange {
  const SourceCodeChangeOk({
    required this.startOffset,
    required this.endOffset,
    required this.newContent,
    required super.method,
  });

  final int startOffset;
  final int endOffset;
  final String newContent;

  @override
  String toString() {
    return 'SourceCodeChangeOk('
        ' startOffset: $startOffset,'
        ' endOffset: $endOffset,'
        ' newContent: $newContent)';
  }
}

class SourceCodeChangeFailure extends SourceCodeChange {
  const SourceCodeChangeFailure({
    required this.message,
    required super.method,
  });
  final String message;
}

class NoDefaultConstructorFailure extends SourceCodeChange {
  const NoDefaultConstructorFailure({required super.method});

  @override
  String toString() => 'NoDefaultConstructorFailure(method: $method)';
}

class ZeroClassOffsetFailure extends SourceCodeChange {
  const ZeroClassOffsetFailure({required super.method});

  @override
  String toString() => 'ZeroClassOffsetFailure(method: $method)';
}

class NoFieldsFailure extends SourceCodeChange {
  const NoFieldsFailure({required super.method});

  @override
  String toString() => 'ZeroClassOffsetFailure(method: $method)';
}
