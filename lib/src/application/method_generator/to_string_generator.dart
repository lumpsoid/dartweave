import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class ToStringGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();

    final buffer = StringBuffer()
      ..writeln('@override\n  String toString() {')
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

    return createSourceCodeChangeForMethod(classEntity, 'toString', buffer);
  }
}
