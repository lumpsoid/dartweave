import 'package:dartweave/src/domain/entities/entities.dart';
import 'package:dartweave/src/infrastructure/repositories/ast_class_parser_repository.dart';
import 'package:dartweave/src/infrastructure/repositories/ast_method_generator_repository.dart';
import 'package:test/test.dart';

void main() {
  group('AstMethodGeneratorRepository', () {
    late AstClassParserRepository parser;
    late AstMethodGeneratorRepository generator;

    setUp(() {
      parser = AstClassParserRepository();
      generator = AstMethodGeneratorRepository();
    });

    group('generateMethods offset ordering', () {
      // Regression: when multiple new methods all append at classEntity.end - 1,
      // they must appear in generation order, not reversed.
      test(
        'multiple new methods appear in generation order, not reversed',
        () {
          const source = '''
class Foo {
  const Foo({required this.x, required this.y});

  final int x;
  final int y;
}
''';

          final classes = parser.parseClasses(source, 'foo.dart');
          final result = generator.generateMethods(
            classes.first,
            [
              MethodType.copyWithMethod,
              MethodType.toStringMethod,
              MethodType.hashCodeMethod,
            ],
            source,
          );

          expect(result.errors, isEmpty);

          final output = result.updatedSourceCode;
          final copyWithPos = output.indexOf('copyWith(');
          final toStringPos = output.indexOf('String toString()');
          final hashCodePos = output.indexOf('get hashCode');

          expect(copyWithPos, greaterThan(-1), reason: 'copyWith not found');
          expect(toStringPos, greaterThan(-1), reason: 'toString not found');
          expect(hashCodePos, greaterThan(-1), reason: 'hashCode not found');

          expect(
            copyWithPos,
            lessThan(toStringPos),
            reason: 'copyWith should appear before toString',
          );
          expect(
            toStringPos,
            lessThan(hashCodePos),
            reason: 'toString should appear before hashCode',
          );
        },
      );

      test(
        'replacing an existing method does not corrupt appended methods',
        () {
          const source = '''
class Bar {
  const Bar({required this.value});

  final String value;

  @override
  String toString() => 'OLD';
}
''';

          final classes = parser.parseClasses(source, 'bar.dart');
          final result = generator.generateMethods(
            classes.first,
            [
              MethodType.copyWithMethod,
              MethodType.toStringMethod,
            ],
            source,
          );

          expect(result.errors, isEmpty);

          final output = result.updatedSourceCode;
          expect(output.contains('OLD'), isFalse,
              reason: 'old toString must be replaced');
          expect(output.contains('copyWith('), isTrue,
              reason: 'copyWith must be present');
          expect(output.contains('String toString()'), isTrue,
              reason: 'toString must be present');
        },
      );
    });
  });
}
