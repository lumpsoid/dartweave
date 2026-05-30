import 'package:dartweave/src/domain/entities/entities.dart';
import 'package:dartweave/src/domain/repositories/class_parser_repository.dart';
import 'package:dartweave/src/domain/repositories/method_generator_repository.dart';

/// Use case for generating methods for a class
class GenerateMethodsUseCase {
  GenerateMethodsUseCase({
    required this.parserRepository,
    required this.generatorRepository,
  });

  final ClassParserRepository parserRepository;
  final MethodGeneratorRepository generatorRepository;

  static const Set<MethodType> _constructorMethodTypes = {
    MethodType.emptyConstructor,
    MethodType.defaultConstructor,
  };

  /// Generate methods for a class
  Future<GenerateMethodsResult> execute(GenerationRequest request) async {
    try {
      final classes = parserRepository.parseClasses(
        request.sourceCode,
        request.filePath,
      );

      if (classes.isEmpty) {
        return const NoClassesFoundFailure();
      }

      final targetClasses = _filterTargetClasses(classes, request);
      if (targetClasses.isEmpty) {
        return ClassNotFoundFailure(className: request.className);
      }

      final constructorTypes = request.methodTypes
          .where((t) => _constructorMethodTypes.contains(t))
          .toList();
      final otherTypes = request.methodTypes
          .where((t) => !_constructorMethodTypes.contains(t))
          .toList();

      // resultsByClass preserves insertion order (bottom-to-top by offset) and
      // merges results when a class appears in both passes, so each class
      // prints exactly once in the log.
      final resultsByClass = <String, GenerationResult>{};
      var currentSource = request.sourceCode;
      var wasUpdated = false;

      // Process classes bottom-to-top: new content is always inserted at each
      // class's own closing brace (classEntity.end - 1), so processing a class
      // lower in the file never shifts the offsets of classes above it.
      void runPass(List<ClassEntity> passClasses, List<MethodType> types) {
        final ordered = [...passClasses]
          ..sort((a, b) => b.offset.compareTo(a.offset));
        for (final classEntity in ordered) {
          final result = generatorRepository.generateMethods(
            classEntity,
            types,
            currentSource,
          );
          if (result.wasUpdated) {
            wasUpdated = true;
            currentSource = result.updatedSourceCode;
          }
          final existing = resultsByClass[classEntity.name];
          resultsByClass[classEntity.name] = existing == null
              ? result
              : GenerationResult(
                  className: existing.className,
                  updatedSourceCode: result.updatedSourceCode,
                  generatedMethods: [
                    ...existing.generatedMethods,
                    ...result.generatedMethods,
                  ],
                  errors: [...existing.errors, ...result.errors],
                );
        }
      }

      if (constructorTypes.isNotEmpty && otherTypes.isNotEmpty) {
        // First pass: constructors only, so subsequent generators see them.
        runPass(targetClasses, constructorTypes);

        // Re-parse to expose the new constructor to subsequent generators.
        final reparsedClasses = parserRepository.parseClasses(
          currentSource,
          request.filePath,
        );
        // Second pass: remaining methods with updated class entities.
        runPass(_filterTargetClasses(reparsedClasses, request), otherTypes);
      } else {
        runPass(targetClasses, request.methodTypes);
      }

      return GenerateMethodsOk(
        updatedSourceCode: currentSource,
        results: resultsByClass.values.toList(),
        wasUpdated: wasUpdated,
      );
    } on Object catch (e) {
      return GenerationExceptionFailure(message: e.toString());
    }
  }

  List<ClassEntity> _filterTargetClasses(
    List<ClassEntity> classes,
    GenerationRequest request,
  ) {
    if (request.updateAllClasses) {
      return classes;
    }
    return classes.where((c) => c.name == request.className).toList();
  }
}

/// Input data for generation request
class GenerationRequest {
  const GenerationRequest({
    required this.className,
    required this.filePath,
    required this.sourceCode,
    required this.methodTypes,
    this.updateAllClasses = false,
  });

  final String className;
  final String filePath;
  final String sourceCode;
  final List<MethodType> methodTypes;
  final bool updateAllClasses;
}

/// Output data for generation result
sealed class GenerateMethodsResult {
  const GenerateMethodsResult();
}

class GenerateMethodsOk implements GenerateMethodsResult {
  const GenerateMethodsOk({
    required this.wasUpdated,
    this.updatedSourceCode,
    this.results = const [],
  });

  final bool wasUpdated;
  final String? updatedSourceCode;
  final List<GenerationResult> results;
}

class NoClassesFoundFailure extends GenerateMethodsResult {
  const NoClassesFoundFailure();
}

class ClassNotFoundFailure extends GenerateMethodsResult {
  const ClassNotFoundFailure({required this.className});

  final String className;
}

class GenerationExceptionFailure extends GenerateMethodsResult {
  const GenerationExceptionFailure({required this.message});
  final String message;
}
