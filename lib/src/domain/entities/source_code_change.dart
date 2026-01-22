/// Data class representing a change to source code
class SourceCodeChange {
  const SourceCodeChange({
    required this.startOffset,
    required this.endOffset,
    required this.newContent,
  });

  final int startOffset;
  final int endOffset;
  final String newContent;

  @override
  String toString() {
    return 'SourceCodeChange('
        ' startOffset: $startOffset,'
        ' endOffset: $endOffset,'
        ' newContent: $newContent)';
  }
}
