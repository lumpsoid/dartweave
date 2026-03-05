import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class DefaultConstructorGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) return null;

    final allFields = classEntity
        .allFields()
        .where((f) => !f.isStatic && !f.isConst)
        .toList();

    final existingConstructor =
        classEntity.constructors.where((c) => c.name == null).firstOrNull;

    final isConst = existingConstructor?.isConst ?? false;
    final prefix = isConst ? 'const ' : '';

    // Parameters already written by the user, keyed by public param name.
    // These are preserved verbatim from source — we must not regenerate them.
    final existingParams = {
      if (existingConstructor != null)
        for (final p in existingConstructor.parameters) p.name: p,
    };

    // Stale params: were in the constructor but their field no longer exists
    // — we drop them by simply not emitting them.

    final buffer = StringBuffer()..writeln('$prefix${classEntity.name}({');

    for (final field in allFields) {
      final isPrivate = field.name.startsWith('_');
      final paramName = isPrivate ? field.name.substring(1) : field.name;

      if (existingParams.containsKey(paramName)) {
        // Field was already present in the constructor — preserve the user's
        // exact source text for this parameter unchanged.
        final existing = existingParams[paramName]!;
        buffer.writeln(
          '    ${sourceCode.substring(existing.offset, existing.end)},',
        );
      } else {
        // New field — not yet in the constructor, generate the default form.
        final typeAnnotation = '${field.type}${field.nullable ? '?' : ''}';
        if (isPrivate) {
          buffer.writeln('    required $typeAnnotation $paramName,');
        } else {
          buffer.writeln('    required this.$paramName,');
        }
      }
    }

    buffer.write('  })');

    // Initializer list: preserve existing entries for private fields still
    // present, append new ones for private fields just added.
    final privateFields =
        allFields.where((f) => f.name.startsWith('_')).toList();
    if (privateFields.isNotEmpty) {
      buffer.write('\n      : ');
      for (var i = 0; i < privateFields.length; i++) {
        final f = privateFields[i];
        final paramName = f.name.substring(1);
        buffer.write('${f.name} = $paramName');
        if (i < privateFields.length - 1) buffer.write(',\n        ');
      }
    }

    buffer.write(';');

    return createSourceCodeChangeForConstructor(classEntity, null, buffer);
  }
}
