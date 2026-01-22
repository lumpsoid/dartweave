import 'package:dartweave/src/domain/entities/parameter_entity.dart';
import 'package:equatable/equatable.dart';

class MethodEntity extends Equatable {
  const MethodEntity({
    required this.name,
    required this.returnType,
    this.parameters = const [],
    this.isStatic = false,
    this.isAbstract = false,
    this.isAsync = false,
    this.isGenerator = false,
  });

  final String name;
  final String returnType;
  final List<ParameterEntity> parameters;
  final bool isStatic;
  final bool isAbstract;
  final bool isAsync;
  final bool isGenerator;

  @override
  List<Object?> get props => [
        name,
        returnType,
        parameters,
        isStatic,
        isAbstract,
        isAsync,
        isGenerator,
      ];

  @override
  String toString() {
    return 'MethodEntity('
        ' name: $name,'
        ' returnType: $returnType,'
        ' parameters: $parameters,'
        ' isStatic: $isStatic,'
        ' isAbstract: $isAbstract,'
        ' isAsync: $isAsync,'
        ' isGenerator: $isGenerator)';
  }
}
