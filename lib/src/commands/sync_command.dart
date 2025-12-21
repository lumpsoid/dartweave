import 'dart:io';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:args/command_runner.dart';
import 'package:dart_create_class/src/generators/generators.dart';
import 'package:dart_create_class/src/models/models.dart' show Field;
import 'package:dart_create_class/src/utils.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template sync_command}
/// `dart_create_class sync <class_name> [options]`
/// A [Command] to sync methods of a Dart class
/// {@endtemplate}
class GenCommand extends Command<int> {
  /// {@macro sync_command}
  GenCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'file',
        abbr: 'f',
        help: 'Path to the file containing the class(es).'
            ' Default to class_name.dart',
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
        allowed: ['copyWith', 'toString'],
      )
      ..addMultiOption(
        'getter',
        abbr: 'g',
        help: 'Getters to sync (isEmpty)',
        allowed: ['isEmpty'],
      );
  }

  @override
  String get description => 'Gen code of a Dart class with defiend fields';

  @override
  String get name => 'gen';

  @override
  String get invocation => '${runner?.executableName} $name'
      ' <class_name> [options]';

  final Logger _logger;

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      _logger.err('Class name is required');
      printUsage();
      return ExitCode.usage.code;
    }

    final className = argResults!.rest[0];

    // Get methods from different categories of flags
    final constructors = argResults?['constructor'] as List<String>? ?? [];
    final methods = argResults?['method'] as List<String>? ?? [];
    final getters = argResults?['getter'] as List<String>? ?? [];

    // Combine all requested methods
    final methodsToSync = [...constructors, ...methods, ...getters];

    // If no methods specified, use defaults
    if (methodsToSync.isEmpty) {
      _logger.info('No methods specified for sync');
      return ExitCode.usage.code;
    }

    // Get file path or use default based on class name
    final filePath =
        argResults?['file'] as String? ?? '${className.toSnakeCase()}.dart';
    final updateAllClasses = argResults?['all-classes'] as bool? ?? false;

    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        _logger.err('File not found: $filePath');
        return ExitCode.usage.code;
      }

      _logger.info(
        lightGreen.wrap(
          'Syncing methods for'
          ' ${updateAllClasses ? 'all classes' : className} in $filePath',
        ),
      );
      for (final method in methodsToSync) {
        _logger.info(lightGreen.wrap('  - $method'));
      }

      final content = file.readAsStringSync();
      final generatingProgress = _logger.progress(
        'Writing updated content to file',
      );
      final result = _syncClassMethods(
        className: className,
        filePath: filePath,
        content: content,
        methodsToSync: methodsToSync,
        updateAllClasses: updateAllClasses,
      );

      if (result.updated) {
        generatingProgress.complete('Methods regenerated successfully');
        final progress = _logger.progress('Writing updated content to file');
        file.writeAsStringSync(result.content);
        progress.complete('File updated successfully');

        for (final entry in result.updatedMethods.entries) {
          final classInfo = entry.key;
          final methods = entry.value;
          _logger.success(
            'For class $classInfo: updated methods ${methods.join(", ")}',
          );
        }
        return ExitCode.success.code;
      } else {
        generatingProgress.complete('No changes were made to the file');
        if (result.errors.isNotEmpty) {
          result.errors.forEach(_logger.err);
          return ExitCode.software.code;
        }
        return ExitCode.success.code;
      }
    } catch (e, stackTrace) {
      _logger
        ..err('Error syncing methods: $e')
        ..detail('$stackTrace');
      return ExitCode.software.code;
    }
  }

  /// Updates selected methods in the given file content
  SyncUpdateResult _syncClassMethods({
    required String className,
    required String filePath,
    required String content,
    required List<String> methodsToSync,
    required bool updateAllClasses,
  }) {
    // Parse the file
    final parseResult = parseString(
      content: content,
      featureSet: FeatureSet.latestLanguageVersion(),
      path: filePath,
    );
    if (parseResult.errors.isNotEmpty) {
      return SyncUpdateResult(
        content: content,
        updated: false,
        errors: ['Error parsing file: ${parseResult.errors.join('\n')}'],
      );
    }
    final unit = parseResult.unit;

    // Visit all classes in the file
    final classVisitor = ClassDeclarationVisitor();
    unit.visitChildren(classVisitor);
    if (classVisitor.classes.isEmpty) {
      return SyncUpdateResult(
        content: content,
        updated: false,
        errors: ['No classes found in the file'],
      );
    }

    // Track all changes we need to make
    final changes = <FileChange>[];
    final updatedMethods = <String, List<String>>{};
    final errors = <String>[];

    for (final classDecl in classVisitor.classes) {
      final currentClassName = classDecl.name.lexeme;
      // Skip if not the targeted class and not updating all
      if (!updateAllClasses && currentClassName != className) {
        continue;
      }

      // Extract fields for this class
      final fieldVisitor = FieldDeclarationVisitor();
      classDecl.visitChildren(fieldVisitor);
      final fields = <Field>[];
      for (final fieldDecl in fieldVisitor.fields) {
        // Skip static fields
        if (fieldDecl.isStatic) continue;
        for (final variable in fieldDecl.fields.variables) {
          final name = variable.name.lexeme;
          final typeNode = fieldDecl.fields.type;
          final typeStr = typeNode?.toString() ?? 'dynamic';
          // Check if field type is nullable
          final isNullable = typeNode?.question != null;
          fields.add(
            Field(
              name: name,
              type: isNullable
                  ? typeStr.substring(0, typeStr.length - 1)
                  : typeStr,
              nullable: isNullable,
            ),
          );
        }
      }
      if (fields.isEmpty) {
        errors.add('No fields found in class $currentClassName');
        continue;
      }

      final updatedMethodsForClass = <String>[];

      final methodGen =
          MethodGenerator(className: currentClassName, fields: fields);
      // Process each requested method
      for (final methodName in methodsToSync) {
        methodGen.clear();

        switch (methodName) {
          case 'equality':
            // Find existing getter
            final getterVisitor = GetterDeclarationVisitor('==');
            classDecl.visitChildren(getterVisitor);

            // Generate new getter
            methodGen.generateEqualityOperator();

            if (getterVisitor.getters.isNotEmpty) {
              // Replace existing getter
              final existingGetter = getterVisitor.getters.first;
              changes.add(
                FileChange(
                  start: existingGetter.offset,
                  end: existingGetter.end,
                  replacement: methodGen.toString(),
                ),
              );
            } else {
              // Add new getter at end of class
              changes.add(
                FileChange(
                  start: classDecl.end - 1,
                  end: classDecl.end - 1,
                  replacement: '\n\n  $methodGen\n',
                ),
              );
            }
            updatedMethodsForClass.add('equality operator');

          case 'hashCode':
            // Find existing getter
            final getterVisitor = GetterDeclarationVisitor('hashCode');
            classDecl.visitChildren(getterVisitor);

            // Generate new getter
            methodGen.generateHashCode();

            if (getterVisitor.getters.isNotEmpty) {
              // Replace existing getter
              final existingGetter = getterVisitor.getters.first;
              changes.add(
                FileChange(
                  start: existingGetter.offset,
                  end: existingGetter.end,
                  replacement: methodGen.toString(),
                ),
              );
            } else {
              // Add new getter at end of class
              changes.add(
                FileChange(
                  start: classDecl.end - 1,
                  end: classDecl.end - 1,
                  replacement: '\n\n$methodGen\n',
                ),
              );
            }
            updatedMethodsForClass.add('hashCode getter');

          case 'toString':
            // Find existing method
            final methodVisitor = MethodDeclarationVisitor('toString');
            classDecl.visitChildren(methodVisitor);

            // Generate new method
            methodGen.generateToStringMethod();

            if (methodVisitor.methods.isNotEmpty) {
              // Replace existing method
              final existingMethod = methodVisitor.methods.first;
              changes.add(
                FileChange(
                  start: existingMethod.offset,
                  end: existingMethod.end,
                  replacement: methodGen.generatedCode,
                ),
              );
            } else {
              // Add new method at end of class
              changes.add(
                FileChange(
                  start: classDecl.end - 1, // Position before closing bracket
                  end: classDecl.end - 1,
                  replacement: '\n  $methodGen\n',
                ),
              );
            }
            updatedMethodsForClass.add('toString');

          case 'copyWith':
            // Find existing method
            final methodVisitor = MethodDeclarationVisitor('copyWith');
            classDecl.visitChildren(methodVisitor);

            // Generate new method
            methodGen.generateCopyWithMethod();

            if (methodVisitor.methods.isNotEmpty) {
              // Replace existing method
              final existingMethod = methodVisitor.methods.first;
              changes.add(
                FileChange(
                  start: existingMethod.offset,
                  end: existingMethod.end,
                  replacement: methodGen.toString(),
                ),
              );
            } else {
              // Add new method at end of class
              changes.add(
                FileChange(
                  start: classDecl.end - 1, // Position before closing bracket
                  end: classDecl.end - 1,
                  replacement: '\n\n$methodGen\n',
                ),
              );
            }
            updatedMethodsForClass.add('copyWith');

          case 'empty':
            // Find existing constructor
            final constructorVisitor = ConstructorDeclarationVisitor('empty');
            classDecl.visitChildren(constructorVisitor);

            // Generate new constructor
            methodGen.generateConstEmptyConstructor();

            if (constructorVisitor.constructors.isNotEmpty) {
              // Replace existing constructor
              final existingConstructor = constructorVisitor.constructors.first;
              changes.add(
                FileChange(
                  start: existingConstructor.offset,
                  end: existingConstructor.end,
                  replacement: methodGen.toString(),
                ),
              );
            } else {
              // Add new constructor after class header
              changes.add(
                FileChange(
                  start: classDecl.leftBracket.end,
                  end: classDecl.leftBracket.end,
                  replacement: '\n\n$methodGen\n',
                ),
              );
            }
            updatedMethodsForClass.add('empty constructor');

          case 'isEmpty':
            // Find existing getter
            final getterVisitor = GetterDeclarationVisitor('isEmpty');
            classDecl.visitChildren(getterVisitor);

            // Generate new getter
            methodGen.generateIsEmptyGetter();

            if (getterVisitor.getters.isNotEmpty) {
              // Replace existing getter
              final existingGetter = getterVisitor.getters.first;
              changes.add(
                FileChange(
                  start: existingGetter.offset,
                  end: existingGetter.end,
                  replacement: methodGen.toString(),
                ),
              );
            } else {
              // Add new getter at end of class
              changes.add(
                FileChange(
                  start: classDecl.end - 1,
                  end: classDecl.end - 1,
                  replacement: '\n\n  $methodGen\n',
                ),
              );
            }
            updatedMethodsForClass.add('isEmpty getter');

          case 'new':
            // Find existing default constructor
            final constructorVisitor = ConstructorDeclarationVisitor('');
            classDecl.visitChildren(constructorVisitor);

            // Generate new default constructor
            methodGen.generateNewConstructor();

            if (constructorVisitor.constructors.isNotEmpty) {
              // Replace existing constructor
              final existingConstructor = constructorVisitor.constructors.first;
              changes.add(
                FileChange(
                  start: existingConstructor.offset,
                  end: existingConstructor.end,
                  replacement: methodGen.toString(),
                ),
              );
            } else {
              // Add new constructor after class header
              changes.add(
                FileChange(
                  start: classDecl.leftBracket.end,
                  end: classDecl.leftBracket.end,
                  replacement: '\n  $methodGen\n',
                ),
              );
            }
            updatedMethodsForClass.add('default constructor');
        }
      }

      if (updatedMethodsForClass.isNotEmpty) {
        updatedMethods[currentClassName] = updatedMethodsForClass;
      }
    }

    // Sort changes from bottom to top (highest offset first)
    changes.sort((a, b) => b.start.compareTo(a.start));

    // Apply changes
    var modifiedContent = content;
    for (final change in changes) {
      modifiedContent = modifiedContent.substring(0, change.start) +
          change.replacement +
          modifiedContent.substring(change.end);
    }

    return SyncUpdateResult(
      content: modifiedContent,
      updated: changes.isNotEmpty,
      updatedMethods: updatedMethods,
      errors: errors,
    );
  }
}

