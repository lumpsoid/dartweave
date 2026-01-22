import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dartweave/src/application/method_generator/method_generator.dart';
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
      // An empty constructor for a class with no fields doesn't make much sense in this context.
      // Or it would just be `const ClassName.empty();`
      return null;
    }

    final buffer = StringBuffer()
      ..writeln('  const ${classEntity.name}.empty()')
      ..write('      : ');

    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      // For simplicity, we'll assume a default value can be assigned.
      // In a real scenario, you'd need more sophisticated default value logic
      // based on field type (e.g., 0 for int, '' for String, false for bool, etc.)
      // Also, handling nullable types for default values.
      String defaultValue;
      if (field.type == 'String') {
        defaultValue = "''";
      } else if (field.type == 'int' || field.type == 'double') {
        defaultValue = '0';
      } else if (field.type == 'bool') {
        defaultValue = 'false';
      } else if (field.nullable) {
        defaultValue = 'null';
      } else {
        // Fallback for types that might not have a simple default
        defaultValue = 'null'; // Might cause compilation errors
      }

      buffer.write('${field.name} = $defaultValue');
      if (i < allFields.length - 1) {
        buffer.write(',\n        ');
      }
    }
    buffer.writeln(';');

    return SourceCodeChange(
      startOffset: classEntity.end - 1, // Insert before the last '}'
      endOffset: classEntity.end - 1,
      newContent: '\n$buffer\n',
    );
  }
}

class _ClassFinderVisitor extends GeneralizingAstVisitor<void> {
  _ClassFinderVisitor(this._onClassFound);

  final void Function(ClassDeclaration) _onClassFound;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _onClassFound(node);
    super.visitClassDeclaration(node);
  }
}

class DefaultConstructorGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();
    // For simplicity, we'll generate a default constructor with required
    // `this.field` parameters.
    // A more complete implementation might parse existing constructors to
    // determine `const` or `late`.
    final buffer = StringBuffer()..writeln('  ${classEntity.name}({');
    for (final field in allFields) {
      // Assuming all fields are required for a default constructor for
      // simplicity
      // Real implementation would inspect nullability and existing constructor
      // parameters
      String paramName = field.name;
      if (paramName.startsWith('_')) {
        paramName =
            paramName.substring(1); // Private field, public parameter name
        buffer.writeln(
          '    required ${field.type}${field.nullable ? '?' : ''} $paramName,',
        );
      } else {
        buffer.writeln('    required this.${field.name},');
      }
    }
    buffer.write('  })');

    final privateInitializers =
        allFields.where((f) => f.name.startsWith('_')).toList();

    if (privateInitializers.isNotEmpty) {
      buffer.write('\n      : ');
      for (var i = 0; i < privateInitializers.length; i++) {
        final f = privateInitializers[i];
        final paramName = f.name.substring(1);
        buffer.write('${f.name} = $paramName');
        if (i < privateInitializers.length - 1) {
          buffer.write(',\n        ');
        }
      }
    }
    buffer.writeln(';');

    return SourceCodeChange(
      startOffset: classEntity.end - 1,
      endOffset: classEntity.end - 1,
      newContent: '\n$buffer\n',
    );
  }
}

class CopyWithGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();

    final buffer = StringBuffer()..writeln('  ${classEntity.name} copyWith({');
    for (final field in allFields) {
      buffer.writeln(
        '    ${field.type}${field.nullable ? '' : '?'} ${field.name},',
      );
    }

    buffer
      ..writeln('  }) {')
      ..writeln('    return ${classEntity.name}(');

    for (final field in allFields) {
      buffer
          .writeln('      ${field.name}: ${field.name} ?? this.${field.name},');
    }

    buffer
      ..writeln('    );')
      ..writeln('  }');

    return SourceCodeChange(
      startOffset: classEntity.end - 1,
      endOffset: classEntity.end - 1,
      newContent: '\n$buffer\n',
    );
  }
}

class ToStringGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();

    final buffer = StringBuffer()
      ..writeln('  @override\n  String toString() {')
      ..write("    return '${classEntity.name}('");
    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      final endString = i < allFields.length - 1 ? ',' : '';
      buffer.write(
        "        ' ${field.name}: \$${field.name}$endString'",
      ); // Add comma for all but the last field
    }
    buffer
      ..writeln(
        "        ')';",
      ) // Ensure closing parenthesis is outside the last field's quote
      ..write('  }');

    return SourceCodeChange(
      startOffset: classEntity.end - 1,
      endOffset: classEntity.end - 1,
      newContent: '\n$buffer\n',
    );
  }
}

class HashCodeGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();

    if (allFields.isEmpty) {
      // If there are no fields, we can just return a constant hash.
      // But for consistency with Object.hash, we'll still call it with no args.
      final buffer = StringBuffer()
        ..writeln('  @override\n  int get hashCode {')
        ..writeln('    return Object.hashAll([]);') // or just Object.hash(0);
        ..writeln('  }');

      return SourceCodeChange(
        startOffset: classEntity.end - 1,
        endOffset: classEntity.end - 1,
        newContent: '\n$buffer\n',
      );
    }

    final buffer = StringBuffer()
      ..writeln('  @override\n  int get hashCode {')
      ..write('    return Object.hash(');
    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      buffer.write(
        ' ${field.name}${i < allFields.length - 1 ? ',' : ''}',
      );
    }
    buffer
      ..writeln(');')
      ..writeln('  }');

    return SourceCodeChange(
      startOffset: classEntity.end - 1,
      endOffset: classEntity.end - 1,
      newContent: '\n$buffer\n',
    );
  }
}

class EqualityOperatorGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();

    final buffer = StringBuffer()
      ..writeln('  @override\n  bool operator ==(Object other) {')
      ..writeln('    if (identical(this, other)) return true;')
      ..writeln('    return other is ${classEntity.name} &&');
    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      final endString = i < allFields.length - 1 ? ' &&' : ';';
      buffer.writeln(
        '        other.${field.name} == ${field.name}$endString',
      );
    }
    buffer.writeln('  }');

    return SourceCodeChange(
      startOffset: classEntity.end - 1,
      endOffset: classEntity.end - 1,
      newContent: '\n$buffer\n',
    );
  }
}

class IsEmptyGetterGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();
    if (allFields.isEmpty) {
      final buffer = StringBuffer()
        // If there are no fields, then by default it's considered empty.
        // Or you might have a different default logic.
        ..writeln('  bool get isEmpty => true;');

      return SourceCodeChange(
        startOffset: classEntity.end - 1,
        endOffset: classEntity.end - 1,
        newContent: '\n$buffer\n',
      );
    }

    final buffer = StringBuffer()..write('  bool get isEmpty =>');

    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      // This is a simplified condition. Real implementations might check
      // specific types or if a field is null for nullable types.
      String isEmptyCondition;
      if (field.type == 'String') {
        isEmptyCondition = '${field.name}.isEmpty';
      } else if (field.type == 'List' ||
          field.type == 'Map' ||
          field.type == 'Set') {
        isEmptyCondition =
            // Assuming nullable collections
            '${field.name} == null || ${field.name}.isEmpty';
      } else if (field.nullable) {
        isEmptyCondition = '${field.name} == null';
      } else {
        // For non-nullable non-collection basic types, determining "empty" is
        // often not applicable or requires a specific value (e.g., 0 for int).
        // This example assumes non-nullable fields are never "empty" in this
        // context. For this example, we'll just consider it not empty.
        isEmptyCondition = 'false'; // Or a more specific check based on type
      }
      final endString = i < allFields.length - 1 ? ' &&' : ';';

      buffer.write('\n      $isEmptyCondition$endString');
    }
    buffer.writeln();

    return SourceCodeChange(
      startOffset: classEntity.end - 1,
      endOffset: classEntity.end - 1,
      newContent: '\n$buffer\n',
    );
  }
}
