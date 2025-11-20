import 'package:dart_create_class/src/models/models.dart';

void generateDefaultConstructor(
  StringBuffer buffer,
  String className,
  List<Field> fields,
) {
  buffer.writeln('  const $className({');
  for (final Field(:name) in fields) {
    buffer.writeln('    required this.$name,');
  }
  buffer.writeln('  });');
}

void generateToStringMethod(
  StringBuffer buffer,
  String className,
  List<Field> fields,
) {
  buffer
    ..writeln('@override\n  String toString() {')
    ..write('    return ')
    ..writeln("'$className('");
  for (var i = 0; i < fields.length - 1; i++) {
    final name = fields[i].name;
    buffer.writeln("        ' $name: \$$name,'");
  }

  final fieldName = fields[fields.length - 1].name;
  buffer
    ..writeln("        ' $fieldName: \$$fieldName)';")
    ..writeln('  }');
}

void generateConstEmptyConstructor(
  StringBuffer buffer,
  String className,
  List<Field> fields,
) {
  buffer
    ..writeln('  const $className.empty()')
    ..write('      '
        ': ${fields[0].name} = ${fields[0].defaultValue}');

  for (var i = 1; i < fields.length; i++) {
    final name = fields[i].name;
    final defaultValue = fields[i].defaultValue;
    buffer.write(
      ',\n        $name = $defaultValue',
    );
  }

  buffer.write(';');
}

void generateIsEmptyGetter(
  StringBuffer buffer,
  List<Field> fields,
) {
  buffer.write('  bool get isEmpty =>');

  for (var i = 0; i < fields.length - 1; i++) {
    final isEmptyCondition = fields[i].isEmptyCondition;
    buffer.write('\n      $isEmptyCondition &&');
  }
  buffer.write('\n      ${fields[fields.length - 1].isEmptyCondition};');
}

void generateCopyWithMethod(
  StringBuffer buffer,
  String className,
  List<Field> fields,
) {
  buffer.writeln('  $className copyWith({');

  for (final Field(:name, :type) in fields) {
    buffer.writeln('    $type? $name,');
  }

  buffer
    ..writeln('  }) {')
    ..writeln('    return $className(');

  for (final Field(:name) in fields) {
    buffer.writeln('      $name: $name ?? this.$name,');
  }

  buffer
    ..writeln('    );')
    ..writeln('  }');
}

extension NameConversion on String {
  /// Converts a string to snake_case
  String toSnakeCase() {
    if (isEmpty) return '';

    final result = StringBuffer();

    for (var i = 0; i < length; i++) {
      final char = this[i];
      final isUpperCase =
          char == char.toUpperCase() && char != char.toLowerCase();

      if (isUpperCase && i > 0 && this[i - 1] != '_') {
        result.write('_');
      }

      result.write(char.toLowerCase());
    }

    return result.toString().replaceAll(RegExp(r'[^\w_]'), '_');
  }

  /// Converts a string to camelCase
  String toCamelCase() {
    if (isEmpty) return '';

    final words = replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'[\s_-]+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return '';

    return words[0].toLowerCase() +
        words
            .sublist(1)
            .map((word) =>
                word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join('');
  }

  /// Converts a string to PascalCase
  String toPascalCase() {
    if (isEmpty) return '';

    final words = replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'[\s_-]+'))
        .where((word) => word.isNotEmpty)
        .toList();

    return words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join('');
  }

  /// Converts a string to kebab-case
  String toKebabCase() {
    if (isEmpty) return '';

    final result = StringBuffer();

    for (var i = 0; i < length; i++) {
      final char = this[i];
      final isUpperCase =
          char == char.toUpperCase() && char != char.toLowerCase();

      if (isUpperCase && i > 0 && this[i - 1] != '-') {
        result.write('-');
      }

      result.write(char.toLowerCase());
    }

    return result.toString().replaceAll(RegExp(r'[^\w-]'), '-');
  }

  /// Converts a string to CONSTANT_CASE
  String toConstantCase() {
    return toSnakeCase().toUpperCase();
  }

  /// Converts a string to Title Case
  String toTitleCase() {
    if (isEmpty) return '';

    return replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
