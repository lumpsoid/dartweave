import 'package:dartweave/src/domain/entities/entities.dart';

/// Repository interface for generating methods
// ignore: one_member_abstracts
abstract class MethodGeneratorRepository {
  /// Generate methods for a class and return updated source code
  GenerationResult generateMethods(
    ClassEntity classEntity,
    List<MethodType> methodTypes,
    String sourceCode,
  );
}
