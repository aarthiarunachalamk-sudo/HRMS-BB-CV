import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CeoLocalDocuments {
  static const _fileName = 'ceo_saved_documents.json';

  static Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<List<Map<String, dynamic>>> load(String userId) async {
    try {
      final file = await _file();
      if (!await file.exists()) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => '${item['user_id'] ?? ''}' == userId)
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> save({
    required String userId,
    required String title,
    required String category,
    required String extension,
    required String url,
    required String displayPath,
    String owner = 'CEO',
    String status = 'Saved',
    String direction = 'Saved',
  }) async {
    final file = await _file();
    final existing = await _loadAll(file);
    final now = DateTime.now();
    final document = <String, dynamic>{
      'id': 'local_${now.microsecondsSinceEpoch}',
      'user_id': userId,
      'title': title,
      'category': category,
      'owner': owner,
      'employee_id': userId,
      'status': status,
      'direction': direction,
      'extension': extension.toLowerCase(),
      'url': url,
      'storage_path': displayPath,
      'created_at': now.toIso8601String(),
      'source': 'mobile',
    };

    existing.removeWhere(
      (item) =>
          '${item['user_id'] ?? ''}' == userId &&
          '${item['title'] ?? ''}' == title &&
          '${item['storage_path'] ?? ''}' == displayPath,
    );
    existing.insert(0, document);
    await file.writeAsString(jsonEncode(existing), flush: true);
  }

  static Future<List<Map<String, dynamic>>> _loadAll(File file) async {
    try {
      if (!await file.exists()) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}
