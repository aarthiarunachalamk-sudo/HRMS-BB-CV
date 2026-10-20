import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Persists active client visit progress and drafts across app sessions.
/// Allows employees to resume duty exactly where they stopped entering details.
class ClientVisitDraftStore {
  static const _fileName = 'client_visit_drafts.json';
  static Map<String, dynamic>? _memoryCache;

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<Map<String, dynamic>> _getAll() async {
    if (_memoryCache != null) return _memoryCache!;
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        if (data is Map<String, dynamic>) {
          _memoryCache = data;
          return data;
        }
      }
    } catch (_) {}
    _memoryCache = {};
    return _memoryCache!;
  }

  static Future<void> _saveAll(Map<String, dynamic> data) async {
    _memoryCache = data;
    try {
      final file = await _getFile();
      await file.writeAsString(json.encode(data));
    } catch (_) {}
  }

  /// Saves the last step number where the employee was working (e.g. 8, 9, 10, 11).
  static Future<void> saveStep(int visitId, int step) async {
    final all = await _getAll();
    final key = '$visitId';
    final visitData = Map<String, dynamic>.from(all[key] as Map? ?? {});
    visitData['last_step'] = step;
    visitData['updated_at'] = DateTime.now().toIso8601String();
    all[key] = visitData;
    await _saveAll(all);
  }

  /// Returns the step where the employee stopped entering details.
  static Future<int?> getLastStep(int visitId) async {
    final all = await _getAll();
    final key = '$visitId';
    final visitData = all[key] as Map?;
    if (visitData != null && visitData['last_step'] != null) {
      final step = visitData['last_step'];
      if (step is int) return step;
      return int.tryParse('$step');
    }
    return null;
  }

  /// Saves draft fields (notes, outcome, follow_up, signature_name, return_mode, amount, etc.)
  static Future<void> saveDraft(int visitId, Map<String, dynamic> fields) async {
    final all = await _getAll();
    final key = '$visitId';
    final visitData = Map<String, dynamic>.from(all[key] as Map? ?? {});
    fields.forEach((k, v) {
      if (v != null) visitData[k] = v;
    });
    visitData['updated_at'] = DateTime.now().toIso8601String();
    all[key] = visitData;
    await _saveAll(all);
  }

  /// Retrieves the draft values for a given visit.
  static Future<Map<String, dynamic>> getDraft(int visitId) async {
    final all = await _getAll();
    final key = '$visitId';
    final visitData = all[key] as Map?;
    if (visitData != null) {
      return Map<String, dynamic>.from(visitData);
    }
    return {};
  }

  /// Clears draft entries and recorded step when visit duty is completed.
  static Future<void> clear(int visitId) async {
    final all = await _getAll();
    all.remove('$visitId');
    await _saveAll(all);
  }
}
