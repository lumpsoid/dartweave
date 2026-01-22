import 'package:dartweave/src/domain/entities/entities.dart';

/// Base class for method generators
// ignore: one_member_abstracts
abstract class MethodGenerator {
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode);
}
