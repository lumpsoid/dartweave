enum ParamType {
  thisField, // this.field
  superField, // super.field
  formal, // String field (standard formal parameter)
}

class ConstructorParam {
  ConstructorParam({
    required this.name,
    required this.type,
    this.isRequired = true,
    this.isNamed = true,
    this.defaultValue,
    this.typeName,
  });
  final String name;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;
  final ParamType type;
  final String? typeName;
}

class ConstructorInfo {
  ConstructorInfo({
    required this.params,
    this.isConst = false,
  }) : paramNames = params.map((p) => p.name).toSet();
  final Set<String> paramNames;
  final List<ConstructorParam> params;
  final bool isConst;
}
