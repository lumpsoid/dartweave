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
    final rawChanges = <SourceCodeChange>[];

    for (final methodType in methodTypes) {
      final generator = _getGenerator(methodType, classEntity);
      final change = generator.generate(classEntity, sourceCode);

      rawChanges.add(change);
      if (change is SourceCodeChangeOk) {
        generatedMethods.add(methodType.name);
      }
    }

    final result = rawChanges.fold(
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

    // Reverse before stable sort so same-offset changes (multiple new methods
    // all appended at classEntity.end - 1) are applied in reverse-generation
    // order, which makes them appear in generation order in the final output.
    final orderedChanges = result.success.reversed.toList()
      ..sort((a, b) => b.startOffset.compareTo(a.startOffset));
    var updatedSourceCode = sourceCode;

    for (final change in orderedChanges) {
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
