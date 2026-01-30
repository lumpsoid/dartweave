import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class IsEmptyGetterGenerator implements MethodGenerator {
  @override
  SourceCodeChange? generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return null;
    }

    final allFields = classEntity.allFields();
    if (allFields.isEmpty) {
      final buffer = StringBuffer()
        // If there are no fields, then by default it's considered empty.
        // Or you might have a different default logic.
        ..write('bool get isEmpty => true;');

      return createSourceCodeChangeForGetter(classEntity, 'isEmpty', buffer);
    }

    final buffer = StringBuffer()..write('bool get isEmpty =>');

    for (var i = 0; i < allFields.length; i++) {
      final field = allFields[i];
      // This is a simplified condition. Real implementations might check
      // specific types or if a field is null for nullable types.
      String isEmptyCondition;
      if (field.type == 'String') {
        isEmptyCondition = '${field.name}.isEmpty';
      } else if (field.type == 'List' ||
          field.type == 'Map' ||
          field.type == 'Set') {
        isEmptyCondition =
            // Assuming nullable collections
            '${field.name} == null || ${field.name}.isEmpty';
      } else if (field.nullable) {
        isEmptyCondition = '${field.name} == null';
      } else {
        // For non-nullable non-collection basic types, determining "empty" is
        // often not applicable or requires a specific value (e.g., 0 for int).
        // This example assumes non-nullable fields are never "empty" in this
        // context. For this example, we'll just consider it not empty.
        isEmptyCondition = 'false'; // Or a more specific check based on type
      }
      final endString = i < allFields.length - 1 ? ' &&' : ';';

      buffer.write('\n      $isEmptyCondition$endString');
    }

    return createSourceCodeChangeForGetter(classEntity, 'isEmpty', buffer);
  }
}
