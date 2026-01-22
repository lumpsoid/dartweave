import 'package:dartweave/src/domain/entities/entities.dart';

/// Repository interface for parsing Dart classes
abstract class ClassParserRepository {
  /// Parse Dart source code and extract class information
  List<ClassEntity> parseClasses(String sourceCode, String filePath);

  /// Get fields from superclass
  List<Field> getSuperclassFields(ClassEntity classEntity, String sourceCode);
}
