import 'dart:io';

import 'package:dartweave/src/application/method_generator/method_generator.dart';
import 'package:dartweave/src/domain/domain.dart';
import 'package:dartweave/src/domain/repositories/repositories.dart';
import 'package:path/path.dart' as p;

SourceCodeChange generateForMethod(
  ClassEntity classEntity,
  MethodEntity method,
) {
  final useCaseClassName =
      '${classEntity.name}${_capitalize(method.name)}UseCase';
  final fieldName = '_${_uncapitalize(useCaseClassName)}';

  final buffer = StringBuffer()
    ..write('${method.returnType} ${method.name}(')
    // ... existing parameters logic ...
    ..writeln(') => $fieldName.execute();');

  return createSourceCodeChangeForMethod(classEntity, method.name, buffer);
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
String _uncapitalize(String s) =>
    s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

/// Use case for generating methods for a class
class GeneratedUseCaseFile {
  GeneratedUseCaseFile(this.fileName, this.content);
  final String fileName;
  final String content;
}

class UseCaseGenerationResult {
  UseCaseGenerationResult(this.updatedSourceCode, this.newFiles);
  final String updatedSourceCode;
  final List<GeneratedUseCaseFile> newFiles;
}

class GenerateUseCasesFromMethodsUseCase {
  GenerateUseCasesFromMethodsUseCase({required this.parserRepository});
  final ClassParserRepository parserRepository;
  final DefaultConstructorGenerator constructorGenerator =
      DefaultConstructorGenerator();

  String? _findPackageName(String filePath) {
    var directory = Directory(p.dirname(filePath));
    while (directory.path != directory.parent.path) {
      final pubspec = File(p.join(directory.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        final lines = pubspec.readAsLinesSync();
        for (final line in lines) {
          if (line.startsWith('name:')) {
            return line.replaceFirst('name:', '').trim();
          }
        }
      }
      directory = directory.parent;
    }
    return null;
  }

  Future<UseCaseGenerationResult> execute(
    String sourceCode,
    String filePath,
    String outputPath,
  ) async {
    final context = _GenerationContext(
      packageName: _findPackageName(filePath) ?? 'unknown_package',
      relativeToLib: _getRelativeToLib(filePath),
      sourceCode: sourceCode,
    );

    final classes = parserRepository.parseClasses(sourceCode, filePath);
    var currentSource = sourceCode;
    final allNewFiles = <GeneratedUseCaseFile>[];

    for (final classEntity in classes) {
      final extraction = _extractMethodsToUseCases(classEntity, context);

      if (extraction.newFiles.isEmpty) continue;

      allNewFiles.addAll(extraction.newFiles);
      currentSource = _applyChangesToClass(
        currentSource,
        classEntity,
        extraction,
        context,
      );
    }

    return UseCaseGenerationResult(currentSource, allNewFiles);
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
  String _uncapitalize(String s) => s[0].toLowerCase() + s.substring(1);
  String _toSnakeCase(String s) => s
      .replaceAllMapped(
        RegExp('([A-Z])'),
        (m) => '_${m.group(1)!.toLowerCase()}',
      )
      .substring(1);

  _ExtractionResult _extractMethodsToUseCases(
    ClassEntity classEntity,
    _GenerationContext context,
  ) {
    final newFiles = <GeneratedUseCaseFile>[];
    final fields = <Field>[];
    final methodChanges = <SourceCodeChange>[];

    for (final method in classEntity.methods) {
      if (method.isStatic || method.name.startsWith('_')) continue;

      final ucName = '${classEntity.name}${_capitalize(method.name)}UseCase';
      final fileName = '${_toSnakeCase(ucName)}.dart';
      final body =
          context.sourceCode.substring(method.body.offset, method.body.end);

      newFiles.add(
        GeneratedUseCaseFile(fileName, _buildUseCaseContent(ucName, body)),
      );
      fields.add(
        Field(
          name: '_${_uncapitalize(ucName)}',
          type: ucName,
          isFinal: true,
          offset: 0,
          end: 0,
        ),
      );
      methodChanges.add(generateForMethod(classEntity, method));
    }

    return _ExtractionResult(newFiles, fields, methodChanges);
  }

  String _applyChangesToClass(
    String source,
    ClassEntity classEntity,
    _ExtractionResult extraction,
    _GenerationContext context,
  ) {
    final changes = [...extraction.methodChanges];

    // 1. Handle Imports
    for (final file in extraction.newFiles) {
      final path = context.relativeToLib.isEmpty
          ? './${file.fileName}'
          : 'package:${context.packageName}/${context.relativeToLib}/${file.fileName}';
      changes.add(
        SourceCodeChange(
          startOffset: 0,
          endOffset: 0,
          newContent: "import '$path';\n",
        ),
      );
    }

    // 2. Handle Fields and Constructor
    changes
      ..add(
        _generateMemberChange(
          classEntity,
          extraction.newUseCaseFields,
          source,
        ),
      )

      // Sort descending to apply changes without breaking offsets
      ..sort((a, b) => b.startOffset.compareTo(a.startOffset));
    return changes.fold(
      source,
      (src, chg) =>
          src.substring(0, chg.startOffset) +
          chg.newContent +
          src.substring(chg.endOffset),
    );
  }

  SourceCodeChange _generateMemberChange(
    ClassEntity ce,
    List<Field> newFields,
    String src,
  ) {
    final insertion = _determineInsertionPoint(ce, src);
    final updatedClass = ce.copyWith(fields: [...ce.fields, ...newFields]);

    final fieldsBlock =
        newFields.map((f) => '  final ${f.type} ${f.name};').join('\n');
    final constructor =
        constructorGenerator.generate(updatedClass, src)?.newContent ?? '';

    return SourceCodeChange(
      startOffset: insertion.start,
      endOffset: insertion.end,
      newContent: '$constructor\n$fieldsBlock',
    );
  }

  _InsertionPoint _determineInsertionPoint(ClassEntity ce, String src) {
    // Look for default unnamed constructor
    final defaultConstructor =
        ce.constructors.cast<ConstructorEntity?>().firstWhere(
              (c) => c?.name == null,
              orElse: () => null,
            );

    if (defaultConstructor != null) {
      return _InsertionPoint(defaultConstructor.offset, defaultConstructor.end);
    }

    // Fallback: after fields or after opening brace
    final offset = ce.fields.isNotEmpty
        ? ce.fields.last.end
        : src.indexOf('{', ce.offset) + 1;

    return _InsertionPoint(offset, offset);
  }

  String _buildUseCaseContent(String name, String body) => '''
class $name {
  $name();

  Future<void> execute() async $body
}
''';

  String _getRelativeToLib(String path) {
    final match = RegExp(r'[/\\]lib[/\\](.*)').firstMatch(path);
    return match != null ? p.dirname(match.group(1)!) : '';
  }
}

/// Helper to carry shared context through the generation process
class _GenerationContext {
  _GenerationContext({
    required this.packageName,
    required this.relativeToLib,
    required this.sourceCode,
  });

  final String packageName;
  final String relativeToLib;
  final String sourceCode;
}

/// Holds data extracted from class methods before applying changes
class _ExtractionResult {
  _ExtractionResult(this.newFiles, this.newUseCaseFields, this.methodChanges);

  final List<GeneratedUseCaseFile> newFiles;
  final List<Field> newUseCaseFields;
  final List<SourceCodeChange> methodChanges;
}

/// Defines where to inject or replace code in the source
class _InsertionPoint {
  _InsertionPoint(this.start, this.end);
  final int start;
  final int end;
}

/// Input data for generation request
class GenerateUseCasesFromMethodsRequest {
  const GenerateUseCasesFromMethodsRequest({
    required this.className,
    required this.filePath,
    required this.sourceCode,
    required this.methodTypes,
  });

  final String className;
  final String filePath;
  final String sourceCode;
  final List<MethodType> methodTypes;
}

/// Output data for generation result
class GenerateUseCasesFromMethodsResult {
  const GenerateUseCasesFromMethodsResult({
    required this.isSuccess,
    this.updatedSourceCode,
    this.updatedClasses = const [],
    this.methodsByClass = const {},
    this.errorMessage,
  });

  factory GenerateUseCasesFromMethodsResult.success({
    required String updatedSourceCode,
    List<String> updatedClasses = const [],
    Map<String, List<String>> methodsByClass = const {},
  }) {
    return GenerateUseCasesFromMethodsResult(
      isSuccess: true,
      updatedSourceCode: updatedSourceCode,
      updatedClasses: updatedClasses,
      methodsByClass: methodsByClass,
    );
  }

  factory GenerateUseCasesFromMethodsResult.failure(String errorMessage) {
    return GenerateUseCasesFromMethodsResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  final bool isSuccess;
  final String? updatedSourceCode;
  final List<String> updatedClasses;
  final Map<String, List<String>> methodsByClass;
  final String? errorMessage;

  bool get wasUpdated => updatedClasses.isNotEmpty;
}
