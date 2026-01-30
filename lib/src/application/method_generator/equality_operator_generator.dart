import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class EqualityOperatorGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();

    final buffer = StringBuffer()
      ..writeln('@override\n  bool operator ==(Object other) {')
      ..writeln('    if (identical(this, other)) return true;')
      ..writeln('    return other is ${classEntity.name} &&');
    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      final endString = i < allFields.length - 1 ? ' &&' : ';';
      buffer.writeln(
        '        other.${field.name} == ${field.name}$endString',
      );
    }
    buffer.write('  }');

    return createSourceCodeChangeForOperator(classEntity, '==', buffer);
  }
}
