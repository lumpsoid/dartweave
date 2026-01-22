import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:dartweave/src/domain/entities/constructor_entity.dart';
import 'package:dartweave/src/domain/entities/entities.dart';
import 'package:dartweave/src/domain/entities/method_entity.dart';
import 'package:dartweave/src/domain/entities/operator_entity.dart';
import 'package:dartweave/src/domain/entities/parameter_entity.dart';
import 'package:dartweave/src/domain/entities/property_entity.dart';
import 'package:dartweave/src/domain/repositories/class_parser_repository.dart';

/// AST-based implementation of ClassParserRepository
class AstClassParserRepository implements ClassParserRepository {
  @override
  List<ClassEntity> parseClasses(String sourceCode, String filePath) {
    return _parseClassesInternal(
      sourceCode,
      filePath,
      withSuperclassParsing: true,
    );
  }

  /// Internal helper to parse classes, with an option to handle superclass
  /// entities
  List<ClassEntity> _parseClassesInternal(
    String sourceCode,
    String filePath, {
    required bool withSuperclassParsing,
  }) {
    final parseResult = parseString(
      content: sourceCode,
      featureSet: FeatureSet.latestLanguageVersion(),
      path: filePath,
    );

    if (parseResult.errors.isNotEmpty) {
      throw FormatException('Parse errors: ${parseResult.errors.join(', ')}');
    }

    final visitor = ClassExtractionVisitor();
    parseResult.unit.visitChildren(visitor);

    if (withSuperclassParsing) {
      _resolveSuperclassEntities(visitor.classes, sourceCode);
    }

    return visitor.classes;
  }

  /// Resolves the superclass entities for the parsed classes.
  void _resolveSuperclassEntities(
    List<ClassEntity> classes,
    String sourceCode,
  ) {
    final classesMap = <String, ClassEntity>{};
    for (final cls in classes) {
      classesMap[cls.name] = cls;
    }

    for (final cls in classes) {
      if (cls.superclassEntity != null &&
          classesMap.containsKey(cls.superclassEntity!.name)) {
        // This is a bit of a hack: ClassEntity's superclassEntity is final,
        // so we need to create a new one. In a real scenario, you might
        // design ClassEntity to be mutable or use a builder pattern.
        final resolvedSuperclass = classesMap[cls.superclassEntity?.name];
        final newFields = cls.fields
            .map(
              (f) => Field(
                name: f.name,
                type: f.type,
                nullable: f.nullable,
                isSuper: f.isSuper,
                isConst: f.isConst,
                isFinal: f.isFinal,
                isLate: f.isLate,
                isStatic: f.isStatic,
              ),
            )
            .toList();

        final newMethods = cls.methods
            .map(
              (m) => MethodEntity(
                name: m.name,
                returnType: m.returnType,
                isAbstract: m.isAbstract,
                isAsync: m.isAsync,
                isGenerator: m.isGenerator,
                isStatic: m.isStatic,
                parameters: m.parameters,
              ),
            )
            .toList();

        final newConstructors = cls.constructors
            .map(
              (c) => ConstructorEntity(
                name: c.name,
                isConst: c.isConst,
                isFactory: c.isFactory,
                isRedirected: c.isRedirected,
                parameters: c.parameters,
              ),
            )
            .toList();

        final newGetters = cls.getters
            .map(
              (g) => PropertyEntity(
                name: g.name,
                type: g.type,
                nullable: g.nullable,
                isAbstract: g.isAbstract,
                isStatic: g.isStatic,
                hasSetter: g.hasSetter,
                isSuper: g.isSuper,
                parameters: g.parameters,
              ),
            )
            .toList();

        final newSetters = cls.setters
            .map(
              (s) => PropertyEntity(
                name: s.name,
                type: s.type,
                nullable: s.nullable,
                isAbstract: s.isAbstract,
                isStatic: s.isStatic,
                hasSetter: s.hasSetter,
                isSuper: s.isSuper,
                parameters: s.parameters,
              ),
            )
            .toList();

        final newOperators = cls.operators
            .map(
              (o) => OperatorEntity(
                name: o.name,
                returnType: o.returnType,
                isAbstract: o.isAbstract,
                parameters: o.parameters,
              ),
            )
            .toList();

        final updatedClass = ClassEntity(
          offset: cls.offset,
          end: cls.end,
          name: cls.name,
          isAbstract: cls.isAbstract,
          superclassEntity: resolvedSuperclass,
          // We keep superclassName here for consistency, though it's
          // now redundant if superclassEntity is present.
          // In a real scenario, you might remove superclassName in ClassEntity.
          fields: newFields,
          methods: newMethods,
          constructors: newConstructors,
          getters: newGetters,
          setters: newSetters,
          operators: newOperators,
        );

        // Update the list with the new ClassEntity instance
        final index = classes.indexOf(cls);
        if (index != -1) {
          classes[index] = updatedClass;
        }
      }
    }
  }

