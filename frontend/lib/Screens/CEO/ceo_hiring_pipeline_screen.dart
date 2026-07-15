import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoHiringPipelineScreen extends StatefulWidget {
  final String userId;
  const CeoHiringPipelineScreen({super.key, required this.userId});

  @override
  State<CeoHiringPipelineScreen> createState() => _CeoHiringPipelineScreenState();
}

class _CeoHiringPipelineScreenState extends State<CeoHiringPipelineScreen> {
  int _page = 0;
  bool _busy = false;
  String _query = '';
  int? _jobId;
  bool _myRequisitions = false;
  Map<String, dynamic>? _candidate;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() { super.initState(); _load(); }
  void _load() => _future = CeoService().fetchHiringPipeline(widget.userId);

  Future<void> _action(String action, Map<String, dynamic> fields) async {
    setState(() => _busy = true);
    final result = await CeoService().updateHiringPipeline(widget.userId, action, fields);
    if (!mounted) return;
    setState(() { _busy = false; if (result['success'] == true) _load(); });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${result['message'] ?? 'Unable to update hiring pipeline.'}'),
      backgroundColor: result['success'] == true ? CeoColors.green : Colors.redAccent,
    ));
  }

  void _go(int page, {Map<String, dynamic>? candidate}) => setState(() {
    _page = page;
    if (candidate != null) _candidate = candidate;
  });

  @override
  Widget build(BuildContext context) => CeoShell(
    title: _titles[_page],
    onBack: _page == 0 ? null : () => setState(() => _page--),
    trailing: PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, color: CeoColors.cyan),
      onSelected: (value) => setState(() => _page = value),
      itemBuilder: (_) => List.generate(_titles.length, (i) => PopupMenuItem(value: i, child: Text(_titles[i]))),
    ),
    bottomNavigationBar: _HiringBottomNav(
      selected: _page,
      onSelected: (value) => setState(() => _page = value),
    ),
    child: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: CeoColors.cyan));
        if (snapshot.hasError || snapshot.data?['success'] != true) return Center(child: OutlinedButton.icon(onPressed: () => setState(_load), icon: const Icon(Icons.refresh), label: const Text('Retry hiring data')));
        final data = snapshot.data!;
        return Stack(children: [
          Positioned.fill(child: switch (_page) { 1 => _jobs(data), 2 => _pipeline(data), 3 => _interview(data), 4 => _offer(data), _ => _dashboard(data) }),
          if (_busy) const Positioned.fill(child: ColoredBox(color: Color(0x77000000), child: Center(child: CircularProgressIndicator(color: CeoColors.cyan)))),
        ]);
      },
    ),
  );

  Widget _dashboard(Map<String, dynamic> data) {
    final summary = _map(data['summary']);
    final candidates = _maps(data['candidates']);
    return ListView(padding: const EdgeInsets.all(14), children: [
      title('Hello, CEO', 17), muted("Here's your recruitment overview", 10), const SizedBox(height: 14),
      CeoMetricGrid(cards: [
        CeoMetric('Total Openings', '${summary['openings'] ?? 0}', '', Icons.work_outline, CeoColors.cyan, onTap: () => _go(1)),
        CeoMetric('Applications', '${summary['applications'] ?? 0}', '', Icons.people_outline, CeoColors.green, onTap: () => _go(2)),
        CeoMetric('In Interviews', '${summary['interview'] ?? 0}', '', Icons.record_voice_over, CeoColors.purple, onTap: () => _go(3, candidate: _firstStage(candidates, 'interview'))),
        CeoMetric('Offers Extended', '${summary['offer'] ?? 0}', '', Icons.handshake_outlined, CeoColors.gold, onTap: () => _go(4, candidate: _firstStage(candidates, 'offer'))),
      ]),
      const SizedBox(height: 12), title('Hiring Funnel', 14), const SizedBox(height: 8),
      CeoCard(child: Column(children: ['applied', 'screening', 'interview', 'offer', 'hired'].asMap().entries.map((entry) => _funnelRow(entry.value, summary[entry.value], 1 - (entry.key * .16))).toList())),
      title('Recent Activity', 14), const SizedBox(height: 8),
      ...candidates.take(5).map((item) => _candidateTile(item)),
      FilledButton(onPressed: () => _go(1), child: const Text('View Job Openings')),
    ]);
  }

  Widget _jobs(Map<String, dynamic> data) {
    final jobs = _maps(data['jobs']).where((job) {
      final ownerMatch = !_myRequisitions || job['created_by'] == widget.userId;
      return ownerMatch && '${job['title']} ${job['department']}'.toLowerCase().contains(_query.toLowerCase());
    }).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 0), child: SegmentedButton<bool>(
        segments: const [ButtonSegment(value: false, label: Text('All Openings')), ButtonSegment(value: true, label: Text('My Requisitions'))],
        selected: {_myRequisitions}, onSelectionChanged: (value) => setState(() => _myRequisitions = value.first),
      )),
      Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Expanded(child: TextField(onChanged: (v) => setState(() => _query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search job title or department'))),
        const SizedBox(width: 8), IconButton.filled(onPressed: _createJob, icon: const Icon(Icons.add)),
      ])),
      Expanded(child: jobs.isEmpty ? Center(child: muted('No job openings from backend', 12)) : ListView(padding: const EdgeInsets.symmetric(horizontal: 14), children: jobs.map((job) => CeoCard(
        onTap: () => setState(() { _jobId = job['id'] as int?; _page = 2; }),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.business_center, color: CeoColors.cyan), const SizedBox(width: 9), Expanded(child: title('${job['title']}', 13)), _badge('${job['status']}', CeoColors.green)]),
          const SizedBox(height: 7), muted('${job['department']} • ${job['location']}', 9),
          const SizedBox(height: 8), Row(children: [muted('${job['applications']} Applied', 9), const Spacer(), muted('${job['in_progress']} In Progress', 9)]),
        ]),
      )).toList())),
    ]);
  }

  Widget _pipeline(Map<String, dynamic> data) {
    final jobs = _maps(data['jobs']);
    final candidates = _maps(data['candidates']).where((item) {
      final jobMatch = _jobId == null || item['job_id'] == _jobId;
      return jobMatch && '${item['name']} ${item['email']}'.toLowerCase().contains(_query.toLowerCase());
    }).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 5), child: DropdownButtonFormField<int?>(
        value: _jobId, decoration: const InputDecoration(labelText: 'Job Opening'), isExpanded: true,
        items: [const DropdownMenuItem<int?>(value: null, child: Text('All Openings')), ...jobs.map((job) => DropdownMenuItem<int?>(value: job['id'] as int?, child: Text('${job['title']}')))],
        onChanged: (value) => setState(() => _jobId = value),
      )),
      Padding(padding: const EdgeInsets.all(14), child: TextField(onChanged: (v) => setState(() => _query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search candidate'))),
      SizedBox(height: 74, child: ListView(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14),
        children: ['applied', 'screening', 'interview', 'offer', 'hired'].map((stage) => Container(
          width: 78, margin: const EdgeInsets.only(right: 7), padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: CeoColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: CeoColors.border)),
          child: Column(children: [title('${candidates.where((c) => c['stage'] == stage).length}', 16), muted(_label(stage), 8)]),
        )).toList(),
      )),
      Expanded(child: candidates.isEmpty ? Center(child: muted('No candidates from backend', 12)) : ListView(padding: const EdgeInsets.symmetric(horizontal: 14), children: [
        for (final stage in ['applied', 'screening', 'interview', 'offer', 'hired']) ...[
          title('${_label(stage)} (${candidates.where((c) => c['stage'] == stage).length})', 13), const SizedBox(height: 7),
          ...candidates.where((c) => c['stage'] == stage).map(_candidateTile), const SizedBox(height: 8),
        ],
      ])),
    ]);
  }

  Widget _candidateTile(Map<String, dynamic> item) => CeoCard(
    onTap: () => _go(item['stage'] == 'offer' || item['stage'] == 'hired' ? 4 : 3, candidate: item),
    child: Row(children: [
      CircleAvatar(backgroundColor: CeoColors.cardAlt, child: Text(_initials('${item['name']}'))), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('${item['name']}', 12), muted('${item['email']}', 9), muted('${item['job_title']}', 8)])),
      PopupMenuButton<String>(
        onSelected: (stage) => _action('move_stage', {'candidate_id': item['id'], 'stage': stage}),
        itemBuilder: (_) => ['screening', 'interview', 'offer', 'hired', 'rejected'].map((stage) => PopupMenuItem(value: stage, child: Text('Move to ${_label(stage)}'))).toList(),
        child: _badge(_label('${item['stage']}'), _stageColor('${item['stage']}')),
      ),
    ]),
  );

  Widget _interview(Map<String, dynamic> data) {
    final candidate = _resolveCandidate(data, preferredStage: 'interview');
    if (candidate == null) return Center(child: muted('Select an interview candidate from the pipeline', 12));
    final interview = _map(candidate['interview']);
    return ListView(padding: const EdgeInsets.all(14), children: [
      _profile(candidate),
      _stageTracker(interview['status'] == 'completed' ? 2 : interview['status'] == 'scheduled' ? 1 : 0),
      CeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        title('Interview Details', 14), const SizedBox(height: 9),
        _info('Scheduled', interview['scheduled_at']), _info('Mode', interview['mode']), _info('Interviewers', interview['interviewers']), _info('Status', interview['status']),
      ])),
      if ('${interview['scheduled_at'] ?? ''}'.isEmpty) FilledButton.icon(onPressed: () => _schedule(candidate), icon: const Icon(Icons.calendar_month), label: const Text('Schedule Interview')),
      if ('${interview['scheduled_at'] ?? ''}'.isNotEmpty) ...[
        CeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          title('Evaluation Form', 14), const SizedBox(height: 8),
          Row(children: [muted('Overall Rating', 10), const Spacer(), ...List.generate(5, (index) => Icon(index < (int.tryParse('${interview['rating']}') ?? 0) ? Icons.star : Icons.star_border, color: CeoColors.gold, size: 22))]),
          _info('Feedback', interview['feedback']),
        ])),
        FilledButton.icon(onPressed: () => _feedback(candidate), icon: const Icon(Icons.rate_review), label: const Text('Add Feedback')),
        OutlinedButton(onPressed: () => _go(4, candidate: candidate), child: const Text('Next: Offer & Onboarding')),
      ],
    ]);
  }

  Widget _offer(Map<String, dynamic> data) {
    final candidate = _resolveCandidate(data, preferredStage: 'offer');
    if (candidate == null) return Center(child: muted('Select a candidate for offer and onboarding', 12));
    final offer = _map(candidate['offer']);
    final checklist = _map(candidate['onboarding']);
    final keys = ['personal_information', 'document_submission', 'policy_acknowledgement', 'it_setup', 'orientation_schedule'];
    return ListView(padding: const EdgeInsets.all(14), children: [
      _profile(candidate),
      CeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('Offer Details', 14), _info('Status', offer['status']), _info('Annual CTC', offer['ctc']), _info('Employment Type', offer['employment_type']), _info('Location', offer['location']), _info('Joining Date', offer['joining_date'])])),
      if (offer.isEmpty) FilledButton.icon(onPressed: () => _extendOffer(candidate), icon: const Icon(Icons.send), label: const Text('Extend Offer')),
      if (offer.isNotEmpty) ...[
        _offerTimeline(candidate),
        if (offer['status'] == 'extended') FilledButton(onPressed: () => _action('offer_status', {'candidate_id': candidate['id'], 'status': 'accepted'}), child: const Text('Mark Offer Accepted')),
        if (offer['status'] == 'accepted') FilledButton(onPressed: () => _action('offer_status', {'candidate_id': candidate['id'], 'status': 'background_check'}), child: const Text('Start Background Check')),
        title('Onboarding Checklist', 14), const SizedBox(height: 6),
        CeoCard(child: Column(children: keys.map((key) => CheckboxListTile(
          value: checklist[key] == true, title: Text(_label(key)), contentPadding: EdgeInsets.zero,
          onChanged: (value) => _action('onboarding_check', {'candidate_id': candidate['id'], 'key': key, 'completed': value == true}),
        )).toList())),
      ],
    ]);
  }

  Map<String, dynamic>? _resolveCandidate(Map<String, dynamic> data, {required String preferredStage}) {
    final candidates = _maps(data['candidates']);
    if (_candidate != null) {
      final match = candidates.where((item) => item['id'] == _candidate!['id']);
      if (match.isNotEmpty) return match.first;
    }
    return _firstStage(candidates, preferredStage);
  }

  Future<void> _createJob() async {
    final values = await _fieldsDialog('Create Job Opening', ['title', 'department', 'location', 'openings']);
    if (values != null) await _action('create_job', values);
  }
  Future<void> _schedule(Map<String, dynamic> candidate) async {
    final values = await _fieldsDialog('Schedule Interview', ['scheduled_at', 'mode', 'interviewers']);
    if (values != null) await _action('schedule_interview', {'candidate_id': candidate['id'], ...values});
  }
  Future<void> _feedback(Map<String, dynamic> candidate) async {
    final values = await _fieldsDialog('Interview Feedback', ['rating', 'feedback']);
    if (values != null) await _action('feedback', {'candidate_id': candidate['id'], ...values});
  }
  Future<void> _extendOffer(Map<String, dynamic> candidate) async {
    final values = await _fieldsDialog('Extend Offer', ['ctc', 'employment_type', 'location', 'joining_date']);
    if (values != null) await _action('extend_offer', {'candidate_id': candidate['id'], ...values});
  }

  Future<Map<String, dynamic>?> _fieldsDialog(String titleText, List<String> fields) async {
    final controllers = {for (final field in fields) field: TextEditingController()};
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (context) => AlertDialog(
      title: Text(titleText), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: fields.map((field) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: controllers[field], decoration: InputDecoration(labelText: _label(field))))).toList())),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, {for (final entry in controllers.entries) entry.key: entry.value.text.trim()}), child: const Text('Save'))],
    ));
    for (final controller in controllers.values) controller.dispose();
    return result;
  }

  Widget _profile(Map<String, dynamic> candidate) => CeoCard(child: Row(children: [CircleAvatar(radius: 25, child: Text(_initials('${candidate['name']}'))), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('${candidate['name']}', 14), muted('${candidate['job_title']}', 10), muted('${candidate['email']}', 9)]))]));
  Widget _funnelRow(String stage, dynamic count, double width) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 72, child: muted(_label(stage), 9)),
      Expanded(child: Align(alignment: Alignment.center, child: FractionallySizedBox(
        widthFactor: width.clamp(.25, 1).toDouble(),
        child: Container(height: 22, decoration: BoxDecoration(color: _stageColor(stage), borderRadius: BorderRadius.circular(4))),
      ))),
      SizedBox(width: 35, child: Text('${count ?? 0}', textAlign: TextAlign.end)),
    ]),
  );
  Widget _stageTracker(int active) {
    const labels = ['Screening', 'Technical', 'HR Interview', 'Managerial', 'Decision'];
    return CeoCard(child: Row(children: labels.asMap().entries.map((entry) => Expanded(child: Column(children: [
      CircleAvatar(radius: 13, backgroundColor: entry.key <= active ? CeoColors.cyan : CeoColors.cardAlt, child: entry.key < active ? const Icon(Icons.check, size: 14) : Text('${entry.key + 1}', style: const TextStyle(fontSize: 9))),
      const SizedBox(height: 4), Text(entry.value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 7)),
    ]))).toList()));
  }
  Widget _offerTimeline(Map<String, dynamic> candidate) {
    final checklist = _map(candidate['onboarding']);
    final offer = _map(candidate['offer']);
    final offerStatus = '${offer['status'] ?? ''}';
    final hired = candidate['stage'] == 'hired';
    final completed = checklist.values.where((value) => value == true).length;
    final values = [
      ('Offered', offer.isNotEmpty),
      ('Accepted', {'accepted', 'background_check'}.contains(offerStatus) || hired),
      ('Background Check', offerStatus == 'background_check' || completed > 0 || hired),
      ('Onboarding', hired),
    ];
    return CeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      title('Offer Status', 14), const SizedBox(height: 12),
      Row(children: values.map((item) => Expanded(child: Column(children: [
        CircleAvatar(radius: 11, backgroundColor: item.$2 ? CeoColors.green : CeoColors.cardAlt, child: Icon(item.$2 ? Icons.check : Icons.circle_outlined, size: 13, color: Colors.white)),
        const SizedBox(height: 5), Text(item.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8)),
      ]))).toList()),
    ]));
  }
  Widget _info(String label, dynamic value) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 110, child: muted(label, 10)), Expanded(child: Text('${value ?? '-'}'))]));
  Widget _badge(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(5)), child: Text(text, style: TextStyle(color: color, fontSize: 9)));
  static Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : {};
  static List<Map<String, dynamic>> _maps(dynamic value) => value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
  static Map<String, dynamic>? _firstStage(List<Map<String, dynamic>> items, String stage) { final match = items.where((item) => item['stage'] == stage); return match.isEmpty ? null : match.first; }
  static double _ratio(dynamic value, dynamic total) { final maximum = double.tryParse('$total') ?? 0; return maximum == 0 ? 0 : ((double.tryParse('$value') ?? 0) / maximum).clamp(0, 1).toDouble(); }
  static String _initials(String name) => name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase();
  static String _label(String value) => value.replaceAll('_', ' ').split(' ').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');
  static Color _stageColor(String stage) => switch (stage) { 'hired' => CeoColors.green, 'offer' => CeoColors.gold, 'interview' => CeoColors.purple, 'rejected' => Colors.redAccent, _ => CeoColors.cyan };
  static const _titles = ['Recruitment Dashboard', 'Job Openings', 'Candidate Pipeline', 'Interview & Evaluation', 'Offer & Onboarding'];
}

class _HiringBottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  const _HiringBottomNav({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.dashboard_outlined, 'Dashboard'),
      (Icons.work_outline, 'Jobs'),
      (Icons.account_tree_outlined, 'Pipeline'),
      (Icons.calendar_month_outlined, 'Calendar'),
      (Icons.person_outline, 'Profile'),
    ];
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: onSelected,
      destinations: items.map((item) => NavigationDestination(icon: Icon(item.$1), label: item.$2)).toList(),
    );
  }
}
