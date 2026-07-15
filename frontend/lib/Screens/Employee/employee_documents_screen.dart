import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'employee_models.dart';
import 'employee_service.dart';
import 'employee_shared.dart';

class EmployeeDocumentsScreen extends StatefulWidget {
  final String userId;
  final EmployeeDashboardData data;
  final EmployeeService service;
  final Future<void> Function() onUploaded;

  const EmployeeDocumentsScreen({
    super.key,
    required this.userId,
    required this.data,
    required this.service,
    required this.onUploaded,
  });

  @override
  State<EmployeeDocumentsScreen> createState() =>
      _EmployeeDocumentsScreenState();
}

class _EmployeeDocumentsScreenState extends State<EmployeeDocumentsScreen> {
  static const MethodChannel _channel = MethodChannel('hrms/location');
  final ImagePicker _picker = ImagePicker();
  String? _uploadingKey;

  @override
  Widget build(BuildContext context) {
    final documents = widget.data.documents
        .where((item) => _hasDocumentUrl(item) || _needsCorrection(item))
        .toList();
    final correctionDocs = documents
        .where(_needsCorrection)
        .toList();
    return EmployeePage(
      title: 'Documents',
      action: IconButton(
        onPressed: correctionDocs.isEmpty
            ? null
            : () => _pickAndUpload(correctionDocs.first),
        icon: const Icon(Icons.upload_file_rounded, color: EmployeeColors.blue),
      ),
      children: [
        if (documents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'No uploaded registration documents found.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ...documents.map((item) => _documentTile(context, item)),
      ],
    );
  }

  Widget _documentTile(BuildContext context, Map<String, dynamic> item) {
    final status = '${item['status'] ?? 'uploaded'}'.toLowerCase();
    final documentKey = '${item['document_key'] ?? ''}';
    final canUpload = _needsCorrection(item);
    final isUploading = _uploadingKey == documentKey;
    final color = _statusColor(status);
    final remark = '${item['remark'] ?? ''}'.trim();
    final url = '${item['url'] ?? ''}'.trim();
    final canOpen = url.startsWith('http');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EmployeeListTile(
        icon: _statusIcon(status),
        title: '${item['title'] ?? 'Document'}',
        subtitle: remark.isEmpty ? _statusLabel(status) : remark,
        trailing: isUploading
            ? 'Uploading...'
            : canUpload
                ? 'Re-upload'
                : canOpen
                    ? 'View'
                    : _statusLabel(status),
        color: color,
        onTap: canUpload
            ? () => _pickAndUpload(item)
            : canOpen
                ? () => _openDocument(url)
                : null,
      ),
    );
  }

  bool _hasDocumentUrl(Map<String, dynamic> item) {
    final url = '${item['url'] ?? ''}'.trim();
    return url.isNotEmpty && url.toLowerCase() != 'null';
  }

  bool _needsCorrection(Map<String, dynamic> item) {
    final status = '${item['status'] ?? ''}'.toLowerCase();
    return status == 'flagged' || status == 'rejected';
  }

  Future<void> _openDocument(String url) async {
    try {
      final opened = await _channel.invokeMethod<bool>('openUrl', {'url': url});
      if (opened != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open document.')),
        );
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to open document.')),
      );
    }
  }

  Future<void> _pickAndUpload(Map<String, dynamic> item) async {
    final documentKey = '${item['document_key'] ?? ''}';
    if (documentKey.isEmpty || _uploadingKey != null) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingKey = documentKey);
    try {
      final result = await widget.service.reuploadDocument(
        widget.userId,
        documentKey,
        picked.path,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result['message'] ?? 'Document uploaded.'}')),
      );
      await widget.onUploaded();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _uploadingKey = null);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'flagged':
        return 'Flagged';
      case 'pending':
        return 'Pending Review';
      case 'rejected':
        return 'Rejected';
      case 'not_uploaded':
        return 'Not uploaded';
      default:
        return 'Uploaded';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.check_circle_rounded;
      case 'flagged':
        return Icons.flag_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'verified':
        return EmployeeColors.green;
      case 'flagged':
        return EmployeeColors.gold;
      case 'pending':
        return EmployeeColors.blue;
      case 'rejected':
        return EmployeeColors.red;
      default:
        return EmployeeColors.purple;
    }
  }
}
