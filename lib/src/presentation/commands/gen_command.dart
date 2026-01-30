import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartweave/src/application/use_cases/generate_methods_use_case.dart';
import 'package:dartweave/src/domain/entities/entities.dart';
import 'package:mason_logger/mason_logger.dart';

class GenCommand extends Command<int> {
  GenCommand({
    required this.generateMethodsUseCase,
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'file',
        abbr: 'f',
        help: 'Path to the file containing the class(es).',
      )
      ..addFlag(
        'all-classes',
        abbr: 'a',
        help: 'Sync methods for all classes in the file',
        negatable: false,
      )
      ..addMultiOption(
        'constructor',
        abbr: 'c',
        help: 'Constructors to sync (new, empty)',
        allowed: ['new', 'empty'],
      )
      ..addMultiOption(
        'method',
        abbr: 'm',
        help: 'Methods to sync',
        allowed: ['copyWith', 'toString', 'hashCode'],
      )
      ..addMultiOption(
        'getter',
        abbr: 'g',
        help: 'Getters to sync (isEmpty)',
        allowed: ['isEmpty'],
      )
      ..addMultiOption(
        'operator',
        abbr: 'o',
        help: 'Operators to sync',
        allowed: ['equality'],
      );
  }

  final GenerateMethodsUseCase generateMethodsUseCase;
  final Logger _logger;

  @override
  String get description => 'Generate code for Dart classes';

  @override
  String get name => 'gen';

  @override
  Future<int> run() async {
    final className = argResults!.rest.isEmpty ? '' : argResults!.rest[0];
    final filePath = argResults!['file'] as String?;

    if (className.isEmpty && filePath == null) {
      _logger.err('Either class name or file path must be provided');
      return ExitCode.usage.code;
    }

    final methodTypes = _parseMethodTypes();
    if (methodTypes.isEmpty) {
      _logger.err('No method types specified');
      return ExitCode.usage.code;
    }

    try {
      final finalFilePath = filePath ?? '${className.toSnakeCase()}.dart';
      final file = File(finalFilePath);

      if (!file.existsSync()) {
        _logger.err('File not found: $finalFilePath');
        return ExitCode.usage.code;
      }

      final sourceCode = file.readAsStringSync();
      final request = GenerationRequest(
        className: className,
        filePath: finalFilePath,
        sourceCode: sourceCode,
        methodTypes: methodTypes,
        updateAllClasses: argResults!['all-classes'] as bool,
      );

      _logger.info(
        lightGreen.wrap(
          'Generating ${methodTypes.length} method(s)'
          ' for ${request.updateAllClasses ? 'all classes' : className}',
        ),
      );

      final result = await generateMethodsUseCase.execute(request);

      if (!result.isSuccess) {
        _logger.err(result.errorMessage);
        return ExitCode.software.code;
      }

      if (!result.wasUpdated) {
        _logger.info('No changes were made to the file');
        return ExitCode.success.code;
      }

      // Write updated content
      await file.writeAsString(result.updatedSourceCode!);

      _logger.success('Successfully generated methods');
      for (final entry in result.methodsByClass.entries) {
        _logger.success(
          'Class ${entry.key}: ${entry.value.join(", ")}',
        );
      }

      return ExitCode.success.code;
    } on Object catch (e, stackTrace) {
      _logger
        ..err('Error: $e')
        ..detail('$stackTrace');
      return ExitCode.software.code;
    }
  }

  List<MethodType> _parseMethodTypes() {
    final types = <MethodType>[];

    void addTypes(List<String>? names) {
      if (names != null) {
        for (final name in names) {
          try {
            types.add(MethodType.fromName(name));
          } on Object catch (_) {
            _logger.warn('Skipping unknown method type: $name');
          }
        }
      }
    }

    addTypes(argResults?['constructor'] as List<String>?);
    addTypes(argResults?['method'] as List<String>?);
    addTypes(argResults?['getter'] as List<String>?);
    addTypes(argResults?['operator'] as List<String>?);

    return types;
  }
}

extension on String {
  String toSnakeCase() {
    return replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp('^_'), '');
  }
}
