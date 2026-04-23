import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class CopyWithGenerator implements MethodGenerator {
  static const MethodType methodType = MethodType.copyWithMethod;

  @override
  SourceCodeChange generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return ZeroClassOffsetFailure(method: methodType.name);
    }

    final allFields = classEntity.allConstructorFields();

    final buffer = StringBuffer()..writeln('${classEntity.name} copyWith({');
    for (final field in allFields) {
      buffer.writeln(
        '    ${field.type}? ${field.name},',
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
      ..write('  }');

    return createSourceCodeChangeForMethod(
      methodType.name,
      classEntity,
      'copyWith',
      buffer,
    );
  }
}
