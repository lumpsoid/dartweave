import 'package:equatable/equatable.dart';

class ParameterEntity extends Equatable {
  const ParameterEntity({
    required this.name,
    required this.type,
    this.isNamed = false,
    this.isRequired = false,
    this.isOptional = false, // Positional optional
    this.defaultValue,
    this.isPositional = false,
    this.nullable = false,
  });

  final String name;
  final String? type;
  final bool isNamed;
  final bool isRequired;
  final bool isOptional;
  final String? defaultValue;
  final bool isPositional;
  final bool nullable;

  @override
  List<Object?> get props => [
        name,
        type,
        isNamed,
        isRequired,
        isOptional,
        defaultValue,
        isPositional,
        nullable,
      ];

  @override
  String toString() {
    return 'ParameterEntity('
        ' name: $name,'
        ' type: $type,'
        ' isNamed: $isNamed,'
        ' isRequired: $isRequired,'
        ' isOptional: $isOptional,'
        ' defaultValue: $defaultValue,'
        ' isPositional: $isPositional,'
        ' nullable: $nullable)';
  }
}
