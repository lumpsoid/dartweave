import 'package:dartweave/src/application/method_generator/copy_with_nullable_generator.dart';
import 'package:dartweave/src/application/method_generator/from_json_generator.dart';
import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/entities/entities.dart';
import 'package:dartweave/src/domain/repositories/method_generator_repository.dart';

/// AST-based implementation of MethodGeneratorRepository
class AstMethodGeneratorRepository implements MethodGeneratorRepository {
  @override
  GenerationResult generateMethods(
    ClassEntity classEntity,
    List<MethodType> methodTypes,
    String sourceCode,
  ) {
    final generatedMethods = <String>[];
    final changes = <SourceCodeChange>[];

    for (final methodType in methodTypes) {
      final generator = _getGenerator(methodType, classEntity);
      final change = generator.generate(classEntity, sourceCode);

      changes.add(change);
      if (change is SourceCodeChangeOk) {
        generatedMethods.add(methodType.name);
      }
    }

    if (changes.isEmpty) {
      return GenerationResult(
        className: classEntity.name,
        updatedSourceCode: sourceCode,
        generatedMethods: generatedMethods,
      );
    }

    // Apply changes from bottom to top
    final result = changes.fold(
      (success: <SourceCodeChangeOk>[], errors: <GenerationError>[]),
      (acc, change) => switch (change) {
        SourceCodeChangeOk() => (
            success: acc.success..add(change),
            errors: acc.errors
          ),
        SourceCodeChangeFailure() => (
            success: acc.success,
            errors: acc.errors
              ..add(
                GenerationFailure(message: change.message),
              ),
          ),
        NoDefaultConstructorFailure() => (
            success: acc.success,
            errors: acc.errors
              ..add(
                NoDefaultGenerationError(methodType: change.method),
              ),
          ),
        ZeroClassOffsetFailure() => (
            success: acc.success,
            errors: acc.errors
              ..add(
                ZeroClassOffsetGenerationError(methodType: change.method),
              ),
          ),
        NoFieldsFailure() => (
            success: acc.success,
            errors: acc.errors
              ..add(
                NoFieldsGenerationError(methodType: change.method),
              ),
          ),
      },
    );
    result.success.sort((a, b) => b.startOffset.compareTo(a.startOffset));
    var updatedSourceCode = sourceCode;

    for (final change in result.success) {
      updatedSourceCode = updatedSourceCode.substring(0, change.startOffset) +
          change.newContent +
          updatedSourceCode.substring(change.endOffset);
    }

    return GenerationResult(
      className: classEntity.name,
      updatedSourceCode: updatedSourceCode,
      generatedMethods: generatedMethods,
      errors: result.errors,
    );
  }

  MethodGenerator _getGenerator(
    MethodType methodType,
    ClassEntity classEntity,
  ) {
    switch (methodType) {
      case MethodType.emptyConstructor:
        return EmptyConstructorGenerator();
      case MethodType.defaultConstructor:
        return DefaultConstructorGenerator();
      case MethodType.copyWithMethod:
        return CopyWithGenerator();
      case MethodType.copyWithNullableMethod:
        return CopyWithNullableGenerator();
      case MethodType.toStringMethod:
        return ToStringGenerator();
      case MethodType.hashCodeMethod:
        return HashCodeGenerator();
      case MethodType.equalityOperator:
        return EqualityOperatorGenerator();
      case MethodType.isEmptyGetter:
        return IsEmptyGetterGenerator();
      case MethodType.fromJsonMethod:
        return FromJsonGenerator();
    }
  }
}
