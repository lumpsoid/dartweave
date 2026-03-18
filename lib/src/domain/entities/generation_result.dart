import 'package:dartweave/src/domain/entities/method_type.dart';

/// Result of method generation
class GenerationResult {
  const GenerationResult({
    required this.className,
    required this.updatedSourceCode,
    required this.generatedMethods,
    this.errors = const [],
  });

  final String className;
  final String updatedSourceCode;
  final List<String> generatedMethods;
  final List<GenerationError> errors;

  bool get wasUpdated => generatedMethods.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
  bool get isPartial => wasUpdated && hasErrors;

  @override
  String toString() {
    return 'GenerationResult('
        ' updatedSourceCode: $updatedSourceCode,'
        ' generatedMethods: $generatedMethods,'
        ' errors: $errors)';
  }
}

sealed class GenerationError {
  const GenerationError();
}

class GenerationFailure extends GenerationError {
  const GenerationFailure({
    required this.message,
  });

  final String message;

  @override
  String toString() => 'GenerationFailure(message: $message)';
}

class NoDefaultGenerationError extends GenerationError {
  const NoDefaultGenerationError({required this.methodType});

  final String methodType;

  @override
  String toString() => 'NoDefaultGenerationError';
}

class ZeroClassOffsetGenerationError extends GenerationError {
  const ZeroClassOffsetGenerationError({required this.methodType});

  final String methodType;

  @override
  String toString() => 'ZeroClassOffsetGenerationError';
}

class NoFieldsGenerationError extends GenerationError {
  const NoFieldsGenerationError({required this.methodType});

  final String methodType;

  @override
  String toString() => 'NoFieldsGenerationError';
}
