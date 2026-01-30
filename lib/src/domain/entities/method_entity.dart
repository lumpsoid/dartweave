import 'package:dartweave/src/domain/entities/function_body.dart';
import 'package:dartweave/src/domain/entities/parameter_entity.dart';
import 'package:meta/meta.dart';

@immutable
class MethodEntity {
  const MethodEntity({
    required this.name,
    required this.returnType,
    required this.offset,
    required this.end,
    required this.body,
    this.parameters = const [],
    this.isStatic = false,
    this.isAbstract = false,
    this.isAsync = false,
    this.isGenerator = false,
  });

  const MethodEntity.empty()
      : name = '',
        returnType = '',
        parameters = const <ParameterEntity>[],
        isStatic = false,
        isAbstract = false,
        isAsync = false,
        isGenerator = false,
        offset = 0,
        end = 0,
        body = const FunctionBody.empty();

  final String name;
  final String returnType;
  final List<ParameterEntity> parameters;
  final bool isStatic;
  final bool isAbstract;
  final bool isAsync;
  final bool isGenerator;
  final int offset;
  final int end;
  final FunctionBody body;

  MethodEntity copyWith({
    String? name,
    String? returnType,
    List<ParameterEntity>? parameters,
    bool? isStatic,
    bool? isAbstract,
    bool? isAsync,
    bool? isGenerator,
    int? offset,
    int? end,
    FunctionBody? body,
  }) {
    return MethodEntity(
      name: name ?? this.name,
      returnType: returnType ?? this.returnType,
      parameters: parameters ?? this.parameters,
      isStatic: isStatic ?? this.isStatic,
      isAbstract: isAbstract ?? this.isAbstract,
      isAsync: isAsync ?? this.isAsync,
      isGenerator: isGenerator ?? this.isGenerator,
      offset: offset ?? this.offset,
      end: end ?? this.end,
      body: body ?? this.body,
    );
  }

  @override
  String toString() {
    return 'MethodEntity('
        ' name: $name,'
        ' returnType: $returnType,'
        ' parameters: $parameters,'
        ' isStatic: $isStatic,'
        ' isAbstract: $isAbstract,'
        ' isAsync: $isAsync,'
        ' isGenerator: $isGenerator,'
        ' offset: $offset,'
        ' end: $end,'
        ' body: $body)';
  }

  @override
  bool operator ==(Object other) {
    return other is MethodEntity &&
        other.name == name &&
        other.returnType == returnType &&
        other.parameters == parameters &&
        other.isStatic == isStatic &&
        other.isAbstract == isAbstract &&
        other.isAsync == isAsync &&
        other.isGenerator == isGenerator &&
        other.offset == offset &&
        other.end == end &&
        other.body == body;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      returnType,
      parameters,
      isStatic,
      isAbstract,
      isAsync,
      isGenerator,
      offset,
      end,
      body,
    );
  }
}
