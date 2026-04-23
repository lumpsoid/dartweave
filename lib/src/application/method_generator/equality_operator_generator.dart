import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';
import 'package:dartweave/src/domain/write_to_buffer.dart';

class EqualityOperatorGenerator implements MethodGenerator {
  static const MethodType methodType = MethodType.equalityOperator;
  @override
  SourceCodeChange generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return ZeroClassOffsetFailure(method: methodType.name);
    }

    final allFields = classEntity.allConstructorFields();

    final buffer = StringBuffer()
      ..writeln('@override\n  bool operator ==(Object other) =>')
      ..writeln('      identical(this, other) ||')
      ..writeln('      other is ${classEntity.name} &&');
    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      final isNotEndLine = i < allFields.length - 1;
      final endString = isNotEndLine ? ' &&' : ';';
      writeToBuffer(
        buffer,
        '          other.${field.name} == ${field.name}$endString',
        ln: isNotEndLine,
      );
    }

    return createSourceCodeChangeForOperator(
      methodType.name,
      classEntity,
      '==',
      buffer,
    );
  }
}
