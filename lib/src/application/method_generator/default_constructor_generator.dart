import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class DefaultConstructorGenerator implements MethodGenerator {
  static const MethodType methodType = MethodType.defaultConstructor;

  @override
  SourceCodeChange generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return ZeroClassOffsetFailure(method: methodType.name);
    }

    final allFields = classEntity.allConstructorFields();

    final existingConstructor =
        classEntity.constructors.where((c) => c.name == null).firstOrNull;

    final isConst = existingConstructor?.isConst ?? false;
    final prefix = isConst ? 'const ' : '';

    // Separate existing params by kind.
    // Positional params are preserved verbatim and emitted before the named
    // block. Named params are keyed by name so we can match them against
    // fields.
    final existingPositional =
        existingConstructor?.parameters.where((p) => p.isPositional).toList() ??
            [];

    // Build a set of names already covered by positional params so we can skip
    // them when iterating fields.
    final positionalParamNames = existingPositional.map((p) => p.name).toSet();

    final existingNamed = {
      if (existingConstructor != null)
        for (final p in existingConstructor.parameters.where((p) => p.isNamed))
          p.name: p,
    };

    final buffer = StringBuffer()..write('$prefix${classEntity.name}(');

    // 1. Emit positional parameters first (preserved verbatim).
    //    These are not tied to fields — just carry them forward unchanged.
    for (final p in existingPositional) {
      buffer.write('${sourceCode.substring(p.offset, p.end)}, ');
    }

    // 2. Open named-parameter block.
    buffer.writeln('{');

    for (final field in allFields) {
      final isPrivate = field.name.startsWith('_');
      final paramName = isPrivate ? field.name.substring(1) : field.name;

      if (positionalParamNames.contains(paramName)) {
        // Already emitted as a positional param above — skip.
        continue;
      }

      if (existingNamed.containsKey(paramName)) {
        // Field was already present as a named param — preserve the user's
        // exact source text for this parameter unchanged.
        final existing = existingNamed[paramName]!;
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

    // Initializer list: emit entries for all private fields still present,
    // whether they existed before or were just added.
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

    return createSourceCodeChangeForConstructor(
      methodType.name,
      classEntity,
      null,
      buffer,
    );
  }
}
