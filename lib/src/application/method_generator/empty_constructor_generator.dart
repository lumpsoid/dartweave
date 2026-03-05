import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

/// Implementation for empty constructor generator
class EmptyConstructorGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }
    final allFields = classEntity.allFields();
    if (allFields.isEmpty) {
      return null;
    }

    // Find existing .empty() constructor from the already-parsed entity
    final existingEmptyCtor =
        classEntity.constructors.where((c) => c.name == 'empty').firstOrNull;

    // If it exists, slice its source and parse the initializer body
    final existingDefaults = existingEmptyCtor != null
        ? _parseInitializerBody(
            sourceCode.substring(
                existingEmptyCtor.offset, existingEmptyCtor.end),
          )
        : <String, String>{};

    final buffer = StringBuffer()
      ..writeln('const ${classEntity.name}.empty()')
      ..write('    : ');

    // Build a set of current field names for fast lookup
    final currentFieldNames = allFields.map((f) => f.name).toSet();

    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];

      // Use existing value if it was in the old constructor AND field still exists,
      // otherwise derive a fresh default from the field type.
      final value = (existingDefaults.containsKey(field.name) &&
              currentFieldNames.contains(field.name))
          ? existingDefaults[field.name]!
          : field.defaultValue;

      buffer.write('${field.name} = $value');
      if (i < allFields.length - 1) {
        buffer.write(',\n      ');
      }
    }

    buffer.write(';');
    return createSourceCodeChangeForConstructor(classEntity, 'empty', buffer);
  }

  /// Slices the initializer list from a constructor declaration string and
  /// returns a map of fieldName → assigned value.
  ///
  /// Handles the form:
  /// ```dart
  /// const MyClass.empty()
  ///     : fieldA = someValue,
  ///       fieldB = null;
  /// ```
  Map<String, String> _parseInitializerBody(String constructorSource) {
    final result = <String, String>{};

    // Everything after the first `:` and before the final `;`
    final colonIndex = constructorSource.indexOf(':');
    if (colonIndex == -1) return result;

    final semicolonIndex = constructorSource.lastIndexOf(';');
    if (semicolonIndex == -1 || semicolonIndex <= colonIndex) return result;

    final initializerBlock =
        constructorSource.substring(colonIndex + 1, semicolonIndex).trim();

    // Split on top-level commas (respecting nested parens/brackets/strings)
    final assignments = _splitOnTopLevelCommas(initializerBlock);

    for (final assignment in assignments) {
      final eqIndex = assignment.indexOf('=');
      if (eqIndex == -1) continue;

      final fieldName = assignment.substring(0, eqIndex).trim();
      final value = assignment.substring(eqIndex + 1).trim();

      if (fieldName.isNotEmpty && value.isNotEmpty) {
        result[fieldName] = value;
      }
    }

    return result;
  }

  /// Splits [input] on commas that are not inside parentheses, brackets, or quotes.
  List<String> _splitOnTopLevelCommas(String input) {
    final parts = <String>[];
    var depth = 0;
    var inString = false;
    var stringChar = '';
    final current = StringBuffer();

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];

      if (inString) {
        current.write(ch);
        if (ch == stringChar && (i == 0 || input[i - 1] != r'\')) {
          inString = false;
        }
        continue;
      }

      if (ch == "'" || ch == '"') {
        inString = true;
        stringChar = ch;
        current.write(ch);
        continue;
      }

      if (ch == '(' || ch == '[' || ch == '{') {
        depth++;
        current.write(ch);
        continue;
      }

      if (ch == ')' || ch == ']' || ch == '}') {
        depth--;
        current.write(ch);
        continue;
      }

      if (ch == ',' && depth == 0) {
        final part = current.toString().trim();
        if (part.isNotEmpty) parts.add(part);
        current.clear();
        continue;
      }

      current.write(ch);
    }

    final last = current.toString().trim();
    if (last.isNotEmpty) parts.add(last);

    return parts;
  }
}
