import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'add_employees.dart';

class HrDocumentVerificationFlowScreen extends StatefulWidget {
  final Map<String, dynamic> employee;
  final int initialIndex;

  const HrDocumentVerificationFlowScreen({
    super.key,
    required this.employee,
    this.initialIndex = 0,
  });

  @override
  State<HrDocumentVerificationFlowScreen> createState() =>
      _HrDocumentVerificationFlowScreenState();
}

class _HrDocumentVerificationFlowScreenState
    extends State<HrDocumentVerificationFlowScreen> {
  int _index = 0;

  Map<String, dynamic> get employee => widget.employee;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex < 0
        ? 0
        : widget.initialIndex >= _flowTitles.length
            ? _flowTitles.length - 1
            : widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _VerificationDashboardPage(
        employee: employee,
        open: _setIndex,
        verify: () => _verifyEmployeeRegistration(context, employee),
        reject: () => _rejectEmployeeRegistration(context, employee),
      ),
      _EmployeeInfoPage(employee: employee),
      _DocumentsFlowPage(
        employee: employee,
        verify: () => _verifyEmployeeRegistration(context, employee),
        reject: () => _rejectEmployeeRegistration(context, employee),
      ),
      _RoleProcessPage(employee: employee),
      _ReviewHistoryFlowPage(employee: employee),
      _VerificationProfilePage(employee: employee),
    ];

    return _HrFlowScaffold(
      title: _flowTitles[_index],
      status: _employeeStatus(employee),
      index: _index,
      onSelect: _setIndex,
      child: pages[_index],
    );
  }

  void _setIndex(int value) {
    setState(() => _index = value);
  }
}

class _VerificationDashboardPage extends StatelessWidget {
  final Map<String, dynamic> employee;
  final ValueChanged<int> open;
  final VoidCallback verify;
  final VoidCallback reject;

  const _VerificationDashboardPage({
    required this.employee,
    required this.open,
    required this.verify,
    required this.reject,
  });

