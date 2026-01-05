import 'package:dart_create_class/src/models/models.dart';

class MethodGenerator {
  MethodGenerator({
    required String className,
    required List<Field> fields,
  })  : _fields = fields,
        _className = className;

  final String _className;
  final List<Field> _fields;
  final StringBuffer _buffer = StringBuffer();

  @override
  String toString() => _buffer.toString();

  void clear() => _buffer.clear();

  void generateNewConstructor() {
    _buffer.writeln('const $_className({');

    for (final Field(:name, :type, :isSuper) in _fields) {
      if (isSuper) {
        _buffer.writeln('    required super.$name,');
      } else {
        // Check if the field name starts with underscore
        if (name.startsWith('_')) {
          // Remove the underscore for the parameter name
          final paramName = name.substring(1);
          _buffer.writeln('    required $type $paramName,');
        } else {
          _buffer.writeln('    required this.$name,');
        }
      }
    }

    _buffer.write('  })');

    // Add initializer list for fields with underscores
    final privateFields = _fields
        .where(
          (f) => !f.isSuper && f.name.startsWith('_'),
        )
        .toList();
    if (privateFields.isNotEmpty) {
      _buffer.write(' : ');
      for (var i = 0; i < privateFields.length; i++) {
        final name = privateFields[i].name;
        final paramName = name.substring(1);
        _buffer.write('$name = $paramName');
        if (i < privateFields.length - 1) {
          _buffer.write(',\n        ');
        }
      }
    }

    _buffer.write(';');
  }

  void generateConstEmptyConstructor() {
    _buffer
      ..writeln('  const $_className.empty()')
      ..write('      '
          ': ${_fields[0].name} = ${_fields[0].defaultValue}');

    for (var i = 1; i < _fields.length; i++) {
      final name = _fields[i].name;
      final defaultValue = _fields[i].defaultValue;
      _buffer.write(
        ',\n        $name = $defaultValue',
      );
    }

    _buffer.write(';');
  }

  void generateToStringMethod() {
    _buffer
      ..writeln('@override\n  String toString() {')
      ..write("    return '$_className('");
    for (var i = 0; i < _fields.length - 1; i++) {
      final name = _fields[i].name;
      _buffer.writeln("        ' $name: \$$name,'");
    }

    final fieldName = _fields[_fields.length - 1].name;
    _buffer
      ..writeln("        ' $fieldName: \$$fieldName)';")
      ..write('  }');
  }

  void generateCopyWithMethod() {
    _buffer.writeln('  $_className copyWith({');
    for (final Field(:name, :type) in _fields) {
      _buffer.writeln('    $type? $name,');
    }

    _buffer
      ..writeln('  }) {')
      ..writeln('    return $_className(');

    for (final Field(:name) in _fields) {
      _buffer.writeln('      $name: $name ?? this.$name,');
    }

    _buffer
      ..writeln('    );')
      ..writeln('  }');
  }

  void generateIsEmptyGetter() {
    _buffer.write('  bool get isEmpty =>');

    for (var i = 0; i < _fields.length - 1; i++) {
      final isEmptyCondition = _fields[i].isEmptyCondition;
      _buffer.write('\n      $isEmptyCondition &&');
    }
    _buffer.write('\n      ${_fields[_fields.length - 1].isEmptyCondition};');
  }

  void generateEqualityOperator() {
    _buffer
      ..writeln('@override\n  bool operator ==(Object other) {')
      ..writeln('    if (identical(this, other)) return true;')
      ..writeln('    return other is $_className &&');
    for (var i = 0; i < _fields.length - 1; i++) {
      _buffer
          .writeln('        other.${_fields[i].name} == ${_fields[i].name} &&');
    }
    _buffer
      ..writeln('        other.${_fields.last.name} == ${_fields.last.name};')
      ..writeln('  }');
  }

  void generateHashCode() {
    _buffer
      ..writeln('  @override\n  int get hashCode {')
      ..write('    return Object.hash(');
    for (var i = 0; i < _fields.length - 1; i++) {
      _buffer.write(' ${_fields[i].name},');
    }
    _buffer
      ..write(' ${_fields.last.name});')
      ..writeln('  }');
  }

  String get generatedCode => _buffer.toString();
}
