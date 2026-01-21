import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dartweave/src/models/models.dart';
import 'package:dartweave/src/utils.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template create_class_command}
/// `dartweave create <class_name> [options] [field1:type1 field2:type2 ...]`
/// A [Command] to create a Dart class file with standard methods
/// {@endtemplate}
class CreateClassCommand extends Command<int> {
  /// {@macro create_class_command}
  CreateClassCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output directory path (defaults to current directory)',
      )

      // Add multi-options for getters, methods, and constructors
      ..addMultiOption(
        'getter',
        abbr: 'g',
        help: 'Add a getter to the class (can be used multiple times)',
        splitCommas: false,
      )
      ..addMultiOption(
        'method',
        abbr: 'm',
        help: 'Add a method to the class (can be used multiple times)',
        splitCommas: false,
      )
      ..addMultiOption(
        'constructor',
        abbr: 'c',
        help: 'Add a constructor to the class (can be used multiple times)',
        splitCommas: false,
      );
  }

  @override
  String get description => 'Creates a Dart class file with specified fields';

  @override
  String get name => 'create';

  @override
  String get invocation => '${runner?.executableName} $name'
      ' <class_name> [options] [field1:type1 field2:type2 ...]';

  final Logger _logger;

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      _logger.err('Class name is required');
      printUsage();
      return ExitCode.usage.code;
    }

    final className = argResults!.rest.first;
    final fieldArgs = argResults!.rest.skip(1).toList();
    final outputDir = argResults?['output'] as String? ?? '.';

    // Get the multi-options
    final getters = argResults?['getter'] as List<String>? ?? [];
    final methods = argResults?['method'] as List<String>? ?? [];
    final constructors = argResults?['constructor'] as List<String>? ?? [];

    try {
      _logger.info(
        lightGreen.wrap(
          'Creating class $className',
        ),
      );

      // Parse fields and their types
      final fields = <Field>[];
      for (final fieldArg in fieldArgs) {
        final field = Field.fromDefinition(fieldArg);
        if (field != null) {
          fields.add(field);
        } else {
          _logger.err('Invalid field format: $fieldArg.'
              ' Expected format: name:type or name:type?');
          return ExitCode.usage.code;
        }
      }

      // Generate class content
      _logger
        ..detail('Generating class with ${fields.length} fields')
        ..detail('Adding ${getters.length} getters')
        ..detail('Adding ${methods.length} methods')
        ..detail('Adding ${constructors.length} constructors');

      final content = _generateClassContent(
        className,
        fields,
        getters: getters,
        methods: methods,
        constructors: constructors,
      );

      // Ensure directory exists
      final directory = Directory(outputDir);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      // Write to file
      final fileName = '${className.toSnakeCase()}.dart';
      final filePath = '$outputDir/$fileName';
      final progress = _logger.progress('Writing file $filePath');
      File(filePath).writeAsStringSync(content);
      progress.complete('Created file $filePath');

      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Error creating class: $e');
      return ExitCode.software.code;
    }
  }

  String _generateClassContent(
    String className,
    List<Field> fields, {
    List<String> getters = const [],
    List<String> methods = const [],
    List<String> constructors = const [],
  }) {
    if (fields.isEmpty) {
      _logger.warn('Empty fields. Nothing to do.');
    }

    final buffer = StringBuffer()
      // Class declaration
      ..writeln('class $className {')
      ..writeln()

      // Default constructor
      ..writeln('  const $className({');
    for (final Field(:name) in fields) {
      buffer.writeln('    required this.$name,');
    }
    buffer
      ..writeln('  });')
      ..writeln();

    // Additional constructors
    for (final constructor in constructors) {
      _generateConstructor(buffer, className, fields, constructor);
      buffer.writeln();
    }

    // Fields
    for (final Field(:name, :typeRepresentation) in fields) {
      buffer.writeln('  final $typeRepresentation $name;');
    }
    buffer.writeln();

    // Custom getters
    for (final getter in getters) {
      _generateGetter(buffer, fields, getter);
      buffer.writeln();
    }

    // Custom methods
    for (final method in methods) {
      _generateMethod(buffer, className, fields, method);
      buffer.writeln();
    }

    // Class closing
    buffer.writeln('}');
    return buffer.toString();
  }

  void _generateConstructor(
    StringBuffer buffer,
    String className,
    List<Field> fields,
    String constructor,
  ) {
    switch (constructor) {
      case 'empty':
        generateConstEmptyConstructor(buffer, className, fields);

      case 'fromJson':
        buffer.writeln(
          '  factory $className.fromJson(Map<String, dynamic> json) {',
        );
        buffer.writeln('    return $className(');
        for (final Field(:name, :type) in fields) {
          buffer.writeln("      $name: json['$name'] as $type,");
        }
        buffer.writeln('    );');
        buffer.writeln('  }');
      default:
        buffer.writeln('  // TODO: Implement $constructor constructor');
        buffer.writeln('  // factory $className.$constructor() {');
        buffer.writeln('  //   return $className(');
        buffer.writeln('  //     /* your implementation */');
        buffer.writeln('  //   );');
        buffer.writeln('  // }');
    }
  }

  void _generateGetter(
    StringBuffer buffer,
    List<Field> fields,
    String getter,
  ) {
    // Parse the getter definition to extract name and return type
    final parts = getter.split(':');
    final getterName = parts[0];
    final returnType = parts.length > 1 ? parts[1] : null;

    // Handle predefined getters
    switch (getterName) {
      case 'isEmpty':
        generateIsEmptyGetter(buffer, fields);
        buffer.writeln();
      case 'isNotEmpty':
        buffer.writeln('  bool get isNotEmpty => !isEmpty;');
      default:
        // Use the specified return type if provided, otherwise use 'dynamic'
        final type = returnType ?? 'dynamic';
        buffer.writeln('  // TODO: Implement $getterName getter');
        buffer.write('  $type get $getterName => ');
        if (type != 'dynamic') {
          final defaultValue = Field.defaultValueFor(type);
          buffer.write(defaultValue);
        } else {
          buffer.write('dynamic');
        }
        buffer.writeln(';');
    }
  }

  void _generateMethod(
    StringBuffer buffer,
    String className,
    List<Field> fields,
    String method,
  ) {
    // Parse the method definition to extract name and return type
    final parts = method.split(':');
    final methodName = parts[0];
    final returnType = parts.length > 1 ? parts[1] : null;

    // Handle predefined methods
    switch (methodName) {
      case 'copyWith':
        generateCopyWithMethod(buffer, className, fields);
      case 'toString':
        buffer.writeln('  @override');
        buffer.writeln('  String toString() {');
        buffer.writeln("    return '$className(");
        for (final Field(:name) in fields) {
          buffer.writeln('      $name: \$$name,');
        }
        buffer.writeln("    )';");
        buffer.writeln('  }');
      case 'toJson':
        buffer.writeln('  Map<String, dynamic> toJson() {');
        buffer.writeln('    return {');
        for (final Field(:name) in fields) {
          buffer.writeln("      '$name': $name,");
        }
        buffer.writeln('    };');
        buffer.writeln('  }');
      default:
        // Use the specified return type if provided, otherwise use 'void'
        final type = returnType ?? 'void';
        buffer.writeln('  // TODO: Implement $methodName method');
        buffer.write('  $type $methodName() {');

        // Add return statement placeholder for non-void return types
        if (type != 'void') {
          final defaultValue = Field.defaultValueFor(type);
          buffer
            ..writeln()
            ..writeln('    /* your implementation */')
            ..write('    return $defaultValue;\n  ');
        }

        buffer.writeln('}');
    }
  }
}
