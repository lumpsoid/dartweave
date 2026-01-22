import 'package:dartweave/src/domain/entities/parameter_entity.dart';
import 'package:equatable/equatable.dart';

class PropertyEntity extends Equatable {
  const PropertyEntity({
    required this.name,
    required this.type,
    this.nullable = false,
    this.isStatic = false,
    this.isAbstract = false,
    this.hasSetter = false,
    this.isSuper = false,
    this.parameters = const [], // Setters may have a parameter
  });

  final String name;
  final String type;
  final bool nullable;
  final bool isStatic;
  final bool isAbstract;
  final bool hasSetter; // Only applicable for getters (read-write properties)
  final bool isSuper; // Indicates if it's inherited from a superclass
  final List<ParameterEntity> parameters; // Parameters for setters

  @override
  List<Object?> get props => [
        name,
        type,
        nullable,
        isStatic,
        isAbstract,
        hasSetter,
        isSuper,
        parameters,
      ];

  @override
  String toString() {
    return 'PropertyEntity('
        ' name: $name,'
        ' type: $type,'
        ' nullable: $nullable,'
        ' isStatic: $isStatic,'
        ' isAbstract: $isAbstract,'
        ' hasSetter: $hasSetter,'
        ' isSuper: $isSuper,'
        ' parameters: $parameters)';
  }
}
