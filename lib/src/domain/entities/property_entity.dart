import 'package:dartweave/src/domain/entities/parameter_entity.dart';
import 'package:meta/meta.dart';

@immutable
class PropertyEntity {
  const PropertyEntity({
    required this.name,
    required this.type,
    required this.offset,
    required this.end,
    this.nullable = false,
    this.isStatic = false,
    this.isAbstract = false,
    this.hasSetter = false,
    this.isSuper = false,
    this.parameters = const [],
  });
  const PropertyEntity.empty()
      : name = '',
        type = '',
        nullable = false,
        isStatic = false,
        isAbstract = false,
        hasSetter = false,
        isSuper = false,
        parameters = const <ParameterEntity>[],
        offset = 0,
        end = 0;

  final String name;
  final String type;
  final bool nullable;
  final bool isStatic;
  final bool isAbstract;
  final bool hasSetter; // Only applicable for getters (read-write properties)
  final bool isSuper; // Indicates if it's inherited from a superclass
  final List<ParameterEntity> parameters; // Parameters for setters
  final int offset;
  final int end;

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
        ' parameters: $parameters,'
        ' offset: $offset,'
        ' end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyEntity &&
        other.name == name &&
        other.type == type &&
        other.nullable == nullable &&
        other.isStatic == isStatic &&
        other.isAbstract == isAbstract &&
        other.hasSetter == hasSetter &&
        other.isSuper == isSuper &&
        other.parameters == parameters &&
        other.offset == offset &&
        other.end == end;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      type,
      nullable,
      isStatic,
      isAbstract,
      hasSetter,
      isSuper,
      parameters,
      offset,
      end,
    );
  }

  PropertyEntity copyWith({
    String? name,
    String? type,
    bool? nullable,
    bool? isStatic,
    bool? isAbstract,
    bool? hasSetter,
    bool? isSuper,
    List<ParameterEntity>? parameters,
    int? offset,
    int? end,
  }) {
    return PropertyEntity(
      name: name ?? this.name,
      type: type ?? this.type,
      nullable: nullable ?? this.nullable,
      isStatic: isStatic ?? this.isStatic,
      isAbstract: isAbstract ?? this.isAbstract,
      hasSetter: hasSetter ?? this.hasSetter,
      isSuper: isSuper ?? this.isSuper,
      parameters: parameters ?? this.parameters,
      offset: offset ?? this.offset,
      end: end ?? this.end,
    );
  }
}
