import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class CopyWithGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();

    final buffer = StringBuffer()..writeln('${classEntity.name} copyWith({');
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
      ..write('  }');

    return createSourceCodeChangeForMethod(classEntity, 'copyWith', buffer);
  }
}
