/// Represents a field in a class definition
class Field {
  /// Creates a new [Field] instance
  const Field({
    required this.name,
    required this.type,
    this.nullable = false,
    this.isSuper = false,
  });

  /// The name of the field
  final String name;

  /// The type of the field
  final String type;

  /// Whether the field is nullable
  final bool nullable;

  final bool isSuper;

  /// The Dart code representation of this field's type
  String get typeRepresentation => nullable ? '$type?' : type;

  static String defaultValueFor(
    String type, {
    bool nullable = false,
  }) {
    if (nullable) {
      return 'null';
    }

    switch (type) {
      case 'int':
        return '0';
      case 'double':
        return '0.0';
      case 'bool':
        return 'false';
      case 'String':
        return "''";
      case 'List':
        return 'const []';
      default:
        if (type.startsWith('List<')) {
          final typeParam = type.substring(5, type.length - 1);
          return 'const <$typeParam>[]';
        } else if (type.startsWith('Map<')) {
          return 'const {}';
        } else if (type == 'Map' || type == 'Map<String, dynamic>') {
          return 'const {}';
        } else {
          return '$type.empty()';
        }
    }
  }

  /// Returns the default value for this field's type as a Dart code string
  String get defaultValue => defaultValueFor(
        type,
        nullable: nullable,
      );

  /// Returns the condition expression used to check if this field is empty
  String get isEmptyCondition {
    if (nullable) {
      return '$name == null';
    }

    switch (type) {
      case 'int':
      case 'double':
        return '$name == 0';
      case 'bool':
        return '$name == false';
      case 'String':
        return '$name.isEmpty';
      case 'List':
        return '$name.isEmpty';
      case 'Map':
      case 'Map<String, dynamic>':
        return '$name.isEmpty';
      default:
        if (type.startsWith('List<')) {
          return '$name.isEmpty';
        } else if (type.startsWith('Map<')) {
          return '$name.isEmpty';
        } else {
          return '$name.isEmpty';
        }
    }
  }

  /// Creates a [Field] from a field definition string (e.g., "name:String")
  static Field? fromDefinition(String definition) {
    // Handle nullable types (e.g., "name:String?")
    if (definition.endsWith('?')) {
      final parts = definition.split(':');
      if (parts.length != 2) return null;

      final name = parts[0];
      var type = parts[1];
      // Remove the trailing '?' from the type
      type = type.substring(0, type.length - 1);

      return Field(name: name, type: type, nullable: true);
    } else {
      final parts = definition.split(':');
      if (parts.length != 2) return null;

      return Field(name: parts[0], type: parts[1]);
    }
  }
}
