import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class HashCodeGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();

    final buffer = StringBuffer()..writeln('@override\n  int get hashCode {');
    if (allFields.isEmpty) {
      // If there are no fields, we can just return a constant hash.
      // But for consistency with Object.hash, we'll still call it with no args.
      buffer
        ..writeln('    return Object.hashAll([]);') // or just Object.hash(0);
        ..write('  }');

      return createSourceCodeChangeForGetter(classEntity, 'hashCode', buffer);
    } else if (allFields.length == 1) {
      buffer
        ..writeln(
          '    return ${allFields.first.name}.hashCode;',
        )
        ..write('  }');

      return createSourceCodeChangeForGetter(classEntity, 'hashCode', buffer);
    } else {
      buffer.write('    return Object.hash(');
      for (var i = 0; i < allFields.length; i++) {
        final field = allFields[i];
        buffer.write(
          ' ${field.name}${i < allFields.length - 1 ? ',' : ''}',
        );
      }
      buffer.writeln(');');
    }

    buffer.write('  }');

    return createSourceCodeChangeForGetter(classEntity, 'hashCode', buffer);
  }
}
