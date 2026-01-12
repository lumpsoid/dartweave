import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_create_class/src/models/models.dart';

ConstructorInfo parseConstructor(ConstructorDeclaration node) {
  final params = <ConstructorParam>[];

  for (final p in node.parameters.parameters) {
    final normalParam = p is DefaultFormalParameter ? p.parameter : p;
    final name = normalParam.name?.lexeme;
    if (name == null) continue;

    var pType = ParamType.formal;
    String? typeName;

    if (normalParam is FieldFormalParameter) {
      pType = ParamType.thisField;
    } else if (normalParam is SuperFormalParameter) {
      pType = ParamType.superField;
    } else if (normalParam is SimpleFormalParameter) {
      pType = ParamType.formal;
      typeName = normalParam.type?.toString();
    }

    params.add(
      ConstructorParam(
        name: name,
        type: pType,
        typeName: typeName,
        isRequired: p.isRequired,
        isNamed: p.isNamed,
        defaultValue:
            (p is DefaultFormalParameter) ? p.defaultValue?.toString() : null,
      ),
    );
  }

  return ConstructorInfo(
    params: params,
    isConst: node.constKeyword != null,
  );
}
