/// Enum representing supported method types
enum MethodType {
  emptyConstructor('empty'),
  defaultConstructor('new'),
  copyWithMethod('copyWith'),
  copyWithNullableMethod('copyWithNullable'),
  toStringMethod('toString'),
  hashCodeMethod('hashCode'),
  equalityOperator('equality'),
  isEmptyGetter('isEmpty'),
  fromJsonMethod('fromJson');

  const MethodType(this.name);

  final String name;

  static MethodType fromName(String name) {
    return MethodType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => throw ArgumentError('Unknown method type: $name'),
    );
  }

  @override
  String toString() {
    return name;
  }
}
