import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class DefaultConstructorGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();
    // For simplicity, we'll generate a default constructor with required
    // `this.field` parameters.
    // A more complete implementation might parse existing constructors to
    // determine `const` or `late`.
    final buffer = StringBuffer()..writeln('${classEntity.name}({');
    for (final field in allFields) {
      // Assuming all fields are required for a default constructor for
      // simplicity
      // Real implementation would inspect nullability and existing constructor
      // parameters
      var paramName = field.name;
      if (paramName.startsWith('_')) {
        paramName =
            paramName.substring(1); // Private field, public parameter name
        buffer.writeln(
          '    required ${field.type}${field.nullable ? '?' : ''} $paramName,',
        );
      } else {
        buffer.writeln('    required this.${field.name},');
      }
    }
    buffer.write('  })');

    final privateInitializers =
        allFields.where((f) => f.name.startsWith('_')).toList();

    if (privateInitializers.isNotEmpty) {
      buffer.write('\n      : ');
      for (var i = 0; i < privateInitializers.length; i++) {
        final f = privateInitializers[i];
        final paramName = f.name.substring(1);
        buffer.write('${f.name} = $paramName');
        if (i < privateInitializers.length - 1) {
          buffer.write(',\n        ');
        }
      }
    }
    buffer.write(';');

    return createSourceCodeChangeForConstructor(classEntity, null, buffer);
  }
}
