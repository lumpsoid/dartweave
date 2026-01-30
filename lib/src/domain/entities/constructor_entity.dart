import 'package:dartweave/src/domain/entities/parameter_entity.dart';
import 'package:meta/meta.dart';

@immutable
class ConstructorEntity {
  const ConstructorEntity({
    required this.offset,
    required this.end,
    this.name,
    this.parameters = const [],
    this.isConst = false,
    this.isFactory = false,
    this.isRedirected = false,
  });
  const ConstructorEntity.empty()
      : name = null,
        parameters = const <ParameterEntity>[],
        isConst = false,
        isFactory = false,
        isRedirected = false,
        offset = 0,
        end = 0;

  final String? name;
  final List<ParameterEntity> parameters;
  final bool isConst;
  final bool isFactory;
  final bool isRedirected;
  final int offset;
  final int end;

  ConstructorEntity copyWith({
    String? name,
    List<ParameterEntity>? parameters,
    bool? isConst,
    bool? isFactory,
    bool? isRedirected,
    int? offset,
    int? end,
  }) {
    return ConstructorEntity(
      name: name ?? this.name,
      parameters: parameters ?? this.parameters,
      isConst: isConst ?? this.isConst,
      isFactory: isFactory ?? this.isFactory,
      isRedirected: isRedirected ?? this.isRedirected,
      offset: offset ?? this.offset,
      end: end ?? this.end,
    );
  }

  @override
  String toString() {
    return 'ConstructorEntity('
        ' name: $name,'
        ' parameters: $parameters,'
        ' isConst: $isConst,'
        ' isFactory: $isFactory,'
        ' isRedirected: $isRedirected,'
        ' offset: $offset,'
        ' end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return other is ConstructorEntity &&
        other.name == name &&
        other.parameters == parameters &&
        other.isConst == isConst &&
        other.isFactory == isFactory &&
        other.isRedirected == isRedirected &&
        other.offset == offset &&
        other.end == end;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      parameters,
      isConst,
      isFactory,
      isRedirected,
      offset,
      end,
    );
  }
}