  @override
  List<Field> getSuperclassFields(ClassEntity classEntity, String sourceCode) {
    if (classEntity.superclassEntity == null) {
      return [];
    }

    // If superclass is already resolved, return its fields
    if (classEntity.superclassEntity != null) {
      return classEntity.superclassEntity!.allFields
          .map(
            (f) => Field(
              name: f.name,
              type: f.type,
              nullable: f.nullable,
              isSuper: true,
              isConst: f.isConst,
              isFinal: f.isFinal,
              isLate: f.isLate,
              isStatic: f.isStatic,
            ),
          )
          .toList();
    }

    // Fallback: parse all classes in the source again to find the superclass
    final classes = _parseClassesInternal(
      sourceCode,
      '',
      withSuperclassParsing: true,
    ); // Parse with superclass resolution
    final superclass = classes.firstWhere(
      (c) => c.name == classEntity.superclassEntity?.name,
      orElse: () => throw StateError(
        'Superclass ${classEntity.superclassEntity?.name} not found',
      ),
    );

    return superclass.allFields
        .map(
          (f) => Field(
            name: f.name,
            type: f.type,
            nullable: f.nullable,
            isSuper: true,
            isConst: f.isConst,
            isFinal: f.isFinal,
            isLate: f.isLate,
            isStatic: f.isStatic,
          ),
        )
        .toList();
  }
}

/// AST visitor for extracting class information
class ClassExtractionVisitor extends GeneralizingAstVisitor<void> {
  final List<ClassEntity> classes = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final fields = _extractFields(node);
    final methods = _extractMethods(node);
    final constructors = _extractConstructors(node);
    final getters = _extractGetters(node);
    final setters = _extractSetters(node);
    final operators = _extractOperators(node);

    final superclassName = node.extendsClause?.superclass.toString();
    final isAbstract = node.abstractKeyword != null;
    classes.add(
      ClassEntity(
        offset: node.offset,
        end: node.end,
        name: node.name.lexeme,
        isAbstract: isAbstract,
        // Will be resolved later
        superclassEntity: superclassName == null
            ? null
            : superclassName.isEmpty
                ? null
                : ClassEntity(
                    name: superclassName,
                    offset: 0,
                    end: 0,
                  ),
        fields: fields,
        methods: methods,
        constructors: constructors,
        getters: getters,
        setters: setters,
        operators: operators,
      ),
    );

