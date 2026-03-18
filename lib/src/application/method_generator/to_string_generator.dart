import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class ToStringGenerator implements MethodGenerator {
  static const MethodType methodType = MethodType.toStringMethod;
  @override
  SourceCodeChange generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return ZeroClassOffsetFailure(method: methodType.name);
    }

    final allFields = classEntity.allFields();

    final buffer = StringBuffer()
      ..writeln('@override\n  String toString() {')
      ..writeln("    return '${classEntity.name}('");
    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      final endString = i < allFields.length - 1 ? ',' : '';
      buffer.writeln(
        "        ' ${field.name}: \$${field.name}$endString'",
      ); // Add comma for all but the last field
    }
    buffer
      ..writeln(
        "        ')';",
      ) // Ensure closing parenthesis is outside the last field's quote
      ..write('  }');

    return createSourceCodeChangeForMethod(
      methodType.name,
      classEntity,
      'toString',
      buffer,
    );
  }
}
