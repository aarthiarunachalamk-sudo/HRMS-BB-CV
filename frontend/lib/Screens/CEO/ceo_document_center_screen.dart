import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ceo_local_documents.dart';
import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoDocumentCenterScreen extends StatefulWidget {
  final String userId;
  const CeoDocumentCenterScreen({super.key, required this.userId});

  @override
  State<CeoDocumentCenterScreen> createState() => _CeoDocumentCenterScreenState();
}

class _CeoDocumentCenterScreenState extends State<CeoDocumentCenterScreen> {
  static const _channel = MethodChannel('hrms/files');
  late Future<Map<String, dynamic>> _future;
  String _category = 'All';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = _fetchDocuments();

  Future<Map<String, dynamic>> _fetchDocuments() async {
    final local = await CeoLocalDocuments.load(widget.userId);
    try {
      final remote = await CeoService().fetchDocuments(widget.userId);
      final documents = <Map<String, dynamic>>[
        ...local,
        ..._maps(remote['documents']),
      ];
      final categories = <String>{
        ..._maps(remote['categories']).map((item) => '${item['name']}'),
        ...local.map((item) => '${item['category'] ?? ''}'),
        ...local.map((item) => '${item['direction'] ?? ''}'),
      }..removeWhere((item) => item.trim().isEmpty);
      return {
        ...remote,
        'success': true,
        'documents': documents,
        'categories': categories.map((name) => {'name': name}).toList(),
      };
    } catch (_) {
      final categories = local
          .map((item) => '${item['category'] ?? ''}')
          .where((item) => item.trim().isNotEmpty)
          .toSet();
      return {
        'success': true,
        'documents': local,
        'categories': categories.map((name) => {'name': name}).toList(),
      };
    }
  }

  Future<void> _open(Map<String, dynamic> document) async {
    final url = '${document['url'] ?? ''}'.trim();
    if (url.isEmpty) return;
    try {
      final opened = await _channel.invokeMethod<bool>('openUrl', {
        'url': url,
        'mimeType': _mimeType('${document['extension'] ?? ''}'),
      });
      if (opened != true && mounted) _message('Unable to open this document.');
    } on PlatformException catch (error) {
      if (mounted) _message(error.message ?? 'Unable to open this document.');
    }
  }

  String _mimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(value)),
  );

  void _details(Map<String, dynamic> document) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title('${document['title'] ?? 'Document'}', 17),
              const SizedBox(height: 14),
              _row('Category', document['category']),
              _row('Owner', document['owner']),
              _row('Employee ID', document['employee_id']),
              _row('Status', document['status']),
              _row('File type', '${document['extension'] ?? ''}'.toUpperCase()),
              _row('Storage path', document['storage_path']),
              _row('Saved at', document['created_at']),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _open(document);
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Document'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: '${document['url']}'));
                    if (context.mounted) Navigator.pop(context);
                    if (mounted) _message('Document link copied.');
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Copy Document Link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    final text = '${value ?? ''}'.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 105, child: muted(label, 10)),
        Expanded(child: Text(text.isEmpty ? 'Not available' : text)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => CeoShell(
    title: 'Document Center',
    trailing: IconButton(
      onPressed: () => setState(_load),
      icon: const Icon(Icons.refresh, color: CeoColors.cyan),
    ),
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: CeoColors.cyan));
        }
        if (snapshot.hasError || snapshot.data?['success'] != true) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            muted('Unable to load saved documents', 12),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: () => setState(_load), icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ]));
        }
        final data = snapshot.data!;
        final all = _maps(data['documents']);
        final categoryNames = <String>{
          ..._maps(data['categories']).map((item) => '${item['name']}'),
          'Saved',
          'Sent',
          'Received',
        }.where((item) => item.trim().isNotEmpty).toList();
        final filtered = all.where((document) {
          final matchesCategory = _category == 'All' ||
              document['category'] == _category ||
              document['status'] == _category ||
              document['direction'] == _category;
          final text = '${document['title']} ${document['owner']} ${document['employee_id']} ${document['status']} ${document['storage_path']}'.toLowerCase();
          return matchesCategory && text.contains(_query.toLowerCase());
        }).toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search document, employee, or status'),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: ['All', ...categoryNames].map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 5, 14, 8),
            child: Row(children: [
              title('${filtered.length} Documents', 13),
              const Spacer(),
              muted('Live saved files', 9),
            ]),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: muted('No saved documents match this filter', 12))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final document = filtered[index];
                      final extension = '${document['extension']}'.toLowerCase();
                      final isPdf = extension == 'pdf';
                      return CeoCard(
                        onTap: () => _details(document),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (isPdf ? Colors.redAccent : CeoColors.cyan).withAlpha(28),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(isPdf ? Icons.picture_as_pdf : Icons.description, color: isPdf ? Colors.redAccent : CeoColors.cyan),
                          ),
                          const SizedBox(width: 11),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            title('${document['title']}', 12),
                            if ('${document['storage_path'] ?? ''}'.trim().isNotEmpty)
                              muted('${document['storage_path']}', 8),
                            const SizedBox(height: 3),
                            muted('${document['owner']} • ${document['category']}', 9),
                            muted('${document['status']} • ${extension.isEmpty ? 'FILE' : extension.toUpperCase()}', 8),
                          ])),
                          IconButton(onPressed: () => _open(document), tooltip: 'View document', icon: const Icon(Icons.visibility, color: CeoColors.cyan)),
                        ]),
                      );
                    },
                  ),
          ),
        ]);
      },
    ),
  );

  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
      : [];
}
