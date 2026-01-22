import 'package:dartweave/src/domain/entities/constructor_entity.dart';
import 'package:dartweave/src/domain/entities/field.dart';
import 'package:dartweave/src/domain/entities/method_entity.dart';
import 'package:dartweave/src/domain/entities/operator_entity.dart';
import 'package:dartweave/src/domain/entities/property_entity.dart';
import 'package:equatable/equatable.dart';

/// Domain entity representing a Dart class
class ClassEntity extends Equatable {
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

  @override
  List<Object?> get props => [
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
      ];

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
}