  @override
  Widget build(BuildContext context) {
    final docs = _verificationDocs(employee);
    final uploadedDocs = docs
        .where((doc) => doc.status != HrDocumentStatus.notUploaded)
        .length;
    final flaggedDocs =
        docs.where((doc) => doc.status == HrDocumentStatus.flagged).length;
    return _FlowList(
      children: [
        _EmployeeHeader(employee: employee),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.36,
          children: [
            _FlowMetric(
              title: 'Uploaded Docs',
              value: '$uploadedDocs/${docs.length}',
              icon: Icons.folder_copy_rounded,
              color: _HrDocColors.primary,
              onTap: () => open(2),
            ),
            _FlowMetric(
              title: 'Flagged',
              value: '$flaggedDocs',
              icon: Icons.flag_rounded,
              color: _HrDocColors.warning,
              onTap: () => open(2),
            ),
            _FlowMetric(
              title: 'Role Process',
              value: _approvalOwner(employee),
              icon: Icons.account_tree_rounded,
              color: _HrDocColors.success,
              onTap: () => open(3),
            ),
            _FlowMetric(
              title: 'History',
              value: '4 logs',
              icon: Icons.history_rounded,
              color: _HrDocColors.muted,
              onTap: () => open(4),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _RoleProcessCard(employee: employee),
        const SizedBox(height: 14),
        _InfoCard(
          children: [
            const Text(
              'Verification Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Verify',
                    icon: Icons.verified_rounded,
                    color: _HrDocColors.success,
                    onTap: verify,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    color: _HrDocColors.danger,
                    onTap: reject,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DocumentsFlowPage extends StatefulWidget {
  final Map<String, dynamic> employee;
  final VoidCallback verify;
  final VoidCallback reject;

  const _DocumentsFlowPage({
    required this.employee,
    required this.verify,
    required this.reject,
  });

  @override
  State<_DocumentsFlowPage> createState() => _DocumentsFlowPageState();
}

class _DocumentsFlowPageState extends State<_DocumentsFlowPage> {
  @override
  Widget build(BuildContext context) {
    final docs = _verificationDocs(widget.employee);
    return _FlowList(
      children: [
        _EmployeeHeader(employee: widget.employee),
        const SizedBox(height: 12),
        _DocumentSection(
          title: 'Mandatory Documents',
          progress: '4/4',
          employee: widget.employee,
          docs: docs.where((doc) => doc.group == _DocGroup.mandatory).toList(),
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 14),
        _DocumentSection(
          title: 'Educational Documents',
          progress: '4/4',
          employee: widget.employee,
          docs:
              docs.where((doc) => doc.group == _DocGroup.educational).toList(),
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 14),
        _DocumentSection(
          title: 'Optional Documents',
          progress: '0/3',
          progressColor: _HrDocColors.warning,
          employee: widget.employee,
          docs: docs.where((doc) => doc.group == _DocGroup.optional).toList(),
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Verify All',
                icon: Icons.check_rounded,
                color: _HrDocColors.success,
                onTap: widget.verify,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Reject All',
                icon: Icons.close_rounded,
                color: _HrDocColors.danger,
                onTap: widget.reject,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmployeeInfoPage extends StatelessWidget {
  final Map<String, dynamic> employee;

  const _EmployeeInfoPage({required this.employee});

  @override
  Widget build(BuildContext context) {
    return _FlowList(
      children: [
        _EmployeeHeader(employee: employee),
        const SizedBox(height: 14),
        _InfoCard(
          children: [
            _InfoLine(label: 'Employee ID', value: _employeeCode(employee)),
            const SizedBox(height: 12),
            _InfoLine(label: 'Role', value: _employeeRole(employee)),
            const SizedBox(height: 12),
            _InfoLine(label: 'Department', value: _employeeDepartment(employee)),
            const SizedBox(height: 12),
            _InfoLine(label: 'Email', value: _employeeEmail(employee)),
            const SizedBox(height: 12),
            _InfoLine(label: 'Status', value: _employeeStatus(employee)),
          ],
        ),
        const SizedBox(height: 14),
        _RoleProcessCard(employee: employee),
      ],
    );
  }
}

class _RoleProcessPage extends StatelessWidget {
  final Map<String, dynamic> employee;

  const _RoleProcessPage({required this.employee});

  @override
  Widget build(BuildContext context) {
    return _FlowList(
      children: [
        _RoleProcessCard(employee: employee),
        const SizedBox(height: 14),
        _InfoCard(
          children: [
            const Text(
              'Role Based Review',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ..._roleStages(employee).map((stage) => _RoleStageTile(stage)),
          ],
        ),
      ],
    );
  }
}

class _ReviewHistoryFlowPage extends StatelessWidget {
  final Map<String, dynamic> employee;

  const _ReviewHistoryFlowPage({required this.employee});

  @override
  Widget build(BuildContext context) {
    final history = _documentHistory(employee);
    return _FlowList(
      children: [
        _SelectBox(
          value: 'All Documents',
          items: const ['All Documents', 'Verified', 'Flagged', 'Rejected'],
          onChanged: (_) {},
        ),
        const SizedBox(height: 18),
        if (history.isEmpty)
          const _EmptyText('No document review history yet.'),
        ...history.map((item) => _HistoryTile(
              title: '${item['document_title'] ?? item['document_key'] ?? 'Document'}',
              status: _statusFromText('${item['status'] ?? ''}'),
              time: _formatHistoryTime('${item['created_at'] ?? ''}'),
            )),
      ],
    );
  }
}

class _VerificationProfilePage extends StatelessWidget {
  final Map<String, dynamic> employee;

  const _VerificationProfilePage({required this.employee});

  @override
  Widget build(BuildContext context) {
    return _FlowList(
      children: [
        _EmployeeHeader(employee: employee),
        const SizedBox(height: 14),
        _InfoCard(
          children: [
            _ProfileRow(Icons.person_rounded, 'Personal Information'),
            _ProfileRow(Icons.business_rounded, _employeeDepartment(employee)),
            _ProfileRow(Icons.badge_rounded, _employeeRole(employee)),
            _ProfileRow(Icons.mail_rounded, _employeeEmail(employee)),
            _ProfileRow(
              Icons.logout_rounded,
              'Close Verification',
              danger: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}

class HrDocumentPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> employee;
  final HrVerificationDoc document;

  const HrDocumentPreviewScreen({
    super.key,
    required this.employee,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final text = ThemeConfig.getTextPrimary(context);
    return _HrDarkShell(
      title: document.title,
      trailing: _StatusBadge(
        document.status.label.toUpperCase(),
        document.status.color,
      ),
      child: Column(
        children: [
          _InfoCard(
            children: [
              _InfoLine(
                label: 'Document Status',
                value: document.status.label,
                valueColor: document.status.color,
                icon: document.status.icon,
              ),
              const SizedBox(height: 12),
              Text(
                document.status == HrDocumentStatus.flagged
                    ? 'Flagged on 21 May 2024 by Priya HR'
                    : 'Verified on 20 May 2024 by Priya HR',
                style: const TextStyle(color: _HrDocColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DocumentPreviewCard(document: document, employee: employee),
          const SizedBox(height: 14),
          if (document.status == HrDocumentStatus.flagged)
            _InfoCard(
              children: [
                const Text(
                  'Flag Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  label: 'Reason',
                  value: '${document.review['issue_type'] ?? 'Document issue'}',
                  valueColor: _HrDocColors.warning,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Remark: ${document.review['remark'] ?? 'Please re-upload the correct document.'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Flag Details'),
                            content: Text('${document.review['remark'] ?? 'Please re-upload the correct document.'}'),
                          ),
                        );
                      },
                      child: const Text('View More'),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Verify',
                  icon: Icons.check_rounded,
                  color: _HrDocColors.success,
                  onTap: () async {
                    final saved = await _submitDocumentAction(
                      context,
                      employee,
                      document,
                      'verify',
                    );
                    if (saved && context.mounted) Navigator.of(context).pop(true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Flag Issue',
                  icon: Icons.flag_rounded,
                  color: _HrDocColors.warning,
                  outlined: true,
                  onTap: () async {
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => HrFlagDocumentIssueScreen(
                          employee: employee,
                          document: document,
                        ),
                      ),
                    );
                    if (saved == true && context.mounted) Navigator.of(context).pop(true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Reject',
                  icon: Icons.close_rounded,
                  color: _HrDocColors.danger,
                  onTap: () async {
                    final saved = await _submitDocumentAction(
                      context,
                      employee,
                      document,
                      'reject',
                    );
                    if (saved && context.mounted) Navigator.of(context).pop(true);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _HrDocColors.border),
          const SizedBox(height: 8),
          const _PreviewToolbar(),
        ],
      ),
    );
  }
}

class HrFlagDocumentIssueScreen extends StatefulWidget {
  final Map<String, dynamic> employee;
  final HrVerificationDoc document;

  const HrFlagDocumentIssueScreen({
    super.key,
    required this.employee,
    required this.document,
  });

  @override
  State<HrFlagDocumentIssueScreen> createState() =>
      _HrFlagDocumentIssueScreenState();
}

class _HrFlagDocumentIssueScreenState
    extends State<HrFlagDocumentIssueScreen> {
  String _issueType = 'Name mismatch';
  String _priority = 'Medium';
  String _suggestedAction = 'Re-upload the correct document';
  final _remarkCtrl = TextEditingController(
    text: 'Entered name is Arun Kumar, but document name is A. Kumar.',
  );

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = ThemeConfig.getTextPrimary(context);
    return _HrDarkShell(
      title: 'Flag Document Issue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            children: [
              const Text(
                'Document',
                style: TextStyle(color: _HrDocColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.document.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FieldLabel('Issue Type *'),
          _SelectBox(
            value: _issueType,
            items: const [
              'Name mismatch',
              'Blurry document',
              'Wrong document',
              'Expired document',
              'Details not visible',
            ],
            onChanged: (value) => setState(() => _issueType = value),
          ),
          const SizedBox(height: 16),
          _FieldLabel('HR Remark *'),
          TextField(
            controller: _remarkCtrl,
            maxLines: 4,
            maxLength: 250,
            style: TextStyle(color: text),
            decoration: _fieldDecoration(context, 'Enter HR remark'),
          ),
          const SizedBox(height: 8),
          const _FieldLabel('Suggested Action for Employee'),
          ...[
            'Re-upload the correct document',
            'Upload additional document',
            'Edit entered information',
          ].map(
            (item) => RadioListTile<String>(
              value: item,
              groupValue: _suggestedAction,
              activeColor: _HrDocColors.primary,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                item,
                style: TextStyle(color: text, fontSize: 13),
              ),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _suggestedAction = value);
              },
            ),
          ),
          const SizedBox(height: 10),
          _FieldLabel('Priority'),
          _SelectBox(
            value: _priority,
            items: const ['Low', 'Medium', 'High'],
            onChanged: (value) => setState(() => _priority = value),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _HrDocColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _HrDocColors.primary.withAlpha(130)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: _HrDocColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This flagged document will be sent back to the employee for correction.',
                    style: TextStyle(color: _HrDocColors.primary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Cancel',
                  icon: Icons.close_rounded,
                  color: _HrDocColors.muted,
                  outlined: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _ActionButton(
                  label: 'Send Correction Request',
                  icon: Icons.send_rounded,
                  color: _HrDocColors.primary,
                  onTap: () async {
                    final saved = await _submitDocumentAction(
                      context,
                      widget.employee,
                      widget.document,
                      'flag',
                      issueType: _issueType,
                      remark: _remarkCtrl.text.trim(),
                      suggestedAction: _suggestedAction,
                      priority: _priority,
                    );
                    if (saved && context.mounted) Navigator.of(context).pop(true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HrDocumentReviewHistoryScreen extends StatelessWidget {
  final Map<String, dynamic> employee;

  const HrDocumentReviewHistoryScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final history = _documentHistory(employee);
    return _HrDarkShell(
      title: 'Review History',
      child: Column(
        children: [
          _Tabs(active: 'Review History', employee: employee),
          const SizedBox(height: 18),
          _SelectBox(
            value: 'All Documents',
            items: const ['All Documents', 'Verified', 'Flagged', 'Rejected'],
            onChanged: (_) {},
          ),
          const SizedBox(height: 18),
          if (history.isEmpty)
            const _EmptyText('No document review history yet.'),
          ...history.map((item) {
            final status = _statusFromText('${item['status'] ?? ''}');
            return _HistoryTile(
              title: '${item['document_title'] ?? item['document_key'] ?? 'Document'}',
              status: status,
              time: _formatHistoryTime('${item['created_at'] ?? ''}'),
            );
          }),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _documentHistory(Map<String, dynamic> employee) {
  return (employee['document_review_history'] is List
          ? employee['document_review_history'] as List
          : const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

HrDocumentStatus _statusFromText(String value) {
  final status = value.toLowerCase();
  if (status == 'verified') return HrDocumentStatus.verified;
  if (status == 'flagged') return HrDocumentStatus.flagged;
  if (status == 'rejected') return HrDocumentStatus.rejected;
  if (status == 'pending') return HrDocumentStatus.pending;
  return HrDocumentStatus.pending;
}

String _formatHistoryTime(String value) {
  if (value.trim().isEmpty) return 'Just now';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} ${two(parsed.hour)}:${two(parsed.minute)}';
}

enum _DocGroup { mandatory, educational, optional }

enum HrDocumentStatus {
  verified('Verified', Icons.check_circle_rounded, _HrDocColors.success),
  flagged('Flagged', Icons.flag_rounded, _HrDocColors.warning),
  pending('Pending Review', Icons.schedule_rounded, _HrDocColors.primary),
  rejected('Rejected', Icons.cancel_rounded, _HrDocColors.danger),
  notUploaded('Not uploaded', Icons.upload_file_rounded, _HrDocColors.muted);

  final String label;
  final IconData icon;
  final Color color;

  const HrDocumentStatus(this.label, this.icon, this.color);
}

class HrVerificationDoc {
  final String key;
  final String title;
  final String url;
  final _DocGroup group;
  final HrDocumentStatus status;
  final Map<String, dynamic> review;

  const HrVerificationDoc({
    required this.key,
    required this.title,
    required this.url,
    required this.group,
    required this.status,
    this.review = const {},
  });
}

List<HrVerificationDoc> _verificationDocs(Map<String, dynamic> employee) {
  String value(String key) => '${employee[key] ?? ''}';
  final statuses = Map<String, dynamic>.from(
    employee['document_statuses'] is Map
        ? employee['document_statuses'] as Map
        : const {},
  );
  HrDocumentStatus statusFor(String key, String url) {
    final review = statuses[key] is Map
        ? Map<String, dynamic>.from(statuses[key] as Map)
        : const <String, dynamic>{};
    final status = '${review['status'] ?? ''}'.toLowerCase();
    if (status == 'verified') return HrDocumentStatus.verified;
    if (status == 'flagged') return HrDocumentStatus.flagged;
    if (status == 'pending') return HrDocumentStatus.pending;
    if (status == 'rejected') return HrDocumentStatus.rejected;
    return url.trim().isEmpty
        ? HrDocumentStatus.notUploaded
        : HrDocumentStatus.pending;
  }

  Map<String, dynamic> reviewFor(String key) => statuses[key] is Map
      ? Map<String, dynamic>.from(statuses[key] as Map)
      : const {};

  return [
    HrVerificationDoc(
      key: 'doc_passport_photo',
      title: 'Passport Size Photo',
      url: value('doc_passport_photo'),
      group: _DocGroup.mandatory,
      status: statusFor('doc_passport_photo', value('doc_passport_photo')),
      review: reviewFor('doc_passport_photo'),
    ),
    HrVerificationDoc(
      key: 'doc_aadhar',
      title: 'Aadhaar Card Copy',
      url: value('doc_aadhar'),
      group: _DocGroup.mandatory,
      status: statusFor('doc_aadhar', value('doc_aadhar')),
      review: reviewFor('doc_aadhar'),
    ),
    HrVerificationDoc(
      key: 'doc_pan',
      title: 'PAN Card Copy',
      url: value('doc_pan'),
      group: _DocGroup.mandatory,
      status: statusFor('doc_pan', value('doc_pan')),
      review: reviewFor('doc_pan'),
    ),
    HrVerificationDoc(
      key: 'doc_bank_passbook',
      title: 'Bank Passbook',
      url: value('doc_bank_passbook'),
      group: _DocGroup.mandatory,
      status: statusFor('doc_bank_passbook', value('doc_bank_passbook')),
      review: reviewFor('doc_bank_passbook'),
    ),
    HrVerificationDoc(
      key: 'doc_10th',
      title: '10th Marksheet',
      url: value('doc_10th'),
      group: _DocGroup.educational,
      status: statusFor('doc_10th', value('doc_10th')),
      review: reviewFor('doc_10th'),
    ),
    HrVerificationDoc(
      key: 'doc_12th',
      title: '12th / Diploma',
      url: value('doc_12th'),
      group: _DocGroup.educational,
      status: statusFor('doc_12th', value('doc_12th')),
      review: reviewFor('doc_12th'),
    ),
    HrVerificationDoc(
      key: 'doc_degree',
      title: 'Degree Certificate',
      url: value('doc_degree'),
      group: _DocGroup.educational,
      status: statusFor('doc_degree', value('doc_degree')),
      review: reviewFor('doc_degree'),
    ),
    HrVerificationDoc(
      key: 'doc_consolidated',
      title: 'Consolidated Marksheet',
      url: value('doc_consolidated'),
      group: _DocGroup.educational,
      status: statusFor('doc_consolidated', value('doc_consolidated')),
      review: reviewFor('doc_consolidated'),
    ),
    HrVerificationDoc(
      key: 'doc_college_noc',
      title: 'NOC Certificate from College',
      url: value('doc_college_noc'),
      group: _DocGroup.educational,
      status: statusFor('doc_college_noc', value('doc_college_noc')),
      review: reviewFor('doc_college_noc'),
    ),
    HrVerificationDoc(
      key: 'doc_passport_copy',
      title: 'Passport Copy',
      url: value('doc_passport_copy'),
      group: _DocGroup.optional,
      status: statusFor('doc_passport_copy', value('doc_passport_copy')),
      review: reviewFor('doc_passport_copy'),
    ),
    HrVerificationDoc(
      key: 'doc_driving',
      title: 'Driving License Copy',
      url: value('doc_driving'),
      group: _DocGroup.optional,
      status: statusFor('doc_driving', value('doc_driving')),
      review: reviewFor('doc_driving'),
    ),
    HrVerificationDoc(
      key: 'doc_vaccination',
      title: 'Vaccination Certificate',
      url: value('doc_vaccination'),
      group: _DocGroup.optional,
      status: statusFor('doc_vaccination', value('doc_vaccination')),
      review: reviewFor('doc_vaccination'),
    ),
  ];
}

Future<void> _verifyEmployeeRegistration(
  BuildContext context,
  Map<String, dynamic> employee,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AddEmployeePage(
        employee: employee,
      ),
    ),
  );
}

Future<void> _rejectEmployeeRegistration(
  BuildContext context,
  Map<String, dynamic> employee,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: _HrDocColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        'Reject Employee?',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: const Text(
        'This will reject the employee registration and complete the HR verification flow.',
        style: TextStyle(color: _HrDocColors.muted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(
            'Reject',
            style: TextStyle(
              color: _HrDocColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final response = await http.post(
      ApiConfig.uri('/reject-employee/${employee['id']}/'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = jsonDecode(response.body);
    if (!context.mounted) return;
    if (data['success'] == true) {
      employee['status'] = 'rejected';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Employee rejected.'),
          backgroundColor: _HrDocColors.danger,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Unable to reject employee.'),
          backgroundColor: _HrDocColors.danger,
        ),
      );
    }
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: _HrDocColors.danger,
      ),
    );
  }
}

Future<bool> _submitDocumentAction(
  BuildContext context,
  Map<String, dynamic> employee,
  HrVerificationDoc document,
  String action, {
  String issueType = '',
  String remark = '',
  String suggestedAction = '',
  String priority = '',
}) async {
  try {
    final response = await http.post(
      ApiConfig.uri('/registered-employees/${employee['id']}/documents/action/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'document_key': document.key,
        'action': action,
        'issue_type': issueType,
        'remark': remark,
        'suggested_action': suggestedAction,
        'priority': priority,
      }),
    );
    final data = jsonDecode(response.body);
    if (!context.mounted) return false;
    if (data['success'] == true) {
      if (data['employee'] is Map) {
        employee
          ..clear()
          ..addAll(Map<String, dynamic>.from(data['employee'] as Map));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['message'] ?? 'Document updated.'}'),
          backgroundColor: action == 'reject'
              ? _HrDocColors.danger
              : action == 'flag'
                  ? _HrDocColors.warning
                  : _HrDocColors.success,
        ),
      );
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data['message'] ?? 'Unable to update document.'}'),
        backgroundColor: _HrDocColors.danger,
      ),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: _HrDocColors.danger,
        ),
      );
    }
  }
  return false;
}

class _HrDarkShell extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _HrDarkShell({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bg = ThemeConfig.getBgStart(context);
    final text = ThemeConfig.getTextPrimary(context);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Row(
                children: [
                  _IconBox(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _flowTitles = [
  'Verification',
  'Employee Details',
  'Documents',
  'Role Process',
  'Review History',
  'Profile',
];

class _HrFlowScaffold extends StatelessWidget {
  final String title;
  final String status;
  final int index;
  final ValueChanged<int> onSelect;
  final Widget child;

  const _HrFlowScaffold({
    required this.title,
    required this.status,
    required this.index,
    required this.onSelect,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bg = ThemeConfig.getBgStart(context);
    final text = ThemeConfig.getTextPrimary(context);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Row(
                children: [
                  _IconBox(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusBadge(
                    status.toUpperCase(),
                    _statusColor(status),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
            _HrFlowBottomNav(index: index, onSelect: onSelect),
          ],
        ),
      ),
    );
  }
}

class _FlowList extends StatelessWidget {
  final List<Widget> children;

  const _FlowList({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      children: children,
    );
  }
}

class _HrFlowBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _HrFlowBottomNav({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final bg = ThemeConfig.getBgEnd(context);
    final border = ThemeConfig.getCardBorder(context);
    final items = [
      (Icons.dashboard_rounded, 'Dashboard'),
      (Icons.person_rounded, 'Details'),
      (Icons.description_rounded, 'Docs'),
      (Icons.account_tree_rounded, 'Process'),
      (Icons.history_rounded, 'History'),
      (Icons.account_circle_rounded, 'Profile'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final selected = i == index;
          return Expanded(
            child: InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.$1,
                      color: selected ? _HrDocColors.primary : _HrDocColors.muted,
                      size: 20,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? _HrDocColors.primary : _HrDocColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FlowMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FlowMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = ThemeConfig.getTextPrimary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: _InfoCard(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleProcessCard extends StatelessWidget {
  final Map<String, dynamic> employee;

  const _RoleProcessCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    final text = ThemeConfig.getTextPrimary(context);
    final stages = _roleStages(employee);
    return _InfoCard(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Role Based Process',
                style: TextStyle(
                  color: text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _SmallPill(_approvalOwner(employee), _HrDocColors.primary),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(stages.length, (index) {
            final stage = stages[index];
            return Expanded(
              child: Row(
                children: [
                  Expanded(child: _StageDot(stage)),
                  if (index != stages.length - 1)
                    Container(width: 18, height: 2, color: _HrDocColors.border),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StageDot extends StatelessWidget {
  final _RoleStage stage;

  const _StageDot(this.stage);

  @override
  Widget build(BuildContext context) {
    final muted = ThemeConfig.getTextSecondary(context);
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: stage.color.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(color: stage.color.withAlpha(170)),
          ),
          child: Icon(stage.icon, color: stage.color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          stage.role,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RoleStageTile extends StatelessWidget {
  final _RoleStage stage;

  const _RoleStageTile(this.stage);

  @override
  Widget build(BuildContext context) {
    final text = ThemeConfig.getTextPrimary(context);
    final muted = ThemeConfig.getTextSecondary(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: stage.color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stage.icon, color: stage.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.role,
                  style: TextStyle(
                    color: text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stage.note,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _SmallPill(stage.status, stage.color),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool danger;
  final VoidCallback? onTap;

  const _ProfileRow(
    this.icon,
    this.text, {
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _HrDocColors.danger : _HrDocColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: danger ? _HrDocColors.danger : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withAlpha(170)),
          ],
        ),
      ),
    );
  }
}

class _RoleStage {
  final String role;
  final String status;
  final String note;
  final IconData icon;
  final Color color;

  const _RoleStage({
    required this.role,
    required this.status,
    required this.note,
    required this.icon,
    required this.color,
  });
}

List<_RoleStage> _roleStages(Map<String, dynamic> employee) {
  final status = _employeeStatus(employee).toLowerCase();
  final verified = status == 'approved' || status == 'verified';
  final rejected = status == 'rejected';
  return [
    const _RoleStage(
      role: 'Employee',
      status: 'Submitted',
      note: 'Registration and documents submitted.',
      icon: Icons.person_rounded,
      color: _HrDocColors.success,
    ),
    _RoleStage(
      role: 'TL',
      status: rejected ? 'Stopped' : 'Checked',
      note: rejected
          ? 'Team lead review stops after rejection.'
          : 'Team lead level employee check is complete.',
      icon: rejected ? Icons.cancel_rounded : Icons.groups_rounded,
      color: rejected ? _HrDocColors.danger : _HrDocColors.success,
    ),
    _RoleStage(
      role: 'HR',
      status: rejected ? 'Rejected' : verified ? 'Verified' : 'Pending',
      note: rejected
          ? 'HR rejected this registration.'
          : verified
              ? 'HR completed employee verification.'
              : 'HR should verify employee details and documents.',
      icon: rejected ? Icons.cancel_rounded : Icons.verified_user_rounded,
      color: rejected
          ? _HrDocColors.danger
          : verified
              ? _HrDocColors.success
              : _HrDocColors.warning,
    ),
    _RoleStage(
      role: 'Complete',
      status: verified ? 'Done' : 'Waiting',
      note: verified
          ? 'Verified employee is active in the dashboard.'
          : 'Completion happens after HR verification.',
      icon: Icons.task_alt_rounded,
      color: verified ? _HrDocColors.primary : _HrDocColors.muted,
    ),
  ];
}

String _employeeStatus(Map<String, dynamic> employee) {
  final status = '${employee['status'] ?? employee['verification_status'] ?? 'Pending'}';
  return status.trim().isEmpty ? 'Pending' : status;
}

String _employeeCode(Map<String, dynamic> employee) {
  final value = '${employee['employee_id'] ?? employee['id'] ?? 'EMP00125'}';
  return value.trim().isEmpty ? 'EMP00125' : value;
}

String _employeeRole(Map<String, dynamic> employee) {
  final value = '${employee['role'] ?? employee['designation'] ?? 'Employee'}';
  return value.trim().isEmpty ? 'Employee' : value;
}

String _employeeDepartment(Map<String, dynamic> employee) {
  final value = '${employee['department'] ?? 'Department not assigned'}';
  return value.trim().isEmpty ? 'Department not assigned' : value;
}

String _employeeEmail(Map<String, dynamic> employee) {
  final value = '${employee['email'] ?? employee['personal_email'] ?? '--'}';
  return value.trim().isEmpty ? '--' : value;
}

String _approvalOwner(Map<String, dynamic> employee) {
  final status = _employeeStatus(employee).toLowerCase();
  if (status == 'approved' || status == 'verified') return 'Complete';
  if (status == 'rejected') return 'Closed';
  return 'HR Review';
}

Color _statusColor(String status) {
  final value = status.toLowerCase();
  if (value == 'approved' || value == 'verified') return _HrDocColors.success;
  if (value == 'rejected') return _HrDocColors.danger;
  if (value.contains('flag')) return _HrDocColors.warning;
  return _HrDocColors.warning;
}

class _EmployeeHeader extends StatelessWidget {
  final Map<String, dynamic> employee;

  const _EmployeeHeader({required this.employee});

  @override
  Widget build(BuildContext context) {
    final first = '${employee['first_name'] ?? 'Arun'}';
    final last = '${employee['last_name'] ?? 'Kumar'}';
    final initials = '${first.isEmpty ? 'A' : first[0]}${last.isEmpty ? '' : last[0]}'.toUpperCase();
    final photoUrl = '${employee['doc_passport_photo'] ?? ''}'.trim();

    Widget avatar;
    if (photoUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 34,
        backgroundColor: _HrDocColors.primary.withAlpha(55),
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, __) {},
      );
    } else {
      avatar = CircleAvatar(
        radius: 34,
        backgroundColor: _HrDocColors.primary.withAlpha(55),
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return _InfoCard(
      children: [
        Row(
          children: [
            avatar,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$first $last',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${employee['employee_id'] ?? 'EMP00125'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${employee['designation'] ?? 'Software Developer'}',
                    style: const TextStyle(color: _HrDocColors.primary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  final String active;
  final Map<String, dynamic> employee;

  const _Tabs({required this.active, required this.employee});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Employee Info', 'Documents', 'Review History'];
    return Row(
      children: tabs.map((tab) {
        final selected = tab == active;
        return Expanded(
          child: InkWell(
            onTap: selected
                ? null
                : () {
                    if (tab == 'Documents') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HrDocumentVerificationFlowScreen(
                            employee: employee,
                            initialIndex: 2,
                          ),
                        ),
                      );
                    } else if (tab == 'Employee Info') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HrDocumentVerificationFlowScreen(
                            employee: employee,
                            initialIndex: 1,
                          ),
                        ),
                      );
                    } else if (tab == 'Review History') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HrDocumentVerificationFlowScreen(
                            employee: employee,
                            initialIndex: 4,
                          ),
                        ),
                      );
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tab,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : _HrDocColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DocumentSection extends StatelessWidget {
  final String title;
  final String progress;
  final Color progressColor;
  final Map<String, dynamic> employee;
  final List<HrVerificationDoc> docs;
  final VoidCallback? onChanged;

  const _DocumentSection({
    required this.title,
    required this.progress,
    required this.employee,
    required this.docs,
    this.progressColor = _HrDocColors.primary,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _SmallPill(progress, progressColor),
          ],
        ),
        const SizedBox(height: 12),
        ...docs.map(
          (doc) => _DocumentTile(
            doc: doc,
            employee: employee,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final HrVerificationDoc doc;
  final Map<String, dynamic> employee;
  final VoidCallback? onChanged;

  const _DocumentTile({
    required this.doc,
    required this.employee,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasDoc = doc.status != HrDocumentStatus.notUploaded && doc.url.isNotEmpty;
    return InkWell(
      onTap: hasDoc
          ? () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => HrDocumentPreviewScreen(
                    employee: employee,
                    document: doc,
                  ),
                ),
              );
              if (changed == true) onChanged?.call();
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _DocThumb(doc: doc),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(doc.status.icon, color: doc.status.color, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        doc.status.label,
                        style: TextStyle(
                          color: doc.status.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _ViewButton(enabled: hasDoc),
          ],
        ),
      ),
    );
  }
}

class _DocumentPreviewCard extends StatelessWidget {
  final HrVerificationDoc document;
  final Map<String, dynamic> employee;

  const _DocumentPreviewCard({required this.document, required this.employee});

  @override
  Widget build(BuildContext context) {
    if (document.url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          document.url,
          height: 245,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _MockAadhaar(employee: employee),
        ),
      );
    }
    return _MockAadhaar(employee: employee);
  }
}

class _MockAadhaar extends StatelessWidget {
  final Map<String, dynamic> employee;

  const _MockAadhaar({required this.employee});

  @override
  Widget build(BuildContext context) {
    final name = '${employee['first_name'] ?? 'Arun'} ${employee['last_name'] ?? 'Kumar'}';
    return Container(
      width: double.infinity,
      height: 245,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_rounded, color: Colors.black87),
              Spacer(),
              Text(
                'AADHAAR',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 86,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.black54, size: 48),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('DOB: 15/08/1995', style: TextStyle(color: Colors.black87)),
                    const Text('Male', style: TextStyle(color: Colors.black87)),
                    const SizedBox(height: 18),
                    const Text(
                      'XXXX XXXX 5678',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.qr_code_2_rounded, color: Colors.black, size: 72),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String title;
  final HrDocumentStatus status;
  final String time;

  const _HistoryTile({
    required this.title,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(status.icon, color: status.color, size: 24),
              Container(width: 1, height: 48, color: _HrDocColors.border),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InfoCard(
              padding: const EdgeInsets.all(14),
              children: [
                Text(time, style: const TextStyle(color: _HrDocColors.muted, fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      'View >',
                      style: TextStyle(
                        color: status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  status.label,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text('by Priya HR', style: TextStyle(color: _HrDocColors.muted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;

  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _HrDocColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PreviewToolbar extends StatelessWidget {
  const _PreviewToolbar();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.zoom_in_rounded, 'Zoom In'),
      (Icons.zoom_out_rounded, 'Zoom Out'),
      (Icons.fit_screen_rounded, 'Fit'),
      (Icons.refresh_rounded, 'Rotate'),
      (Icons.download_rounded, 'Download'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map(
            (item) => Column(
              children: [
                Icon(item.$1, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  item.$2,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const _InfoCard({
    required this.children,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;

  const _InfoLine({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final muted = ThemeConfig.getTextSecondary(context);
    final text = ThemeConfig.getTextPrimary(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ),
        if (icon != null) ...[
          Icon(icon, color: valueColor, size: 16),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor == Colors.white ? text : valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectBox extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _SelectBox({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final text = ThemeConfig.getTextPrimary(context);
    final muted = ThemeConfig.getTextSecondary(context);
    return AppDropdownButtonFormField<String>(
      value: value,
      dropdownColor: cardBg,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: muted),
      style: TextStyle(color: text, fontSize: 13),
      decoration: _fieldDecoration(context, ''),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (next) {
        if (next == null) return;
        onChanged(next);
      },
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context, String hint) {
  final isDark = ThemeConfig.isDark(context);
  final muted = ThemeConfig.getTextSecondary(context);
  final fill = isDark ? _HrDocColors.bgAlt : const Color(0xFFF1F5F9);
  final border = ThemeConfig.getCardBorder(context);
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: muted, fontSize: 12),
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _HrDocColors.primary),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          backgroundColor: outlined ? Colors.transparent : color.withAlpha(28),
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color.withAlpha(outlined ? 150 : 95)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  final bool enabled;

  const _ViewButton({required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? _HrDocColors.primary : _HrDocColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withAlpha(180)),
      ),
      child: Icon(
        enabled ? Icons.visibility_rounded : Icons.upload_file_rounded,
        color: color,
        size: 18,
      ),
    );
  }
}

class _DocThumb extends StatelessWidget {
  final HrVerificationDoc doc;

  const _DocThumb({required this.doc});

  @override
  Widget build(BuildContext context) {
    if (doc.url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.network(
          doc.url,
          width: 42,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbFallback(),
        ),
      );
    }
    return _thumbFallback();
  }

  Widget _thumbFallback() {
    return Container(
      width: 42,
      height: 52,
      decoration: BoxDecoration(
        color: _HrDocColors.bgAlt,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _HrDocColors.border),
      ),
      child: Icon(doc.status.icon, color: doc.status.color, size: 22),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallPill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBox({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = ThemeConfig.getCardBg(context);
    final border = ThemeConfig.getCardBorder(context);
    final text = ThemeConfig.getTextPrimary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Icon(icon, color: text, size: 18),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final muted = ThemeConfig.getTextSecondary(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HrDocColors {
  static const bg = Color(0xFF020D1A);
  static const bgAlt = Color(0xFF061B2D);
  static const surface = Color(0xFF0A2034);
  static const border = Color(0xFF1D3E58);
  static const primary = Color(0xFF0072FF);
  static const success = Color(0xFF08D967);
  static const danger = Color(0xFFFF3B4F);
  static const warning = Color(0xFFF59E0B);
  static const muted = Color(0xFF91A4B8);
}
