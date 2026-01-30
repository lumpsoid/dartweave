import 'package:dartweave/src/domain/entities/entities.dart';

SourceCodeChange _createSourceCodeChangeGeneric<T>(
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
    return SourceCodeChange(
      startOffset: getOffset(entity),
      endOffset: getEnd(entity),
      newContent: '$buffer',
    );
  }

  return SourceCodeChange(
    startOffset: classEntity.end - 1,
    endOffset: classEntity.end - 1,
    newContent: '\n  $buffer\n',
  );
}

SourceCodeChange createSourceCodeChangeForMethod(
  ClassEntity classEntity,
  String name,
  StringBuffer buffer,
) =>
    _createSourceCodeChangeGeneric(
      classEntity,
      name,
      buffer,
      classEntity.methods,
      (e) => e.name,
      (e) => e.offset,
      (e) => e.end,
    );

SourceCodeChange createSourceCodeChangeForGetter(
  ClassEntity classEntity,
  String name,
  StringBuffer buffer,
) =>
    _createSourceCodeChangeGeneric(
      classEntity,
      name,
      buffer,
      classEntity.getters,
      (e) => e.name,
      (e) => e.offset,
      (e) => e.end,
    );

SourceCodeChange createSourceCodeChangeForSetter(
  ClassEntity classEntity,
  String name,
  StringBuffer buffer,
) =>
    _createSourceCodeChangeGeneric(
      classEntity,
      name,
      buffer,
      classEntity.setters,
      (e) => e.name,
      (e) => e.offset,
      (e) => e.end,
    );

SourceCodeChange createSourceCodeChangeForConstructor(
  ClassEntity classEntity,
  String? name,
  StringBuffer buffer,
) =>
    _createSourceCodeChangeGeneric(
      classEntity,
      name,
      buffer,
      classEntity.constructors,
      (e) => e.name,
      (e) => e.offset,
      (e) => e.end,
    );

SourceCodeChange createSourceCodeChangeForOperator(
  ClassEntity classEntity,
  String name,
  StringBuffer buffer,
) =>
    _createSourceCodeChangeGeneric(
      classEntity,
      name,
      buffer,
      classEntity.operators,
      (e) => e.name,
      (e) => e.offset,
      (e) => e.end,
    );
