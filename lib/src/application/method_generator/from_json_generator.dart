import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/create_source_code_change_from_class_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';

class FromJsonGenerator implements MethodGenerator {
  static const MethodType methodType = MethodType.fromJsonMethod;

  @override
  SourceCodeChange generate(ClassEntity classEntity, String sourceCode) {
    if (classEntity.isZeroOffset) {
      return ZeroClassOffsetFailure(method: methodType.name);
    }

    final allFields = classEntity
        .allFields()
        .where((f) => !f.isStatic && !f.isConst)
        .toList();

    final buffer = StringBuffer()
      ..writeln('static ${classEntity.name}? fromJson(dynamic jsonRaw) {')
      ..writeln(
        '  final json = jsonRaw is Map<String, dynamic> ? jsonRaw : null;',
      )
      ..writeln('  if (json == null) return null;')
      ..writeln();

    // 1. Declare a raw variable for each field.
    for (final field in allFields) {
      final isPrivate = field.name.startsWith('_');
      final paramName = isPrivate ? field.name.substring(1) : field.name;
      buffer.writeln("  final $paramName = json['$paramName'];");
    }

    buffer
      ..writeln()

      // 2. Constructor call — cast using the local variable.
      ..writeln('  return ${classEntity.name}(');

    for (final field in allFields) {
      final isPrivate = field.name.startsWith('_');
      final paramName = isPrivate ? field.name.substring(1) : field.name;
      final castExpr = _castExpression(
        varName: paramName,
        type: field.type,
        nullable: field.nullable,
        defaultVal: field.defaultValue,
      );
      buffer.writeln('    $paramName: $castExpr,');
    }

    buffer
      ..writeln('  );')
      ..write('}');

    return createSourceCodeChangeForMethod(
      methodType.name,
      classEntity,
      'fromJson',
      buffer,
    );
  }

  String _castExpression({
    required String varName,
    required String type,
    required bool nullable,
    required String defaultVal,
  }) {
    if (nullable) {
      return _nullableCast(varName, type);
    }

    switch (type) {
      case 'String':
        return '$varName is String ? $varName : $defaultVal';
      case 'int':
        return '($varName is int ? $varName '
            ': $varName is double ? ($varName as double).toInt()'
            ' : $defaultVal)';
      case 'double':
        return '($varName is double ? $varName '
            ': $varName is int ? ($varName as int).toDouble() : $defaultVal)';
      case 'bool':
        return '$varName is bool ? $varName : $defaultVal';
      case 'List':
        return '$varName is List ? List.from($varName) : $defaultVal';
      case 'Map':
        return '$varName is Map<String, dynamic> '
            '? Map<String, dynamic>.from($varName) : $defaultVal';
      case 'Set':
        return '$varName is List ? Set.from($varName) : $defaultVal';
      default:
        return '$varName as $type? ?? $defaultVal '
            '/* TODO: implement $type.fromJson */';
    }
  }

  String _nullableCast(String varName, String type) {
    switch (type) {
      case 'String':
        return '$varName is String ? $varName : null';
      case 'int':
        return '($varName is int ? $varName '
            ': $varName is double ? ($varName as double).toInt() : null)';
      case 'double':
        return '($varName is double ? $varName '
            ': $varName is int ? ($varName as int).toDouble() : null)';
      case 'bool':
        return '$varName is bool ? $varName : null';
      case 'List':
        return '$varName is List ? List.from($varName) : null';
      case 'Map':
        return '$varName is Map ? Map<String, dynamic>.from($varName as Map)'
            ' : null';
      case 'Set':
        return '$varName is List ? Set.from($varName as List) : null';
      default:
        return '$varName as $type? /* TODO: implement $type.fromJson */';
    }
  }
}
