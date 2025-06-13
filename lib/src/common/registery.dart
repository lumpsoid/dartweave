import 'package:dart_create_class/src/common/template.dart';

/// Registry to manage all available templates
class TemplateRegistry {
  factory TemplateRegistry() => _instance;
  TemplateRegistry._();

  static final TemplateRegistry _instance = TemplateRegistry._();

  final Map<String, Map<String, CodeTemplate>> _templates = {};

  /// Register a template
  void register(CodeTemplate template) {
    _templates.putIfAbsent(template.category, () => {});
    _templates[template.category]![template.name] = template;
  }

  /// Get a template by category and name
  T? getTemplate<T extends CodeTemplate>(String category, String name) {
    return _templates[category]?[name] as T?;
  }

  /// Get all templates of a specific category
  List<T> getTemplatesOfType<T extends CodeTemplate>() {
    final category = _getCategoryFromType<T>();
    return _templates[category]?.values.whereType<T>().toList() ?? [];
  }

  /// Get all method templates
  List<MethodTemplate> get methodTemplates =>
      getTemplatesOfType<MethodTemplate>();

  /// Get all getter templates
  List<GetterTemplate> get getterTemplates =>
      getTemplatesOfType<GetterTemplate>();

  /// Get all constructor templates
  List<ConstructorTemplate> get constructorTemplates =>
      getTemplatesOfType<ConstructorTemplate>();

  /// Get category from template type
  String _getCategoryFromType<T extends CodeTemplate>() {
    if (T == MethodTemplate) return 'method';
    if (T == GetterTemplate) return 'getter';
    if (T == ConstructorTemplate) return 'constructor';
    return 'unknown';
  }

  /// Get all available template names by category
  Map<String, List<String>> get availableTemplates {
    final result = <String, List<String>>{};
    for (final category in _templates.keys) {
      result[category] = _templates[category]!.keys.toList();
    }
    return result;
  }
}
