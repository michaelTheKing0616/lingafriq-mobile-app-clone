import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'dependency_graph.dart';
import 'skill_node.dart';

/// Manages the registry of all skills across all supported languages.
///
/// The registry is the single source of truth for skill definitions.
/// Skills can be loaded from bundled assets, fetched from the backend,
/// or defined programmatically.
///
/// Provides language-filtered views and CEFR-level filtering.
class SkillRegistry {
  static SkillRegistry? _instance;
  static SkillRegistry get instance => _instance ??= SkillRegistry._();

  SkillRegistry._();

  final Map<String, SkillDependencyGraph> _languageGraphs = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initializes the registry, loading cached skill data if available.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('skill_registry_data');
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        _loadFromJson(data);
      }
    } catch (_) {
      // Cache miss or corrupt data — will be populated by registerSkills
    }

    _isInitialized = true;
  }

  /// Registers skills for a language, building the dependency graph.
  ///
  /// Can be called incrementally as new language packs are downloaded.
  void registerSkills(String languageCode, List<SkillNode> skills) {
    final graph = _languageGraphs.putIfAbsent(
      languageCode,
      () => SkillDependencyGraph(),
    );
    graph.addSkills(skills);
    _persistAsync();
  }

  /// Returns the dependency graph for a specific language.
  SkillDependencyGraph? getGraph(String languageCode) {
    return _languageGraphs[languageCode];
  }

  /// Returns all registered language codes.
  Set<String> get registeredLanguages => _languageGraphs.keys.toSet();

  /// Returns all skills for a language, optionally filtered by CEFR level.
  List<SkillNode> getSkills(String languageCode, {CefrLevel? cefrLevel}) {
    final graph = _languageGraphs[languageCode];
    if (graph == null) return [];

    final allSkills = graph.skillIds
        .map((id) => graph.getSkill(id))
        .whereType<SkillNode>()
        .toList();

    if (cefrLevel != null) {
      return allSkills.where((s) => s.cefrLevel == cefrLevel).toList();
    }

    return allSkills;
  }

  /// Returns a specific skill across all languages.
  SkillNode? findSkill(String skillId) {
    for (final graph in _languageGraphs.values) {
      final skill = graph.getSkill(skillId);
      if (skill != null) return skill;
    }
    return null;
  }

  /// Returns available skills (unlocked) for a learner in a language.
  List<SkillNode> getAvailableSkills(
    String languageCode,
    Set<String> masteredSkillIds,
  ) {
    final graph = _languageGraphs[languageCode];
    if (graph == null) return [];
    return graph.getAvailableSkills(masteredSkillIds);
  }

  /// Returns the root skills (no prerequisites) for a language.
  List<SkillNode> getRootSkills(String languageCode) {
    return _languageGraphs[languageCode]?.rootSkills ?? [];
  }

  /// Returns skills grouped by type for a language.
  Map<SkillType, List<SkillNode>> getSkillsByType(String languageCode) {
    final skills = getSkills(languageCode);
    final grouped = <SkillType, List<SkillNode>>{};
    for (final skill in skills) {
      grouped.putIfAbsent(skill.type, () => []).add(skill);
    }
    return grouped;
  }

  /// Returns skills grouped by CEFR level for a language.
  Map<CefrLevel, List<SkillNode>> getSkillsByCefrLevel(String languageCode) {
    final skills = getSkills(languageCode);
    final grouped = <CefrLevel, List<SkillNode>>{};
    for (final skill in skills) {
      grouped.putIfAbsent(skill.cefrLevel, () => []).add(skill);
    }
    return grouped;
  }

  /// Validates all registered graphs.
  Map<String, List<String>> validateAll() {
    final results = <String, List<String>>{};
    for (final entry in _languageGraphs.entries) {
      final errors = entry.value.validate();
      if (errors.isNotEmpty) {
        results[entry.key] = errors;
      }
    }
    return results;
  }

  /// Clears all registered skills.
  void clear() {
    _languageGraphs.clear();
    _topoOrder = null;
  }

  List<String>? _topoOrder;

  void _loadFromJson(Map<String, dynamic> data) {
    final languages = data['languages'] as Map<String, dynamic>? ?? {};
    for (final entry in languages.entries) {
      final graph = SkillDependencyGraph.fromJson(
        entry.value as Map<String, dynamic>,
      );
      _languageGraphs[entry.key] = graph;
    }
  }

  Map<String, dynamic> _toJson() {
    return {
      'languages': _languageGraphs.map(
        (key, graph) => MapEntry(key, graph.toJson()),
      ),
    };
  }

  /// Persists the registry asynchronously.
  Future<void> _persistAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('skill_registry_data', jsonEncode(_toJson()));
    } catch (_) {
      // Non-critical — will be rebuilt on next launch
    }
  }
}
