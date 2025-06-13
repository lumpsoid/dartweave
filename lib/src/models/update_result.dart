/// Result of updating the copyWith method
class UpdateResult {
  /// The updated file content
  final String content;

  /// Whether the file was updated
  final bool updated;

  /// List of updated class names
  final List<String> updatedClasses;

  /// List of errors encountered during update
  final List<String> errors;

  /// Creates a new [UpdateResult] instance
  const UpdateResult({
    required this.content,
    required this.updated,
    this.updatedClasses = const [],
    this.errors = const [],
  });
}
