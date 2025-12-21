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
    for (final Field(:name) in _fields) {
      _buffer.writeln('    required this.$name,');
    }
    _buffer.write('  });');
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
    for (final Field(:name) in _fields) {
      _buffer.writeln('        other.$name == $name;');
    }
    _buffer.write('  }');
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
