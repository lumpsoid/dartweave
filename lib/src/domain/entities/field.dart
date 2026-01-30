import 'package:meta/meta.dart';

/// Domain entity representing a class field
@immutable
class Field {
  const Field({
    required this.name,
    required this.type,
    required this.offset,
    required this.end,
    this.nullable = false,
    this.isSuper = false,
    this.isFinal = false,
    this.isConst = false,
    this.isStatic = false,
    this.isLate = false,
  });

  const Field.empty()
      : name = '',
        type = '',
        nullable = false,
        isSuper = false,
        isFinal = false,
        isConst = false,
        isStatic = false,
        isLate = false,
        offset = 0,
        end = 0;

  final String name;
  final String type;
  final bool nullable;
  final bool isSuper;
  final bool isFinal;
  final bool isConst;
  final bool isStatic;
  final bool isLate;
  final int offset;
  final int end;

  @override
  String toString() {
    return 'Field('
        ' name: $name,'
        ' type: $type,'
        ' nullable: $nullable,'
        ' isSuper: $isSuper,'
        ' isFinal: $isFinal,'
        ' isConst: $isConst,'
        ' isStatic: $isStatic,'
        ' isLate: $isLate,'
        ' offset: $offset,'
        ' end: $end)';
  }

  /// Returns the Dart source code representation of this field.
  String toSourceCode() {
    final buffer = StringBuffer();

    if (isStatic) buffer.write('static ');
    if (isLate) buffer.write('late ');

    if (isConst) {
      buffer.write('const ');
    } else if (isFinal) {
      buffer.write('final ');
    }

    buffer.write(type);
    if (nullable) buffer.write('?');
    buffer.write(' ');
    buffer.write(name);
    buffer.write(';');

    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    return other is Field &&
        other.name == name &&
        other.type == type &&
        other.nullable == nullable &&
        other.isSuper == isSuper &&
        other.isFinal == isFinal &&
        other.isConst == isConst &&
        other.isStatic == isStatic &&
        other.isLate == isLate &&
        other.offset == offset &&
        other.end == end;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      type,
      nullable,
      isSuper,
      isFinal,
      isConst,
      isStatic,
      isLate,
      offset,
      end,
    );
  }

  Field copyWith({
    String? name,
    String? type,
    bool? nullable,
    bool? isSuper,
    bool? isFinal,
    bool? isConst,
    bool? isStatic,
    bool? isLate,
    int? offset,
    int? end,
  }) {
    return Field(
      name: name ?? this.name,
      type: type ?? this.type,
      nullable: nullable ?? this.nullable,
      isSuper: isSuper ?? this.isSuper,
      isFinal: isFinal ?? this.isFinal,
      isConst: isConst ?? this.isConst,
      isStatic: isStatic ?? this.isStatic,
      isLate: isLate ?? this.isLate,
      offset: offset ?? this.offset,
      end: end ?? this.end,
    );
  }
}
