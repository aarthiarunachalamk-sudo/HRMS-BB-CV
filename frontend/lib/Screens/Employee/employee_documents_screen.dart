import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';

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
  static const MethodChannel _filesChannel = MethodChannel('hrms/files');
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

    const acceptedFiles = XTypeGroup(
      label: 'Images and documents',
      extensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc'],
      mimeTypes: [
        'image/jpeg',
        'image/png',
        'application/pdf',
        'application/msword',
      ],
    );
    final file = await openFile(acceptedTypeGroups: [acceptedFiles]);
    if (file == null || !mounted) return;

    var filePath = file.path;
    var fileName = file.name;
    var extension = _extensionOf(fileName).toLowerCase();
    const imageExtensions = {'jpg', 'jpeg', 'png'};
    const documentExtensions = {'pdf', 'doc'};
    final fileType = imageExtensions.contains(extension)
        ? 'image'
        : documentExtensions.contains(extension)
        ? 'document'
        : '';

    if (filePath.isEmpty || fileType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid file. Select an image (JPG, JPEG, PNG) or document (PDF, DOC).',
          ),
        ),
      );
      return;
    }

    if (documentKey == 'doc_passport_photo' && fileType != 'image') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passport Size Photo must be a JPG, JPEG, or PNG image.'),
        ),
      );
      return;
    }

    if (fileType == 'image') {
      final cropped = await ImageCropper().cropImage(
        sourcePath: filePath,
        compressFormat: extension == 'png'
            ? ImageCompressFormat.png
            : ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Document',
            toolbarColor: EmployeeColors.blue,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Document'),
        ],
      );
      if (!mounted) return;
      if (cropped != null) {
        filePath = cropped.path;
        extension = _extensionOf(filePath).toLowerCase();
        fileName =
            'cropped_document_${DateTime.now().millisecondsSinceEpoch}.$extension';
      }
    }

    setState(() => _uploadingKey = documentKey);
    try {
      final result = await widget.service.reuploadDocument(
        widget.userId,
        documentKey,
        filePath,
        fileType,
      );
      if (!mounted) return;
      String? localLocation;
      String? localSaveError;
      try {
        localLocation = await _saveOnMobile(filePath, fileName, extension);
      } catch (_) {
        localSaveError = 'Uploaded to HRMS, but the mobile copy could not be saved.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localSaveError ??
                '${result['message'] ?? 'Document uploaded.'} Saved on mobile: $localLocation',
          ),
        ),
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

  Future<String> _saveOnMobile(
    String sourcePath,
    String originalName,
    String extension,
  ) async {
    final safeName = _safeFileName(originalName, extension);
    if (Platform.isAndroid) {
      final saved = await _filesChannel.invokeMethod<String>(
        'saveToDownloads',
        {
          'fileName': safeName,
          'mimeType': _mimeType(extension),
          'bytes': await File(sourcePath).readAsBytes(),
        },
      );
      return saved ?? 'Downloads/BitByte HRMS/$safeName';
    }

    final appDocuments = await getApplicationDocumentsDirectory();
    final employeeFolder = Directory(
      '${appDocuments.path}${Platform.pathSeparator}BitByte HRMS${Platform.pathSeparator}Employee Documents',
    );
    await employeeFolder.create(recursive: true);
    final destination = File(
      '${employeeFolder.path}${Platform.pathSeparator}$safeName',
    );
    await File(sourcePath).copy(destination.path);
    return destination.path;
  }

  String _safeFileName(String originalName, String extension) {
    final cleaned = originalName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final fallback =
        'employee_document_${DateTime.now().millisecondsSinceEpoch}.$extension';
    return cleaned.isEmpty ? fallback : cleaned;
  }

  String _mimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }

  String _extensionOf(String fileName) {
    final separator = fileName.lastIndexOf('.');
    return separator < 0 ? '' : fileName.substring(separator + 1);
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
