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

  void generateConstructor({ConstructorInfo? existing}) {
    final isConst = existing?.isConst ?? true;
    _buffer
      ..write(isConst ? 'const ' : '')
      ..writeln('$_className({');

    final privateInitializers = <Field>[];
    final processedNames = <String>{};

    // 1. Process existing parameters first to preserve order/defaults
    if (existing != null) {
      for (final param in existing.params) {
        _writeExistingParam(param);
        processedNames.add(param.name);
      }
    }

    // 2. Add new fields that weren't in the existing constructor
    for (final field in _fields) {
      final paramName =
          field.name.startsWith('_') ? field.name.substring(1) : field.name;

      if (!processedNames.contains(paramName)) {
        _writeField(field);
        processedNames.add(paramName);
      }

      // Track if it needs an initializer (private field)
      if (!field.isSuper && field.name.startsWith('_')) {
        privateInitializers.add(field);
      }
    }

    _buffer.write('  })');

    // 3. Initializer list (e.g., : _field = field)
    if (privateInitializers.isNotEmpty) {
      _buffer.write('\n      : ');
      for (var i = 0; i < privateInitializers.length; i++) {
        final f = privateInitializers[i];
        final paramName = f.name.substring(1);
        _buffer.write('${f.name} = $paramName');
        if (i < privateInitializers.length - 1) {
          _buffer.write(',\n        ');
        }
      }
    }
    _buffer.write(';');
  }

  void _writeExistingParam(ConstructorParam param) {
    final req = param.isRequired ? 'required ' : '';
    final def = param.defaultValue != null ? ' = ${param.defaultValue}' : '';

    String paramCode;
    switch (param.type) {
      case ParamType.thisField:
        paramCode = 'this.${param.name}';
      case ParamType.superField:
        paramCode = 'super.${param.name}';
      case ParamType.formal:
        // Include type if it was explicitly defined in the original code
        final typePrefix = param.typeName != null ? '${param.typeName} ' : '';
        paramCode = '$typePrefix${param.name}';
    }

    _buffer.writeln('    $req$paramCode$def,');
  }

  void _writeField(Field field) {
    if (field.isSuper) {
      _buffer.writeln('    required super.${field.name},');
    } else if (field.name.startsWith('_')) {
      final paramName = field.name.substring(1);
      _buffer.writeln('    required ${field.type} $paramName,');
    } else {
      _buffer.writeln('    required this.${field.name},');
    }
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
