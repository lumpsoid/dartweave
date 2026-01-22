import 'package:dartweave/src/domain/entities/parameter_entity.dart';
import 'package:equatable/equatable.dart';

class OperatorEntity extends Equatable {
  const OperatorEntity({
    required this.name,
    required this.returnType,
    this.parameters = const [],
    this.isAbstract = false,
  });

  final String name; // e.g., '+', '[]', '=='
  final String returnType;
  final List<ParameterEntity> parameters;
  final bool isAbstract;

  @override
  List<Object?> get props => [name, returnType, parameters, isAbstract];

  @override
  String toString() {
    return 'OperatorEntity('
        ' name: $name,'
        ' returnType: $returnType,'
        ' parameters: $parameters,'
        ' isAbstract: $isAbstract)';
  }
}
