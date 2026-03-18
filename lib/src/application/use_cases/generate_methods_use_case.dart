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

      final updatedClasses = <GenerationResult>[];
      var updatedSourceCode = request.sourceCode;
      var wasUpdated = false;

      for (final classEntity in targetClasses) {
        final generationResult = generatorRepository.generateMethods(
          classEntity,
          request.methodTypes,
          updatedSourceCode,
        );

        if (generationResult.wasUpdated) {
          wasUpdated = true;
          updatedSourceCode = generationResult.updatedSourceCode;
        }
        updatedClasses.add(generationResult);
      }

      return GenerateMethodsOk(
        updatedSourceCode: updatedSourceCode,
        results: updatedClasses,
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
