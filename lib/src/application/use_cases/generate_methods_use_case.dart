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
  Future<GenerationResult> execute(GenerationRequest request) async {
    try {
      final classes = parserRepository.parseClasses(
        request.sourceCode,
        request.filePath,
      );

      if (classes.isEmpty) {
        return GenerationResult.failure('No classes found in the file');
      }

      final targetClasses = _filterTargetClasses(classes, request);
      if (targetClasses.isEmpty) {
        return GenerationResult.failure(
          'Class "${request.className}" not found',
        );
      }

      final updatedClasses = <String>[];
      final methodsByClass = <String, List<String>>{};
      var updatedSourceCode = request.sourceCode;

      for (final classEntity in targetClasses) {
        final generationResult = generatorRepository.generateMethods(
          classEntity,
          request.methodTypes,
          updatedSourceCode,
        );

        if (generationResult.wasUpdated) {
          updatedSourceCode = generationResult.updatedSourceCode;
          updatedClasses.add(classEntity.name);
          methodsByClass[classEntity.name] = generationResult.generatedMethods;
        }
      }

      return GenerationResult.success(
        updatedSourceCode: updatedSourceCode,
        updatedClasses: updatedClasses,
        methodsByClass: methodsByClass,
      );
    } on Object catch (e) {
      return GenerationResult.failure(e.toString());
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
class GenerationResult {
  const GenerationResult({
    required this.isSuccess,
    this.updatedSourceCode,
    this.updatedClasses = const [],
    this.methodsByClass = const {},
    this.errorMessage,
  });

  factory GenerationResult.success({
    required String updatedSourceCode,
    List<String> updatedClasses = const [],
    Map<String, List<String>> methodsByClass = const {},
  }) {
    return GenerationResult(
      isSuccess: true,
      updatedSourceCode: updatedSourceCode,
      updatedClasses: updatedClasses,
      methodsByClass: methodsByClass,
    );
  }

  factory GenerationResult.failure(String errorMessage) {
    return GenerationResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  final bool isSuccess;
  final String? updatedSourceCode;
  final List<String> updatedClasses;
  final Map<String, List<String>> methodsByClass;
  final String? errorMessage;

  bool get wasUpdated => updatedClasses.isNotEmpty;
}
