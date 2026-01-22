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

      if (change != null) {
        changes.add(change);
        generatedMethods.add(methodType.name);
      }
    }

    if (changes.isEmpty) {
      return GenerationResult(
        updatedSourceCode: sourceCode,
        wasUpdated: false,
        generatedMethods: generatedMethods,
      );
    }

    // Apply changes from bottom to top
    changes.sort((a, b) => b.startOffset.compareTo(a.startOffset));
    var updatedSourceCode = sourceCode;

    for (final change in changes) {
      updatedSourceCode = updatedSourceCode.substring(0, change.startOffset) +
          change.newContent +
          updatedSourceCode.substring(change.endOffset);
    }

    return GenerationResult(
      updatedSourceCode: updatedSourceCode,
      wasUpdated: true,
      generatedMethods: generatedMethods,
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
      case MethodType.toStringMethod:
        return ToStringGenerator();
      case MethodType.hashCodeMethod:
        return HashCodeGenerator();
      case MethodType.equalityOperator:
        return EqualityOperatorGenerator();
      case MethodType.isEmptyGetter:
        return IsEmptyGetterGenerator();
    }
  }
}
