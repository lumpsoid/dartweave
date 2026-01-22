import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartweave/src/infrastructure/repositories/ast_class_parser_repository.dart';
import 'package:mason_logger/mason_logger.dart';

/// Refactored TestCommand using clean architecture
class TestCommand extends Command<int> {
  TestCommand({
    required this.classParserRepo,
    required Logger logger,
  }) : _logger = logger {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Path to the file containing the class(es).',
    );
  }

  final AstClassParserRepository classParserRepo;
  final Logger _logger;

  @override
  String get description => 'Test';

  @override
  String get name => 'test';

  @override
  Future<int> run() async {
    final filePath = argResults!['file'] as String?;
    if (filePath == null) {
      _logger.err('File not specified');
      return ExitCode.usage.code;
    }
    final file = File(filePath);

    if (!file.existsSync()) {
      _logger.err('File not found: $filePath');
      return ExitCode.usage.code;
    }

    final sourceCode = file.readAsStringSync();

    classParserRepo.parseClasses(sourceCode, filePath).forEach(print);

    return ExitCode.success.code;
  }
}
