import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ClientServiceDetailsCache {
  static const _fileName = 'pending_client_service_details.json';

  static Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<Map<String, dynamic>> savePending({
    required String userId,
    required String clientName,
    required String clientEmail,
    required String clientMobile,
    required String clientGst,
    required String clientAddress,
    required String clientDetails,
  }) async {
    final items = await _loadAll();
    final now = DateTime.now();
    final record = <String, dynamic>{
      'id': 'pending_${now.microsecondsSinceEpoch}',
      'title': 'Client details',
      'user_id': userId,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_mobile': clientMobile,
      'client_gst': clientGst,
      'client_address': clientAddress,
      'client_details': clientDetails,
      'created_at': now.toIso8601String(),
      'sync_pending': true,
    };
    items.insert(0, record);
    await (await _file()).writeAsString(jsonEncode(items), flush: true);
    return record;
  }

  static Future<List<Map<String, dynamic>>> load(String userId) async {
    final items = await _loadAll();
    return items.where((item) => '${item['user_id'] ?? ''}' == userId).toList();
  }

  static Future<void> remove(Object? id) async {
    final items = await _loadAll();
    items.removeWhere((item) => '${item['id']}' == '$id');
    await (await _file()).writeAsString(jsonEncode(items), flush: true);
  }

  static Future<List<Map<String, dynamic>>> _loadAll() async {
    try {
      final file = await _file();
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
