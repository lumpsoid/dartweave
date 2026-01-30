import 'package:dartweave/src/domain/entities/parameter_entity.dart';
import 'package:meta/meta.dart';

@immutable
class OperatorEntity {
  const OperatorEntity({
    required this.name,
    required this.returnType,
    required this.offset,
    required this.end,
    this.parameters = const [],
    this.isAbstract = false,
  });
  const OperatorEntity.empty()
      : name = '',
        returnType = '',
        parameters = const <ParameterEntity>[],
        isAbstract = false,
        offset = 0,
        end = 0;

  final String name; // e.g., '+', '[]', '=='
  final String returnType;
  final List<ParameterEntity> parameters;
  final bool isAbstract;
  final int offset;
  final int end;

  @override
  String toString() {
    return 'OperatorEntity('
        ' name: $name,'
        ' returnType: $returnType,'
        ' parameters: $parameters,'
        ' isAbstract: $isAbstract,'
        ' offset: $offset,'
        ' end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return other is OperatorEntity &&
        other.name == name &&
        other.returnType == returnType &&
        other.parameters == parameters &&
        other.isAbstract == isAbstract &&
        other.offset == offset &&
        other.end == end;
  }

  @override
  int get hashCode {
    return Object.hash(name, returnType, parameters, isAbstract, offset, end);
  }

  OperatorEntity copyWith({
    String? name,
    String? returnType,
    List<ParameterEntity>? parameters,
    bool? isAbstract,
    int? offset,
    int? end,
  }) {
    return OperatorEntity(
      name: name ?? this.name,
      returnType: returnType ?? this.returnType,
      parameters: parameters ?? this.parameters,
      isAbstract: isAbstract ?? this.isAbstract,
      offset: offset ?? this.offset,
      end: end ?? this.end,
    );
  }
}
