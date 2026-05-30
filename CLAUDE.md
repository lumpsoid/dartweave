# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
# Run all tests
dart test

# Run a single test file
dart test test/src/application/method_generator/copy_with_generator_test.dart

# Run tests with a specific name pattern
dart test --name "copyWith"

# Run version-verify tests (skipped in normal runs)
dart run test --run-skipped -t version-verify

# Format then analyze (always format first — never fix formatting errors by hand)
dart format .
dart analyze --format=machine .

# Run tests with coverage
dart pub global activate coverage 1.2.0
dart test --coverage=coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

## Architecture

`dartweave` is a Dart CLI tool that parses Dart source files via the `analyzer` AST package and generates boilerplate methods (copyWith, toString, equality, fromJson, isEmpty, constructors) directly into class source files.

### Layer structure

```
bin/dartweave.dart              # Entry point → DartCreateClassCommandRunner
lib/src/
  command_runner.dart           # CompletionCommandRunner subclass; wires DI, flags, tab completion
  presentation/commands/        # CLI commands (GenCommand, TestCommand, UpdateCommand, …)
  application/
    use_cases/                  # GenerateMethodsUseCase, GenerateUseCasesFromMethodsUseCase
    method_generator/           # One generator class per method type; all extend MethodGeneratorBase
  domain/
    entities/                   # ClassEntity, FieldEntity, MethodEntity, ConstructorEntity, etc.
  infrastructure/repositories/  # AstClassParserRepository (parse), AstMethodGeneratorRepository (write)
```

### Data flow

1. CLI command receives a Dart file path.
2. `AstClassParserRepository` uses `package:analyzer` to build an AST and maps it to domain entities (`ClassEntity` → `FieldEntity` etc.).
3. `GenerateMethodsUseCase` selects the requested generators and calls each one with the `ClassEntity`.
4. Each `MethodGeneratorBase` subclass produces a code string.
5. `AstMethodGeneratorRepository` applies the generated code as a source-change patch to the original file.

### Key conventions

- Domain entities are `@immutable` and use `equatable` for value equality.
- Generators receive a `ClassEntity` and return a `GenerationResult` (a sealed failure-or-success type).
- Static fields on a class are filtered out before generation; generators only see instance fields.
- `mason_logger` is used for all console output; pass the `Logger` instance through constructors.
- Linting is enforced by `very_good_analysis` v10; `public_member_api_docs` is disabled.
