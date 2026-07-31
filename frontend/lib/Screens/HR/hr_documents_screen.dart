import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';

import 'hr_service.dart';
import 'hr_shared.dart';

class HrDocumentsScreen extends StatefulWidget {
  final String userId;

  const HrDocumentsScreen({super.key, required this.userId});

  @override
  State<HrDocumentsScreen> createState() => _HrDocumentsScreenState();
}

class _HrDocumentsScreenState extends State<HrDocumentsScreen> {
  static const MethodChannel _platformChannel = MethodChannel('hrms/location');
  final HrService _service = HrService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _documents = const [];
  Map<String, dynamic> _counts = const {};
  Timer? _searchDebounce;
  bool _loading = true;
  bool _uploading = false;
  String _status = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await _service.fetchDocuments(
        widget.userId,
        query: _searchController.text,
        status: _status,
      );
      final rawDocuments = response['documents'];
      final rawCounts = response['counts'];
      if (!mounted) return;
      setState(() {
        _documents = rawDocuments is List
            ? rawDocuments
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : const [];
        _counts = rawCounts is Map
            ? Map<String, dynamic>.from(rawCounts)
            : const {};
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadDocuments(showLoader: false),
    );
  }

  Future<void> _startUpload() async {
    if (_uploading) return;
    final draft = await showModalBottomSheet<_HrDocumentDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HrDocumentUploadSheet(),
    );
    if (draft == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final response = await _service.uploadDocument(
        widget.userId,
        filePath: draft.file.path,
        documentType: draft.documentType,
        ownerUserId: draft.ownerUserId,
        ownerRole: draft.ownerRole,
        documentNumber: draft.documentNumber,
        expiryDate: draft.expiryDate,
        remarks: draft.remarks,
      );
      await _loadDocuments(showLoader: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${response['message'] ?? 'Document uploaded successfully.'}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(_errorText(error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openDocument(Map<String, dynamic> document) async {
    final url = '${document['file_url'] ?? ''}'.trim();
    if (!url.startsWith('http')) {
      _showError('This document does not have an accessible file.');
      return;
    }
    try {
      final opened = await _platformChannel.invokeMethod<bool>('openUrl', {
        'url': url,
      });
      if (opened != true && mounted) {
        _showError('Unable to open this document.');
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _showError(error.message ?? 'Unable to open this document.');
      }
    }
  }

  Future<void> _showDocumentActions(Map<String, dynamic> document) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HrDocumentActionsSheet(document: document),
    );
    if (action == null || !mounted) return;
    if (action == 'view') {
      await _openDocument(document);
      return;
    }
    if (action == 'delete') {
      await _confirmDelete(document);
      return;
    }
    if (action.startsWith('status:')) {
      await _updateStatus(document, action.substring(7));
    }
  }

  Future<void> _updateStatus(
    Map<String, dynamic> document,
    String status,
  ) async {
    final id = _intValue(document['id']);
    if (id == null) return;
    try {
      await _service.updateDocumentStatus(
        widget.userId,
        id,
        status,
        remarks: '${document['remarks'] ?? ''}',
      );
      await _loadDocuments(showLoader: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document status updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (mounted) _showError(_errorText(error));
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
          '“${document['title'] ?? 'Document'}” and its uploaded file will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final id = _intValue(document['id']);
    if (id == null) return;
    try {
      await _service.deleteDocument(widget.userId, id);
      await _loadDocuments(showLoader: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (mounted) _showError(_errorText(error));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: HrPalette.of(context).danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _loadDocuments(showLoader: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppLayout.pagePadding,
            children: [
              _header(c),
              const SizedBox(height: 14),
              _summary(c),
              const SizedBox(height: 14),
              _searchAndFilters(c),
              const SizedBox(height: 14),
              if (_loading)
                const _HrDocumentsLoading()
              else if (_error != null)
                _errorState(c)
              else if (_documents.isEmpty)
                _emptyState(c)
              else
                ..._documents.map(
                  (document) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _documentCard(c, document),
                  ),
                ),
              const SizedBox(height: 90),
            ],
          ),
        ),
        if (_uploading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withAlpha(90),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: HrCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Uploading document…',
                            style: TextStyle(
                              color: c.text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Keep this screen open until the upload completes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _header(HrPalette c) {
    return HrCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_copy_rounded,
                  color: c.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document center',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Upload, review and maintain HR records',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _uploading ? null : _startUpload,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('Upload document'),
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(HrPalette c) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total',
            value: '${_counts['total'] ?? _documents.length}',
            icon: Icons.description_rounded,
            color: c.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Pending',
            value: '${_counts['pending'] ?? 0}',
            icon: Icons.schedule_rounded,
            color: c.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Verified',
            value: '${_counts['verified'] ?? 0}',
            icon: Icons.verified_rounded,
            color: c.success,
          ),
        ),
      ],
    );
  }

  Widget _searchAndFilters(HrPalette c) {
    const filters = <String, String>{
      '': 'All',
      'pending': 'Pending',
      'verified': 'Verified',
      'rejected': 'Rejected',
      'expired': 'Expired',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search title, employee ID or document number',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      _loadDocuments(showLoader: false);
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: c.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.entries.map((entry) {
              final selected = _status == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected,
                  label: Text(entry.value),
                  onSelected: (_) {
                    setState(() => _status = entry.key);
                    _loadDocuments(showLoader: false);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _documentCard(HrPalette c, Map<String, dynamic> document) {
    final status = '${document['status'] ?? 'pending'}'.toLowerCase();
    final statusColor = _statusColor(c, status);
    final owner = '${document['owner_name'] ?? document['owner_user_id'] ?? ''}'
        .trim();
    final fileName = '${document['file_name'] ?? ''}'.trim();
    final subtitle = [
      if (owner.isNotEmpty) owner,
      if (fileName.isNotEmpty) fileName,
    ].join('  •  ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDocumentActions(document),
        child: HrCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_fileIcon(fileName), color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${document['title'] ?? 'Document'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusPill(
                          label: _statusLabel(status),
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateLabel('${document['uploaded_at'] ?? ''}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.muted, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert_rounded, color: c.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(HrPalette c) {
    final filtered =
        _searchController.text.trim().isNotEmpty || _status.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          Icon(
            filtered ? Icons.search_off_rounded : Icons.folder_open_rounded,
            color: c.muted,
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(
            filtered ? 'No matching documents' : 'No documents uploaded',
            style: TextStyle(
              color: c.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? 'Try a different search or status filter.'
                : 'Upload the first HR document to start the repository.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontSize: 12),
          ),
          if (!filtered) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _startUpload,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add first document'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorState(HrPalette c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: c.danger, size: 48),
          const SizedBox(height: 12),
          Text(
            'Couldn’t load documents',
            style: TextStyle(
              color: c.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _loadDocuments,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _HrDocumentUploadSheet extends StatefulWidget {
  const _HrDocumentUploadSheet();

  @override
  State<_HrDocumentUploadSheet> createState() => _HrDocumentUploadSheetState();
}

class _HrDocumentUploadSheetState extends State<_HrDocumentUploadSheet> {
  static const int _maxBytes = 10 * 1024 * 1024;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController(
    text: 'COMPANY',
  );
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  XFile? _file;
  int _fileSize = 0;
  String _ownerRole = 'company';
  DateTime? _expiryDate;
  String? _fileError;

  @override
  void dispose() {
    _titleController.dispose();
    _ownerController.dispose();
    _numberController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    const acceptedFiles = XTypeGroup(
      label: 'HR documents',
      extensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      mimeTypes: [
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'image/jpeg',
        'image/png',
      ],
    );
    final file = await openFile(acceptedTypeGroups: [acceptedFiles]);
    if (file == null || !mounted) return;
    final size = await file.length();
    if (!mounted) return;
    setState(() {
      _file = size <= _maxBytes ? file : null;
      _fileSize = size;
      _fileError = size > _maxBytes
          ? 'The selected file is larger than 10 MB.'
          : null;
      if (_titleController.text.trim().isEmpty && size <= _maxBytes) {
        _titleController.text = _titleFromFileName(file.name);
      }
    });
  }

  Future<void> _pickExpiryDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 36500)),
    );
    if (selected != null && mounted) setState(() => _expiryDate = selected);
  }

  void _submit() {
    setState(
      () => _fileError = _file == null ? 'Choose a file to upload.' : null,
    );
    if (!_formKey.currentState!.validate() || _file == null) return;
    Navigator.of(context).pop(
      _HrDocumentDraft(
        file: _file!,
        documentType: _titleController.text.trim(),
        ownerUserId: _ownerController.text.trim(),
        ownerRole: _ownerRole,
        documentNumber: _numberController.text.trim(),
        expiryDate: _expiryDate == null
            ? ''
            : '${_expiryDate!.year.toString().padLeft(4, '0')}-'
                  '${_expiryDate!.month.toString().padLeft(2, '0')}-'
                  '${_expiryDate!.day.toString().padLeft(2, '0')}',
        remarks: _remarksController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.6,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload document',
                          style: TextStyle(
                            color: c.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Add the file and its ownership metadata',
                          style: TextStyle(color: c.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _FilePickerCard(
                file: _file,
                fileSize: _fileSize,
                error: _fileError,
                onPick: _pickFile,
                onClear: () => setState(() {
                  _file = null;
                  _fileSize = 0;
                  _fileError = null;
                }),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Document title *',
                  hintText: 'e.g. Employment Contract',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a document title.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _ownerRole,
                decoration: const InputDecoration(
                  labelText: 'Document owner',
                  prefixIcon: Icon(Icons.account_circle_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'company', child: Text('Company')),
                  DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(value: 'hr', child: Text('HR')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _ownerRole = value;
                    if (value == 'company') {
                      _ownerController.text = 'COMPANY';
                    } else if (_ownerController.text == 'COMPANY') {
                      _ownerController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: _ownerRole == 'company'
                      ? 'Owner ID'
                      : 'Employee / user ID *',
                  hintText: _ownerRole == 'company' ? 'COMPANY' : 'BBEMP00001',
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the owner ID.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Document number (optional)',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickExpiryDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry date (optional)',
                    prefixIcon: const Icon(Icons.event_outlined),
                    suffixIcon: _expiryDate == null
                        ? const Icon(Icons.chevron_right_rounded)
                        : IconButton(
                            tooltip: 'Clear expiry date',
                            onPressed: () => setState(() => _expiryDate = null),
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  child: Text(
                    _expiryDate == null
                        ? 'No expiry date'
                        : '${_expiryDate!.day.toString().padLeft(2, '0')}/'
                              '${_expiryDate!.month.toString().padLeft(2, '0')}/'
                              '${_expiryDate!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarksController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('Upload document'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Accepted: PDF, DOC, DOCX, JPG, JPEG, PNG • Maximum 10 MB',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilePickerCard extends StatelessWidget {
  final XFile? file;
  final int fileSize;
  final String? error;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _FilePickerCard({
    required this.file,
    required this.fileSize,
    required this.error,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final hasFile = file != null;
    final borderColor = error != null
        ? c.danger
        : hasFile
        ? c.success
        : c.border;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: borderColor.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: borderColor.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasFile ? _fileIcon(file!.name) : Icons.upload_file_rounded,
                color: borderColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile ? file!.name : 'Choose a file *',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    error ??
                        (hasFile
                            ? _formatBytes(fileSize)
                            : 'Tap to browse files on this device'),
                    style: TextStyle(
                      color: error == null ? c.muted : c.danger,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile)
              IconButton(
                tooltip: 'Remove file',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              )
            else
              Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _HrDocumentActionsSheet extends StatelessWidget {
  final Map<String, dynamic> document;

  const _HrDocumentActionsSheet({required this.document});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final fileName = '${document['file_name'] ?? ''}'.trim();
    final status = '${document['status'] ?? 'pending'}'.toLowerCase();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(_fileIcon(fileName), color: c.primary, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${document['title'] ?? 'Document'}',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${document['owner_name'] ?? document['owner_user_id'] ?? ''}',
                      style: TextStyle(color: c.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if ('${document['file_url'] ?? ''}'.startsWith('http'))
            _ActionTile(
              icon: Icons.open_in_new_rounded,
              title: 'Open document',
              color: c.primary,
              onTap: () => Navigator.pop(context, 'view'),
            ),
          if (status != 'verified')
            _ActionTile(
              icon: Icons.verified_rounded,
              title: 'Mark as verified',
              color: c.success,
              onTap: () => Navigator.pop(context, 'status:verified'),
            ),
          if (status != 'rejected')
            _ActionTile(
              icon: Icons.cancel_rounded,
              title: 'Mark as rejected',
              color: c.warning,
              onTap: () => Navigator.pop(context, 'status:rejected'),
            ),
          if (status != 'pending')
            _ActionTile(
              icon: Icons.schedule_rounded,
              title: 'Move back to pending',
              color: c.primary,
              onTap: () => Navigator.pop(context, 'status:pending'),
            ),
          _ActionTile(
            icon: Icons.delete_outline_rounded,
            title: 'Delete document',
            color: c.danger,
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return HrCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: c.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HrDocumentsLoading extends StatelessWidget {
  const _HrDocumentsLoading();

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: HrCard(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.border.withAlpha(100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 10, width: 150, color: c.border),
                      const SizedBox(height: 8),
                      Container(height: 8, width: 210, color: c.border),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HrDocumentDraft {
  final XFile file;
  final String documentType;
  final String ownerUserId;
  final String ownerRole;
  final String documentNumber;
  final String expiryDate;
  final String remarks;

  const _HrDocumentDraft({
    required this.file,
    required this.documentType,
    required this.ownerUserId,
    required this.ownerRole,
    required this.documentNumber,
    required this.expiryDate,
    required this.remarks,
  });
}

IconData _fileIcon(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  if (extension == 'pdf') return Icons.picture_as_pdf_rounded;
  if (extension == 'doc' || extension == 'docx') {
    return Icons.article_rounded;
  }
  if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
    return Icons.image_rounded;
  }
  return Icons.description_rounded;
}

Color _statusColor(HrPalette c, String status) {
  switch (status) {
    case 'verified':
      return c.success;
    case 'rejected':
      return c.danger;
    case 'expired':
      return c.purple;
    default:
      return c.warning;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'verified':
      return 'Verified';
    case 'rejected':
      return 'Rejected';
    case 'expired':
      return 'Expired';
    default:
      return 'Pending review';
  }
}

String _dateLabel(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _titleFromFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final withoutExtension = dot > 0 ? fileName.substring(0, dot) : fileName;
  final words = withoutExtension
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'));
  return words
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

int? _intValue(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value');
}

String _errorText(Object error) =>
    '$error'.replaceFirst('Exception: ', '').trim();
