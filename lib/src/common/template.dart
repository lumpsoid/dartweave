import 'package:dartweave/src/models/models.dart';

/// Base interface for all code generators
abstract class CodeTemplate {
  /// Unique identifier for this template
  String get name;

  /// Human-readable description
  String get description;

  /// Category this template belongs to (method, getter, constructor, etc.)
  String get category;

  String generate({
    required StringBuffer buffer,
    required String className,
    required List<Field> fields,
    Map<String, dynamic>? options,
  });
}

/// Interface for method generators
abstract class MethodTemplate implements CodeTemplate {
  @override
  String get category => 'method';
}

/// Interface for constructor generators
abstract class ConstructorTemplate implements CodeTemplate {
  @override
  String get category => 'constructor';
}

/// Interface for getter generators
abstract class GetterTemplate implements CodeTemplate {
  @override
  String get category => 'getter';
}
