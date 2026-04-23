import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class CopyWithNullableGenerator implements MethodGenerator {
  static const MethodType methodType = MethodType.copyWithNullableMethod;
  @override
  SourceCodeChange generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return ZeroClassOffsetFailure(method: methodType.name);
    }
    // Grab existing default constructor knowledge
    final existingConstructor =
        classEntity.constructors.where((c) => c.name == null).firstOrNull;

    if (existingConstructor == null) {
      return NoDefaultConstructorFailure(method: methodType.name);
    }

    final allFields = classEntity.allConstructorFields();

    // Parameters already written by the user, keyed by public param name.
    final existingParams = {
      for (final p in existingConstructor.parameters) p.name: p,
    };

    final buffer = StringBuffer()
      ..writeln('${classEntity.name} copyWithNullable({');

    for (final field in allFields) {
      final returnType = field.nullable ? '${field.type}?' : field.type;
      buffer.writeln('    $returnType Function()? ${field.name},');
    }

    buffer
      ..writeln('  }) {')
      ..writeln('    return ${classEntity.name}(');

    for (final field in allFields) {
      final param = existingParams[field.name];

      if (param == null) {
        // Field has no matching constructor param — skip or fall back
        // (e.g. it may be initialized in an initializer list, or late)
        continue;
      }

      final accessor =
          field.isSuper ? 'super.${field.name}' : 'this.${field.name}';
      final callSite = param.isNamed ? '${field.name}: ' : '';

      buffer.writeln(
        '      $callSite${field.name} != null'
        ' ? ${field.name}()'
        ' : $accessor,',
      );
    }

    buffer
      ..writeln('    );')
      ..write('  }');

    return createSourceCodeChangeForMethod(
      methodType.name,
      classEntity,
      'copyWithNullable',
      buffer,
    );
  }
}
