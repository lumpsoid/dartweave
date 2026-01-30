import 'package:meta/meta.dart';

@immutable
class FunctionBody {
  const FunctionBody({
    required this.offset,
    required this.end,
  });

  const FunctionBody.empty()
      : offset = 0,
        end = 0;

  final int offset;
  final int end;

  FunctionBody copyWith({
    int? offset,
    int? end,
  }) {
    return FunctionBody(
      offset: offset ?? this.offset,
      end: end ?? this.end,
    );
  }

  @override
  String toString() {
    return 'FunctionBody('
        ' offset: $offset,'
        ' end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return other is FunctionBody && other.offset == offset && other.end == end;
  }

  @override
  int get hashCode {
    return Object.hash(offset, end);
  }
}
