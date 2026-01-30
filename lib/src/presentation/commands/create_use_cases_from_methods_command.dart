import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartweave/src/application/use_cases/generate_use_cases_from_methods_use_case.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

class CreateUseCasesFromMethodsCommand extends Command<int> {
  CreateUseCasesFromMethodsCommand({
    required this.generateUseCasesFromMethodsUseCase,
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'file',
        abbr: 'f',
        help: 'Path to the file containing the class(es).',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Path to the dir for new generated use cases.',
      );
  }

  final GenerateUseCasesFromMethodsUseCase generateUseCasesFromMethodsUseCase;
  final Logger _logger;

  @override
  String get description => 'Generate use cases from class methods';

  @override
  String get name => 'create_use_cases_from_methods';

  @override
  Future<int> run() async {
    final className = argResults!.rest.isEmpty ? '' : argResults!.rest[0];
    final filePath = argResults!['file'] as String?;
    final outputPath = argResults!['output'] as String? ?? '';

    if (filePath == null) {
      _logger.err('File path must be provided');
      return ExitCode.usage.code;
    }

    if (className.isEmpty) {
      _logger.err('Class name must be provided');
      return ExitCode.usage.code;
    }

    try {
      final finalFilePath = filePath;
      final file = File(finalFilePath);

      if (!file.existsSync()) {
        _logger.err('File not found: $finalFilePath');
        return ExitCode.usage.code;
      }

      final sourceCode = file.readAsStringSync();

      _logger.info(
        lightGreen.wrap('Generating'),
      );

      final result = await generateUseCasesFromMethodsUseCase.execute(
        sourceCode,
        finalFilePath,
        outputPath,
      );

      if (result.newFiles.isEmpty) {
        _logger.info('No new files created');
        return ExitCode.success.code;
      }

      // Write updated content
      if (result.updatedSourceCode.isNotEmpty) {
        _logger.success('Successfully updated source code');
        await file.writeAsString(result.updatedSourceCode);
      }

      final directory = p.dirname(finalFilePath);

      for (final entry in result.newFiles) {
        var fileName = entry.fileName;
        var targetPath = p.join(directory, fileName);

        while (File(targetPath).existsSync()) {
          final extension = p.extension(fileName);
          final basename = p.basenameWithoutExtension(fileName);
          fileName = '${basename}01$extension';
          targetPath = p.join(directory, fileName);
        }

        final newFile = File(targetPath);
        await newFile.writeAsString(entry.content);
        _logger.success('Created file: $targetPath');
      }

      return ExitCode.success.code;
    } on Object catch (e, stackTrace) {
      _logger
        ..err('Error: $e')
        ..detail('$stackTrace');
      return ExitCode.software.code;
    }
  }
}
