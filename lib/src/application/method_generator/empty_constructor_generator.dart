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
      // An empty constructor for a class with no fields doesn't make much sense in this context.
      // Or it would just be `const ClassName.empty();`
      return null;
    }

    final buffer = StringBuffer()
      ..writeln('const ${classEntity.name}.empty()')
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
    buffer.write(';');

    return createSourceCodeChangeForConstructor(classEntity, 'empty', buffer);
  }
}