    super.visitClassDeclaration(node);
  }

  List<Field> _extractFields(ClassDeclaration node) {
    final fields = <Field>[];
    final visitor = FieldDeclarationVisitor();
    node.visitChildren(visitor);

    for (final fieldDecl in visitor.fields) {
      if (fieldDecl.isStatic) {
        // We might want to include static fields as well,
        // but for now, based on the original logic, we skip them here.
        // If needed, modify Field entity to have an `isStatic` property.
      }

      for (final variable in fieldDecl.fields.variables) {
        final name = variable.name.lexeme;

        final typeNode = fieldDecl.fields.type;
        final typeStr = typeNode?.toString() ?? 'dynamic';
        final isNullable = typeNode?.question != null;

        fields.add(
          Field(
            name: name,
            type:
                isNullable ? typeStr.substring(0, typeStr.length - 1) : typeStr,
            nullable: isNullable,
            isConst: variable.isConst,
            isFinal: variable.isFinal,
            isLate: variable.isLate,
            isStatic: fieldDecl.isStatic,
          ),
        );
      }
    }

    return fields;
  }

  List<MethodEntity> _extractMethods(ClassDeclaration node) {
    final methods = <MethodEntity>[];
    for (final member in node.members) {
      if (member is MethodDeclaration &&
          !member.isGetter &&
          !member.isSetter &&
          !member.isOperator) {
        methods.add(
          MethodEntity(
            name: member.name.lexeme,
            returnType: member.returnType?.toString() ?? 'void',
            isStatic: member.isStatic,
            isAbstract: member.body is EmptyFunctionBody,
            isAsync: member.body.isAsynchronous,
            isGenerator: member.body.isGenerator,
            parameters: _extractParameters(member.parameters),
          ),
        );
      }
    }
    return methods;
  }

  List<ConstructorEntity> _extractConstructors(ClassDeclaration node) {
    final constructors = <ConstructorEntity>[];
    for (final member in node.members) {
      if (member is ConstructorDeclaration) {
        constructors.add(
          ConstructorEntity(
            name: member.name?.lexeme,
            isConst: member.constKeyword != null,
            isFactory: member.factoryKeyword != null,
            isRedirected: member.redirectedConstructor != null,
            parameters: _extractParameters(member.parameters),
          ),
        );
      }
    }
    return constructors;
  }

  List<PropertyEntity> _extractGetters(ClassDeclaration node) {
    final getters = <PropertyEntity>[];
    for (final member in node.members) {
      if (member is MethodDeclaration && member.isGetter) {
        // Check if there's a corresponding setter
        final hasSetter = node.members.any(
          (m) =>
              m is MethodDeclaration &&
              m.isSetter &&
              m.name.lexeme == member.name.lexeme,
        );

        getters.add(
          PropertyEntity(
            name: member.name.lexeme,
            type: member.returnType?.toString() ?? 'dynamic',
            nullable: _isTypeNullable(member.returnType),
            isStatic: member.isStatic,
            isAbstract: member.body is EmptyFunctionBody,
            hasSetter: hasSetter,
          ),
        );
      }
    }
    return getters;
  }

  List<PropertyEntity> _extractSetters(ClassDeclaration node) {
    final setters = <PropertyEntity>[];
    for (final member in node.members) {
      if (member is MethodDeclaration && member.isSetter) {
        setters.add(
          PropertyEntity(
            name: member.name.lexeme,
            type: member
                    .typeParameters?.typeParameters.firstOrNull?.name.lexeme ??
                'dynamic',
            isStatic: member.isStatic,
            isAbstract: member.body is EmptyFunctionBody,
            // Setters inherently "have a setter" in a sense, but hasSetter
            // is for getters to indicate a read-write property.
            hasSetter: true,
            parameters: _extractParameters(member.parameters),
          ),
        );
      }
    }
    return setters;
  }

  List<OperatorEntity> _extractOperators(ClassDeclaration node) {
    final operators = <OperatorEntity>[];
    for (final member in node.members) {
      if (member is MethodDeclaration && member.isOperator) {
        operators.add(
          OperatorEntity(
            name: member.name.lexeme,
            returnType: member.returnType?.toString() ?? 'dynamic',
            isAbstract: member.body is EmptyFunctionBody,
            parameters: _extractParameters(member.parameters),
          ),
        );
      }
    }
    return operators;
  }

  List<ParameterEntity> _extractParameters(FormalParameterList? paramList) {
    if (paramList == null) return [];
    final parameters = <ParameterEntity>[];
    for (final param in paramList.parameters) {
      final paramString = param.toString();
      final typeAnnotation =
          param.isExplicitlyTyped ? paramString.split(' ').firstOrNull : null;
      final nullable = typeAnnotation?.endsWith('?') ?? false;

      parameters.add(
        ParameterEntity(
          name: param.name?.lexeme ?? '',
          type: typeAnnotation,
          isNamed: param.isNamed,
          isRequired: param.isRequired,
          isOptional: param.isOptional,
          isPositional: param.isPositional,
          nullable: nullable,
          defaultValue:
              (param is DefaultFormalParameter && param.defaultValue != null)
                  ? param.defaultValue.toString()
                  : null,
        ),
      );
    }
    return parameters;
  }

  bool _isTypeNullable(TypeAnnotation? typeNode) {
    if (typeNode == null) return false;
    return typeNode.type?.nullabilitySuffix == NullabilitySuffix.question;
  }
}

// Keeping these visitors if they are used elsewhere directly,
// but ClassExtractionVisitor now incorporates their logic.
// If not used directly, they can be removed.
// For example, FieldDeclarationVisitor is used inside _extractFields.

/// Visitor to collect field declarations
class FieldDeclarationVisitor extends GeneralizingAstVisitor<void> {
  final List<FieldDeclaration> fields = [];
  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    fields.add(node);
    super.visitFieldDeclaration(node);
  }
}

// These are now potentially redundant as ClassExtractionVisitor does the work
// If you need to search for specific elements outside of class extraction, keep them.
// Otherwise, they might be removed for a leaner codebase.
class ImportVisitor extends GeneralizingAstVisitor<void> {
  final List<ImportDirective> imports = [];

  @override
  void visitImportDirective(ImportDirective node) {
    imports.add(node);
    super.visitImportDirective(node);
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

class OperatorDeclarationVisitor extends GeneralizingAstVisitor<void> {
  OperatorDeclarationVisitor(this.operatorName);
  final String operatorName;
  final List<MethodDeclaration> operators = [];

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isOperator && node.name.lexeme == operatorName) {
      operators.add(node);
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
