import 'package:equatable/equatable.dart';

/// Domain entity representing a class field
class Field extends Equatable {
  const Field({
    required this.name,
    required this.type,
    this.nullable = false,
    this.isSuper = false,
    this.isFinal = false,
    this.isConst = false,
    this.isStatic = false,
    this.isLate = false,
  });

  final String name;
  final String type;
  final bool nullable;
  final bool isSuper;
  final bool isFinal;
  final bool isConst;
  final bool isStatic;
  final bool isLate;

  @override
  List<Object?> get props => [
        name,
        type,
        nullable,
        isSuper,
        isFinal,
        isConst,
        isStatic,
        isLate,
      ];

  /// Factory method to create a Field from definition string
  static Field fromDefinition(String definition) {
    final parts = definition.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid field definition: $definition');
    }

    final name = parts[0];
    var type = parts[1];
    final nullable = type.endsWith('?');

    if (nullable) {
      type = type.substring(0, type.length - 1);
    }

    return Field(name: name, type: type, nullable: nullable);
  }

  @override
  String toString() {
    return 'Field('
        ' name: $name,'
        ' type: $type,'
        ' nullable: $nullable,'
        ' isSuper: $isSuper,'
        ' isFinal: $isFinal,'
        ' isConst: $isConst,'
        ' isStatic: $isStatic,'
        ' isLate: $isLate)';
  }
}
