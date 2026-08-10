import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'client_visit_theme.dart';

class ClientVisitDownloads {
  static const _fileName = 'client_visit_downloads.json';

  static Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<List<Map<String, dynamic>>> load(String userId) async {
    final items = await _loadAll();
    return items.where((item) => '${item['user_id'] ?? ''}' == userId).toList()
      ..sort(
        (a, b) => '${b['downloaded_at'] ?? ''}'.compareTo(
          '${a['downloaded_at'] ?? ''}',
        ),
      );
  }

  static Future<void> save({
    required String userId,
    required int visitId,
    required String visitReference,
    required String clientName,
    required String fileName,
    required String uri,
  }) async {
    final file = await _file();
    final items = await _loadAll();
    final now = DateTime.now();
    items.removeWhere(
      (item) =>
          '${item['user_id'] ?? ''}' == userId && '${item['uri'] ?? ''}' == uri,
    );
    items.insert(0, {
      'id': 'download_${now.microsecondsSinceEpoch}',
      'user_id': userId,
      'visit_id': visitId,
      'visit_reference': visitReference,
      'client_name': clientName,
      'file_name': fileName,
      'uri': uri,
      'display_path': 'Downloads/HRMS-ERP/$fileName',
      'mime_type': 'application/pdf',
      'downloaded_at': now.toIso8601String(),
    });
    await file.writeAsString(jsonEncode(items), flush: true);
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

class ClientVisitDownloadedFilesScreen extends StatefulWidget {
  final String userId;

  const ClientVisitDownloadedFilesScreen({super.key, required this.userId});

  @override
  State<ClientVisitDownloadedFilesScreen> createState() =>
      _ClientVisitDownloadedFilesScreenState();
}

class _ClientVisitDownloadedFilesScreenState
    extends State<ClientVisitDownloadedFilesScreen> {
  static const _filesChannel = MethodChannel('hrms/files');
  List<Map<String, dynamic>>? _files;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final files = await ClientVisitDownloads.load(widget.userId);
    if (mounted) setState(() => _files = files);
  }

  Future<void> _open(Map<String, dynamic> file) async {
    final uri = '${file['uri'] ?? ''}'.trim();
    if (uri.isEmpty) return;
    try {
      final opened = await _filesChannel.invokeMethod<bool>('openUrl', {
        'url': uri,
        'mimeType': '${file['mime_type'] ?? 'application/pdf'}',
      });
      if (opened != true && mounted) {
        _message('No PDF viewer is available on this device.');
      }
    } catch (_) {
      if (mounted) {
        _message('Unable to open this file. It may have been moved.');
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _date(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Saved';
    String two(int number) => number.toString().padLeft(2, '0');
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(hour)}:${two(date.minute)} $period';
  }

  @override
  Widget build(BuildContext context) {
    final files = _files;
    return ClientVisitTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Downloaded Files'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: files == null
              ? const Center(child: CircularProgressIndicator())
              : files.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No downloaded client visit reports yet.',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Downloaded PDFs will appear here automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: files.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final clientName = '${file['client_name'] ?? 'Client'}';
                      final reference = '${file['visit_reference'] ?? ''}';
                      return Card(
                        child: ListTile(
                          onTap: () => _open(file),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          title: Text(
                            clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              [
                                if (reference.isNotEmpty) reference,
                                _date('${file['downloaded_at'] ?? ''}'),
                                '${file['display_path'] ?? ''}',
                              ].join('\n'),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: const Icon(Icons.open_in_new_rounded),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
