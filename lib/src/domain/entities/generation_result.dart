/// Result of method generation
class GenerationResult {
  const GenerationResult({
    required this.updatedSourceCode,
    required this.wasUpdated,
    required this.generatedMethods,
  });

  final String updatedSourceCode;
  final bool wasUpdated;
  final List<String> generatedMethods;

  @override
  String toString() {
    return 'GenerationResult('
        ' updatedSourceCode: $updatedSourceCode,'
        ' wasUpdated: $wasUpdated,'
        ' generatedMethods: $generatedMethods)';
  }
}