/// Visitor to collect class declarations
class ClassDeclarationVisitor extends GeneralizingAstVisitor<void> {
  final List<ClassDeclaration> classes = [];
  @override
  void visitClassDeclaration(ClassDeclaration node) {
    classes.add(node);
    super.visitClassDeclaration(node);
  }
}

/// Visitor to collect field declarations
class FieldDeclarationVisitor extends GeneralizingAstVisitor<void> {
  final List<FieldDeclaration> fields = [];
  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    fields.add(node);
    super.visitFieldDeclaration(node);
  }
}

/// Visitor to find a specific method by name
class MethodDeclarationVisitor extends GeneralizingAstVisitor<void> {
  MethodDeclarationVisitor(this.methodName);
  final String methodName;
  final List<MethodDeclaration> methods = [];
  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == methodName) {
      methods.add(node);
    }
    super.visitMethodDeclaration(node);
  }
}

/// Visitor to find getters by name
class GetterDeclarationVisitor extends GeneralizingAstVisitor<void> {
  GetterDeclarationVisitor(this.getterName);
  final String getterName;
  final List<MethodDeclaration> getters = [];

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isGetter && node.name.lexeme == getterName) {
      getters.add(node);
    }
    super.visitMethodDeclaration(node);
  }
}

/// Visitor to find constructors by name
class ConstructorDeclarationVisitor extends GeneralizingAstVisitor<void> {
  ConstructorDeclarationVisitor(this.constructorName);
  final String constructorName;
  final List<ConstructorDeclaration> constructors = [];

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final name = node.name?.lexeme ?? '';
    if (name == constructorName) {
      constructors.add(node);
    }
    super.visitConstructorDeclaration(node);
  }
}

/// Result of updating class methods
class SyncUpdateResult {
  /// Creates a new [SyncUpdateResult] instance
  const SyncUpdateResult({
    required this.content,
    required this.updated,
    this.updatedMethods = const {},
    this.errors = const [],
  });

  /// The updated file content
  final String content;

  /// Whether the file was updated
  final bool updated;

  /// Map of class names to lists of updated methods
  final Map<String, List<String>> updatedMethods;

  /// List of errors encountered during update
  final List<String> errors;
}

/// Represents a change to be made to a file
class FileChange {
  const FileChange({
    required this.start,
    required this.end,
    required this.replacement,
  });

  final int start;
  final int end;
  final String replacement;
}
