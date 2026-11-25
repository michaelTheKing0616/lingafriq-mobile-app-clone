/// P9-952 — pure helpers for roster CSV import UI feedback.
Map<String, dynamic> summarizeRosterImportResult(Map<String, dynamic> result) {
  final parseErrors = List<Map<String, dynamic>>.from(result['parseErrors'] ?? const []);
  final imported = List<Map<String, dynamic>>.from(result['imported'] ?? const []);
  final ok = imported.where((r) => r['ok'] == true).length;
  final rowFails = imported.where((r) => r['ok'] != true).toList();
  final errors = [...parseErrors, ...rowFails];
  final summary = rowFails.isNotEmpty || parseErrors.isNotEmpty
      ? 'Added $ok learners. ${errors.length} rows need a quick fix below.'
      : 'Added $ok learners to your class.';
  return {'okCount': ok, 'errors': errors, 'summary': summary};
}
