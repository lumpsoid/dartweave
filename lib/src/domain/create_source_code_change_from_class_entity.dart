import 'package:dartweave/src/domain/entities/entities.dart';

SourceCodeChange _createSourceCodeChangeGeneric<T>(
  String methodType,
  ClassEntity classEntity,
  String? name,
  StringBuffer buffer,
  List<T> entities,
  String? Function(T) getName,
  int Function(T) getOffset,
  int Function(T) getEnd,
) {
  final index = entities.indexWhere((e) => getName(e) == name);
  final isPresent = index != -1;

  if (isPresent) {
    final entity = entities[index];
    return SourceCodeChangeOk(
      method: methodType,
      startOffset: getOffset(entity),
      endOffset: getEnd(entity),
      newContent: '$buffer',
    );
  }

  return SourceCodeChangeOk(
    method: methodType,
    startOffset: classEntity.end - 1,
    endOffset: classEntity.end - 1,
    newContent: '\n  $buffer\n',
  );
}

SourceCodeChange createSourceCodeChangeForMethod(
  String methodType,
  ClassEntity classEntity,
  String name,
  StringBuffer buffer,
) =>
    _createSourceCodeChangeGeneric(
      methodType,
      classEntity,
      name,
      buffer,
      classEntity.methods,
      (e) => e.name,
      (e) => e.offset,
      (e) => e.end,
    );

SourceCodeChange createSourceCodeChangeForGetter(
  String methodType,
  ClassEntity classEntity,
  String name,
  StringBuffer buffer,
) =>
    _createSourceCodeChangeGeneric(
      methodType,
      classEntity,
      name,
      buffer,
      classEntity.getters,
      (e) => e.name,
      (e) => e.offset,
      (e) => e.end,
    );

SourceCodeChange createSourceCodeChangeForSetter(
  String methodType,
  ClassEntity classEntity,
  String name,
  StringBuffer buffer,
) =>
    _createSourceCodeChangeGeneric(
      methodType,
      classEntity,
      name,
      buffer,
      classEntity.setters,
      (e) => e.name,
      (e) => e.offset,
      (e) => e.end,
    );

SourceCodeChange createSourceCodeChangeForConstructor(
  String methodType,
  ClassEntity classEntity,
  String? name,
  StringBuffer buffer,
) =>
    _createSourceCodeChangeGeneric(
      methodType,
      classEntity,
      name,
      buffer,
      classEntity.constructors,
      (e) => e.name,
      (e) => e.offset,
      (e) => e.end,
    );

SourceCodeChange createSourceCodeChangeForOperator(
  String methodType,
  ClassEntity classEntity,
  String name,
  StringBuffer buffer,
) =>
    _createSourceCodeChangeGeneric(
      methodType,
      classEntity,
      name,
      buffer,
      classEntity.operators,
      (e) => e.name,
      (e) => e.offset,
      (e) => e.end,
    );
