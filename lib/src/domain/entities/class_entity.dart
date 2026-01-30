import 'package:dartweave/src/domain/entities/constructor_entity.dart';
import 'package:dartweave/src/domain/entities/field.dart';
import 'package:dartweave/src/domain/entities/method_entity.dart';
import 'package:dartweave/src/domain/entities/operator_entity.dart';
import 'package:dartweave/src/domain/entities/property_entity.dart';
import 'package:meta/meta.dart';

/// Domain entity representing a Dart class
@immutable
class ClassEntity {
  const ClassEntity({
    required this.name,
    required this.offset,
    required this.end,
    this.fields = const [],
    this.methods = const [],
    this.constructors = const [],
    this.getters = const [],
    this.setters = const [],
    this.operators = const [],
    this.isAbstract = false,
    this.superclassEntity,
  });

  final String name;
  final List<Field> fields;
  final List<MethodEntity> methods;
  final List<ConstructorEntity> constructors;
  final List<PropertyEntity> getters;
  final List<PropertyEntity> setters;
  final List<OperatorEntity> operators;
  final ClassEntity? superclassEntity;
  final bool isAbstract;
  final int offset;
  final int end;

  bool get isZeroOffset => (end - offset) == 0;

  // Convenience getter to recursively get all fields including inherited ones
  List<Field> allFields() {
    final all = [...fields];
    if (superclassEntity != null) {
      all.addAll(
        superclassEntity!.allFields().map(
              (f) => Field(
                name: f.name,
                type: f.type,
                nullable: f.nullable,
                isSuper: true,
                isConst: f.isConst,
                isFinal: f.isFinal,
                isLate: f.isLate,
                isStatic: f.isStatic,
                offset: f.offset,
                end: f.end,
              ),
            ),
      );
    }
    return all;
  }

  @override
  String toString() {
    return 'ClassEntity('
        ' name: $name,'
        ' fields: $fields,'
        ' methods: $methods,'
        ' constructors: $constructors,'
        ' getters: $getters,'
        ' setters: $setters,'
        ' operators: $operators,'
        ' superclassEntity: $superclassEntity,'
        ' isAbstract: $isAbstract,'
        ' offset: $offset,'
        ' end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return other is ClassEntity &&
        other.name == name &&
        other.fields == fields &&
        other.methods == methods &&
        other.constructors == constructors &&
        other.getters == getters &&
        other.setters == setters &&
        other.operators == operators &&
        other.superclassEntity == superclassEntity &&
        other.isAbstract == isAbstract &&
        other.offset == offset &&
        other.end == end;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      fields,
      methods,
      constructors,
      getters,
      setters,
      operators,
      superclassEntity,
      isAbstract,
      offset,
      end,
    );
  }

  ClassEntity copyWith({
    String? name,
    List<Field>? fields,
    List<MethodEntity>? methods,
    List<ConstructorEntity>? constructors,
    List<PropertyEntity>? getters,
    List<PropertyEntity>? setters,
    List<OperatorEntity>? operators,
    ClassEntity? superclassEntity,
    bool? isAbstract,
    int? offset,
    int? end,
  }) {
    return ClassEntity(
      name: name ?? this.name,
      fields: fields ?? this.fields,
      methods: methods ?? this.methods,
      constructors: constructors ?? this.constructors,
      getters: getters ?? this.getters,
      setters: setters ?? this.setters,
      operators: operators ?? this.operators,
      superclassEntity: superclassEntity ?? this.superclassEntity,
      isAbstract: isAbstract ?? this.isAbstract,
      offset: offset ?? this.offset,
      end: end ?? this.end,
    );
  }
}
