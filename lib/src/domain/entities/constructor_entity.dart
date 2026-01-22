import 'package:dartweave/src/domain/entities/parameter_entity.dart';
import 'package:equatable/equatable.dart';

class ConstructorEntity extends Equatable {
  const ConstructorEntity({
    this.name, // null for default constructor
    this.parameters = const [],
    this.isConst = false,
    this.isFactory = false,
    this.isRedirected = false,
  });

  final String? name;
  final List<ParameterEntity> parameters;
  final bool isConst;
  final bool isFactory;
  final bool isRedirected;

  @override
  List<Object?> get props =>
      [name, parameters, isConst, isFactory, isRedirected];

  @override
  String toString() {
    return 'ConstructorEntity('
        ' name: $name,'
        ' parameters: $parameters,'
        ' isConst: $isConst,'
        ' isFactory: $isFactory,'
        ' isRedirected: $isRedirected)';
  }
}
