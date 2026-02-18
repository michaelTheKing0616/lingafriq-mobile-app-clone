import 'skill_node.dart';

/// Directed Acyclic Graph (DAG) of skill dependencies.
///
/// The dependency graph determines the order in which skills can be
/// unlocked and practiced. A skill is "available" only when all its
/// prerequisites are mastered.
///
/// Supports topological ordering, reachability queries, and
/// dependency-aware curriculum sequencing.
class SkillDependencyGraph {
  /// All skill nodes indexed by ID.
  final Map<String, SkillNode> _nodes = {};

  /// Adjacency list: skill ID -> list of skills that depend on it.
  final Map<String, Set<String>> _dependents = {};

  /// Reverse adjacency: skill ID -> list of prerequisites.
  final Map<String, Set<String>> _prerequisites = {};

  /// Cached topological ordering (invalidated on mutation).
  List<String>? _topoOrder;

  /// Number of skills in the graph.
  int get nodeCount => _nodes.length;

  /// All skill IDs in the graph.
  Iterable<String> get skillIds => _nodes.keys;

  /// Gets a skill node by ID.
  SkillNode? getSkill(String id) => _nodes[id];

  /// Adds a skill to the graph. Prerequisites must reference existing skills
  /// or skills that will be added later (validated at query time).
  void addSkill(SkillNode skill) {
    _nodes[skill.id] = skill;
    _dependents.putIfAbsent(skill.id, () => {});
    _prerequisites[skill.id] = Set.from(skill.prerequisites);

    for (final prereq in skill.prerequisites) {
      _dependents.putIfAbsent(prereq, () => {}).add(skill.id);
    }

    _topoOrder = null;
  }

  /// Adds multiple skills at once.
  void addSkills(Iterable<SkillNode> skills) {
    for (final skill in skills) {
      addSkill(skill);
    }
  }

  /// Returns skills that have no prerequisites (entry points).
  List<SkillNode> get rootSkills {
    return _nodes.values
        .where((s) => s.prerequisites.isEmpty)
        .toList();
  }

  /// Returns skills that no other skill depends on (leaf nodes).
  List<SkillNode> get leafSkills {
    return _nodes.values
        .where((s) => (_dependents[s.id]?.isEmpty ?? true))
        .toList();
  }

  /// Returns the direct prerequisites of a skill.
  List<SkillNode> getPrerequisites(String skillId) {
    final prereqIds = _prerequisites[skillId] ?? {};
    return prereqIds
        .map((id) => _nodes[id])
        .whereType<SkillNode>()
        .toList();
  }

  /// Returns all skills that directly depend on this skill.
  List<SkillNode> getDependents(String skillId) {
    final depIds = _dependents[skillId] ?? {};
    return depIds
        .map((id) => _nodes[id])
        .whereType<SkillNode>()
        .toList();
  }

  /// Returns all transitive prerequisites (deep ancestors).
  Set<String> getAllPrerequisites(String skillId) {
    final visited = <String>{};
    final queue = <String>[..._prerequisites[skillId] ?? {}];

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (visited.add(current)) {
        queue.addAll(_prerequisites[current] ?? {});
      }
    }

    return visited;
  }

  /// Returns the topological ordering of skills.
  ///
  /// Guarantees that every skill appears after all its prerequisites.
  /// Used for curriculum sequencing.
  List<String> get topologicalOrder {
    if (_topoOrder != null) return _topoOrder!;

    final inDegree = <String, int>{};
    for (final id in _nodes.keys) {
      inDegree[id] = (_prerequisites[id]?.length ?? 0);
    }

    final queue = <String>[];
    for (final entry in inDegree.entries) {
      if (entry.value == 0) queue.add(entry.key);
    }

    final result = <String>[];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);

      for (final dependent in _dependents[current] ?? <String>{}) {
        inDegree[dependent] = (inDegree[dependent] ?? 1) - 1;
        if (inDegree[dependent] == 0) {
          queue.add(dependent);
        }
      }
    }

    if (result.length != _nodes.length) {
      throw StateError(
        'Cycle detected in skill graph. '
        '${_nodes.length - result.length} skills are in a cycle.',
      );
    }

    _topoOrder = result;
    return _topoOrder!;
  }

  /// Returns the skills available to a learner given their mastered skills.
  ///
  /// A skill is "available" if ALL its prerequisites are in [masteredSkillIds].
  List<SkillNode> getAvailableSkills(Set<String> masteredSkillIds) {
    return _nodes.values.where((skill) {
      if (masteredSkillIds.contains(skill.id)) return false;
      return skill.prerequisites.every(masteredSkillIds.contains);
    }).toList();
  }

  /// Returns the shortest path of skills from a root to the target skill.
  ///
  /// Useful for showing learners what they need to master to unlock a goal skill.
  List<String> pathToSkill(String targetSkillId) {
    if (!_nodes.containsKey(targetSkillId)) return [];

    final allPrereqs = getAllPrerequisites(targetSkillId);
    final topoOrder = topologicalOrder;

    return topoOrder
        .where((id) => allPrereqs.contains(id) || id == targetSkillId)
        .toList();
  }

  /// Returns skills grouped by their depth (distance from root nodes).
  ///
  /// Level 0 = root skills, Level 1 = depends on level 0 only, etc.
  Map<int, List<SkillNode>> get skillsByDepth {
    final depths = <String, int>{};
    final topo = topologicalOrder;

    for (final id in topo) {
      final prereqDepths = (_prerequisites[id] ?? {})
          .map((p) => depths[p] ?? 0);
      depths[id] = prereqDepths.isEmpty ? 0 : prereqDepths.reduce((a, b) => a > b ? a : b) + 1;
    }

    final result = <int, List<SkillNode>>{};
    for (final entry in depths.entries) {
      final node = _nodes[entry.key];
      if (node != null) {
        result.putIfAbsent(entry.value, () => []).add(node);
      }
    }

    return result;
  }

  /// Validates the graph integrity.
  ///
  /// Returns a list of validation errors. Empty list = valid graph.
  List<String> validate() {
    final errors = <String>[];

    // Check for missing prerequisites
    for (final skill in _nodes.values) {
      for (final prereq in skill.prerequisites) {
        if (!_nodes.containsKey(prereq)) {
          errors.add('Skill "${skill.id}" references unknown prerequisite "$prereq"');
        }
      }
    }

    // Check for cycles
    try {
      topologicalOrder;
    } catch (e) {
      errors.add(e.toString());
    }

    return errors;
  }

  /// Serializes the graph to JSON.
  Map<String, dynamic> toJson() => {
        'skills': _nodes.values.map((s) => s.toJson()).toList(),
      };

  /// Deserializes the graph from JSON.
  factory SkillDependencyGraph.fromJson(Map<String, dynamic> json) {
    final graph = SkillDependencyGraph();
    final skills = (json['skills'] as List<dynamic>)
        .map((s) => SkillNode.fromJson(s as Map<String, dynamic>));
    graph.addSkills(skills);
    return graph;
  }
}
