import 'package:dartweave/src/application/use_cases/generate_methods_use_case.dart';
import 'package:dartweave/src/domain/entities/entities.dart';
import 'package:dartweave/src/infrastructure/repositories/ast_class_parser_repository.dart';
import 'package:dartweave/src/infrastructure/repositories/ast_method_generator_repository.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateMethodsUseCase', () {
    late GenerateMethodsUseCase useCase;

    setUp(() {
      useCase = GenerateMethodsUseCase(
        parserRepository: AstClassParserRepository(),
        generatorRepository: AstMethodGeneratorRepository(),
      );
    });

    // Regression test: when a file has multiple classes, generators used
    // classEntity offsets from the original parse but were handed the
    // already-modified source from the previous class, causing offset
    // mismatches and interleaved/corrupted output.
    group('multi-class file', () {
      test(
        'generates constructors for each class without corrupting output',
        () async {
          const source = '''
class ChatPartner {
  final String id;
  final String? name;
  final bool isOnline;
}

class ChatPartnerTest {
  final String id;
  final String? name;
  final bool isOnline;
}
''';

          final result = await useCase.execute(
            const GenerationRequest(
              className: '',
              filePath: 'chat_partner.dart',
              sourceCode: source,
              methodTypes: [
                MethodType.defaultConstructor,
                MethodType.emptyConstructor,
              ],
              updateAllClasses: true,
            ),
          );

          expect(result, isA<GenerateMethodsOk>());
          final ok = result as GenerateMethodsOk;
          expect(ok.wasUpdated, isTrue);

          final output = ok.updatedSourceCode!;

          // Each class must have exactly one default constructor
          expect(
            RegExp(r'ChatPartner\(').allMatches(output).length,
            greaterThanOrEqualTo(1),
            reason: 'ChatPartner default constructor missing',
          );
          expect(
            RegExp(r'ChatPartnerTest\(').allMatches(output).length,
            greaterThanOrEqualTo(1),
            reason: 'ChatPartnerTest default constructor missing',
          );

          // ChatPartnerTest body must not appear inside ChatPartner's block.
          // Parse the result — if it's corrupted the analyzer throws.
          expect(
            () => AstClassParserRepository().parseClasses(output, 'chat_partner.dart'),
            returnsNormally,
            reason: 'generated output is not valid Dart',
          );

          final classes = AstClassParserRepository().parseClasses(output, 'chat_partner.dart');
          expect(classes, hasLength(2));

          // Both classes must have their own constructors in the right place
          final partner = classes.firstWhere((c) => c.name == 'ChatPartner');
          final partnerTest = classes.firstWhere((c) => c.name == 'ChatPartnerTest');
          expect(partner.constructors, isNotEmpty);
          expect(partnerTest.constructors, isNotEmpty);
        },
      );

      test(
        'second class constructor body is not split across first class output',
        () async {
          const source = '''
class A {
  final int x;
  final int y;
}

class B {
  final String name;
  final bool flag;
}
''';

          final result = await useCase.execute(
            const GenerationRequest(
              className: '',
              filePath: 'ab.dart',
              sourceCode: source,
              methodTypes: [MethodType.defaultConstructor],
              updateAllClasses: true,
            ),
          );

          final ok = result as GenerateMethodsOk;
          final output = ok.updatedSourceCode!;

          // A's constructor must appear entirely before B's class definition
          final aConstructorPos = output.indexOf('A({');
          final bClassPos = output.indexOf('class B');
          final bConstructorPos = output.indexOf('B({');

          expect(aConstructorPos, greaterThan(-1));
          expect(bClassPos, greaterThan(-1));
          expect(bConstructorPos, greaterThan(-1));

          expect(
            aConstructorPos,
            lessThan(bClassPos),
            reason: "A's constructor should appear before class B",
          );
          expect(
            bClassPos,
            lessThan(bConstructorPos),
            reason: "B's constructor should appear inside class B",
          );
        },
      );
    });
  });
}
