import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoProjectsFlowScreen extends StatefulWidget {
  final String userId;
  const CeoProjectsFlowScreen({super.key, required this.userId});
  @override State<CeoProjectsFlowScreen> createState() => _CeoProjectsFlowScreenState();
}

class _CeoProjectsFlowScreenState extends State<CeoProjectsFlowScreen> {
  int _page = 0; bool _busy = false; String _query = ''; String _filter = 'all'; bool _tasksTab = false;
  Map<String, dynamic>? _project; late Future<Map<String, dynamic>> _future;
  @override void initState() { super.initState(); _load(); }
  void _load() => _future = CeoService().fetchProjectsFlow(widget.userId);
  Future<void> _action(String action, Map<String, dynamic> fields) async {
    setState(() => _busy = true);
    final result = await CeoService().updateProjectsFlow(widget.userId, action, fields);
    if (!mounted) return;
    setState(() { _busy = false; if (result['success'] == true) { if (result['project'] is Map) _project = Map<String, dynamic>.from(result['project']); _load(); } });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['message'] ?? 'Unable to update project.'}'), backgroundColor: result['success'] == true ? CeoColors.green : Colors.redAccent));
  }
  void _open(Map<String, dynamic> project, [int page = 2]) => setState(() { _project = project; _page = page; });

  @override Widget build(BuildContext context) => CeoShell(
    title: _titles[_page], onBack: _page == 0 ? null : () => setState(() => _page--),
    trailing: _page == 1 ? IconButton(onPressed: _createProject, icon: const Icon(Icons.add, color: CeoColors.cyan)) : null,
    bottomNavigationBar: NavigationBar(selectedIndex: _page == 0 ? 0 : 3, onDestinationSelected: (i) { if (i == 0) setState(() => _page = 0); }, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'), NavigationDestination(icon: Icon(Icons.people_outline), label: 'People'), NavigationDestination(icon: Icon(Icons.approval_outlined), label: 'Approvals'), NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More')]),
    child: FutureBuilder<Map<String, dynamic>>(future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: CeoColors.cyan));
      if (snapshot.hasError || snapshot.data?['success'] != true) return Center(child: OutlinedButton.icon(onPressed: () => setState(_load), icon: const Icon(Icons.refresh), label: const Text('Retry projects')));
      final data = snapshot.data!; final current = _resolve(data);
      return Stack(children: [Positioned.fill(child: switch (_page) { 1 => _list(data), 2 => _details(current), 3 => _teamTasks(current), 4 => _progress(current), _ => _dashboard(data) }), if (_busy) const Positioned.fill(child: ColoredBox(color: Color(0x77000000), child: Center(child: CircularProgressIndicator(color: CeoColors.cyan))))]);
    }),
  );

  Widget _dashboard(Map<String, dynamic> data) { final s = _map(data['summary']); final projects = _maps(data['projects']); return ListView(padding: const EdgeInsets.all(14), children: [
    title('Good morning, CEO', 17), muted("Here's an overview of your projects", 10), const SizedBox(height: 14),
    CeoMetricGrid(cards: [CeoMetric('Total Projects', '${s['total'] ?? 0}', '', Icons.folder_copy_outlined, CeoColors.cyan, onTap: () => setState(() => _page = 1)), CeoMetric('Active Projects', '${s['active'] ?? 0}', '', Icons.folder_open, CeoColors.cyan, onTap: () => setState(() { _filter = 'in_progress'; _page = 1; })), CeoMetric('On Track', '${(int.tryParse('${s['active']}') ?? 0) - (int.tryParse('${s['at_risk']}') ?? 0)}', '', Icons.check_circle_outline, CeoColors.green), CeoMetric('At Risk', '${s['at_risk'] ?? 0}', '', Icons.warning_amber, Colors.deepOrange)]),
    const SizedBox(height: 12), CeoCard(child: Column(children: [title('Overall Progress', 14), const SizedBox(height: 12), SizedBox(width: 105, height: 105, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: _num(s['average_progress']) / 100, strokeWidth: 13, color: CeoColors.cyan, backgroundColor: CeoColors.border), title('${s['average_progress'] ?? 0}%', 18)]))])),
    Row(children: [Expanded(child: title('Recent Projects', 14)), TextButton(onPressed: () => setState(() => _page = 1), child: const Text('View all'))]), ...projects.take(4).map(_projectCard),
  ]); }

  Widget _list(Map<String, dynamic> data) { final all = _maps(data['projects']); final list = all.where((p) { final status = '${p['status']}'; return (_filter == 'all' || status == _filter) && '${p['name']} ${p['department']} ${p['code']}'.toLowerCase().contains(_query.toLowerCase()); }).toList(); return Column(children: [
    Padding(padding: const EdgeInsets.all(14), child: TextField(onChanged: (v) => setState(() => _query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search projects...'))),
    SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), children: ['all', 'in_progress', 'completed', 'on_hold'].map((f) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(_label(f)), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)))).toList())),
    Expanded(child: list.isEmpty ? Center(child: muted('No projects from backend', 12)) : ListView(padding: const EdgeInsets.all(14), children: list.map(_projectCard).toList())),
  ]); }
  Widget _projectCard(Map<String, dynamic> p) => CeoCard(onTap: () => _open(p), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: CeoColors.cyan.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.folder_copy_outlined, color: CeoColors.cyan)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('${p['name']}', 12), muted('${p['department']} • ${p['code']}', 9), const SizedBox(height: 6), LinearProgressIndicator(value: _num(p['progress']) / 100, color: CeoColors.cyan, backgroundColor: CeoColors.border)])), const SizedBox(width: 9), Column(children: [title('${p['progress']}%', 11), muted(_label('${p['status']}'), 8)])]));

  Widget _details(Map<String, dynamic>? p) { if (p == null) return Center(child: muted('Select a project', 12)); final milestones = _maps(p['milestones']); return ListView(padding: const EdgeInsets.all(14), children: [
    CeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.folder_special, color: CeoColors.cyan), const SizedBox(width: 9), Expanded(child: title('${p['name']}', 16)), _chip(_label('${p['status']}'))]), muted('${p['code']} • ${p['department']}', 9), const SizedBox(height: 12), Row(children: [Expanded(child: _stat('Start Date', p['start_date'])), Expanded(child: _stat('End Date', p['end_date']))])])),
    CeoMetricGrid(cards: [CeoMetric('Progress', '${p['progress']}%', '', Icons.donut_large, CeoColors.cyan), CeoMetric('Budget', _money(p['budget']), '', Icons.account_balance_wallet, CeoColors.purple), CeoMetric('Spent', _money(p['spent']), '', Icons.payments, CeoColors.gold)]),
    CeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('Project Manager', 13), _info('Name', p['manager_name']), _info('Email', p['manager_email'])])),
    CeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('Description', 13), const SizedBox(height: 6), Text('${p['description'] ?? ''}') ])),
    Row(children: [Expanded(child: title('Key Milestones', 13)), TextButton(onPressed: () => _addMilestone(p), child: const Text('+ Add'))]), ...milestones.map((m) => CeoCard(child: Row(children: [Icon(m['status'] == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked, color: m['status'] == 'completed' ? CeoColors.green : CeoColors.gold), const SizedBox(width: 8), Expanded(child: Text('${m['title']}')), Text('${m['progress']}%')]))),
    FilledButton(onPressed: () => setState(() => _page = 3), child: const Text('Team & Tasks')),
  ]); }

  Widget _teamTasks(Map<String, dynamic>? p) { if (p == null) return const SizedBox(); final team = _maps(p['team']); final tasks = _maps(p['tasks']); final counts = _map(p['task_counts']); return ListView(padding: const EdgeInsets.all(14), children: [
    SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Team')), ButtonSegment(value: true, label: Text('Tasks'))], selected: {_tasksTab}, onSelectionChanged: (v) => setState(() => _tasksTab = v.first)), const SizedBox(height: 12),
    if (!_tasksTab) ...[Row(children: [Expanded(child: title('Project Team', 14)), TextButton(onPressed: () => _addMember(p), child: const Text('+ Add Member'))]), if (team.isEmpty) CeoCard(child: muted('No team members assigned', 11)), ...team.map((m) => CeoListTile(icon: Icons.person_outline, titleText: '${m['name']}', subtitle: '${m['role'] ?? 'Member'} • ${m['email'] ?? ''}'))],
    if (_tasksTab) ...[Row(children: [Expanded(child: title('Project Tasks', 14)), TextButton(onPressed: () => _addTask(p), child: const Text('+ Add Task'))]), ...tasks.map((t) => CeoCard(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('${t['title']}', 11), muted('${t['assignee_name']} • ${t['priority']}', 9)])), DropdownButton<String>(value: '${t['status']}', items: ['pending', 'in_progress', 'completed'].map((s) => DropdownMenuItem(value: s, child: Text(_label(s)))).toList(), onChanged: (v) { if (v != null) _action('update_task', {'project_id': p['id'], 'task_id': t['id'], 'status': v}); })])))],
    const SizedBox(height: 10), CeoMetricGrid(cards: [CeoMetric('Total Tasks', '${p['total_tasks']}', '', Icons.task, CeoColors.cyan), CeoMetric('Completed', '${counts['completed'] ?? 0}', '', Icons.check, CeoColors.green), CeoMetric('In Progress', '${counts['in_progress'] ?? 0}', '', Icons.schedule, CeoColors.gold), CeoMetric('Pending', '${counts['pending'] ?? 0}', '', Icons.pending_actions, Colors.deepOrange)]),
    FilledButton(onPressed: () => setState(() => _page = 4), child: const Text('Progress & Completion')),
  ]); }

  Widget _progress(Map<String, dynamic>? p) { if (p == null) return const SizedBox(); final milestones = _maps(p['milestones']); final history = _maps(p['progress_history']); return ListView(padding: const EdgeInsets.all(14), children: [
    CeoCard(child: Column(children: [title('Overall Progress', 14), const SizedBox(height: 12), SizedBox(width: 130, height: 130, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: _num(p['progress']) / 100, strokeWidth: 16, color: CeoColors.green, backgroundColor: CeoColors.border), title('${p['progress']}%', 21)]))])),
    title('Progress Over Time', 14), const SizedBox(height: 8), CeoCard(child: Column(children: history.map((h) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [SizedBox(width: 90, child: muted('${h['date']}', 9)), Expanded(child: LinearProgressIndicator(value: _num(h['progress']) / 100, color: CeoColors.cyan, backgroundColor: CeoColors.border)), const SizedBox(width: 8), Text('${h['progress']}%')]))).toList())),
    title('Milestone Completion', 14), const SizedBox(height: 8), ...milestones.map((m) => CeoCard(child: Column(children: [Row(children: [Expanded(child: Text('${m['title']}')), Text('${m['progress']}%')]), Slider(value: _num(m['progress']).clamp(0, 100).toDouble(), max: 100, divisions: 10, onChangeEnd: (v) => _action('update_milestone', {'project_id': p['id'], 'milestone_id': m['id'], 'progress': v.round()}), onChanged: (_) {})]))),
    CeoCard(child: Row(children: [const Icon(Icons.calendar_month, color: CeoColors.cyan), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [muted('Estimated Completion', 9), title('${p['end_date']}', 13)])), _chip(_label('${p['status']}'))])),
  ]); }

  Map<String, dynamic>? _resolve(Map<String, dynamic> data) { final list = _maps(data['projects']); if (_project != null) { final m = list.where((p) => p['id'] == _project!['id']); if (m.isNotEmpty) return m.first; } return list.isEmpty ? null : list.first; }
  Future<void> _createProject() async { final v = await _dialog('Create Project', ['name','code','department','start_date','end_date','budget','description']); if (v != null) await _action('create_project', v); }
  Future<void> _addMember(Map<String,dynamic> p) async { final v = await _dialog('Add Team Member', ['id','name','email','role']); if (v != null) await _action('add_member', {'project_id':p['id'],'member':v}); }
  Future<void> _addTask(Map<String,dynamic> p) async { final v = await _dialog('Add Task', ['title','assignee_id','assignee_name','assignee_email','priority','due_date','description']); if (v != null) await _action('create_task', {'project_id':p['id'],...v}); }
  Future<void> _addMilestone(Map<String,dynamic> p) async { final v = await _dialog('Add Milestone', ['title','due_date']); if (v != null) await _action('add_milestone', {'project_id':p['id'],...v}); }
  Future<Map<String,dynamic>?> _dialog(String heading,List<String> fields) async { final c={for(final f in fields)f:TextEditingController()}; final r=await showDialog<Map<String,dynamic>>(context:context,builder:(x)=>AlertDialog(title:Text(heading),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:fields.map((f)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c[f],decoration:InputDecoration(labelText:_label(f))))).toList())),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(x,{for(final e in c.entries)e.key:e.value.text.trim()}),child:const Text('Save'))])); for(final x in c.values)x.dispose(); return r; }
  Widget _stat(String l,dynamic v)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[muted(l,8),title('${v??'-'}',11)]); Widget _info(String l,dynamic v)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[SizedBox(width:90,child:muted(l,9)),Expanded(child:Text('${v??'-'}'))])); Widget _chip(String t)=>Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(border:Border.all(color:CeoColors.cyan),borderRadius:BorderRadius.circular(5)),child:Text(t,style:const TextStyle(color:CeoColors.cyan,fontSize:8)));
  static Map<String,dynamic> _map(dynamic v)=>v is Map?Map<String,dynamic>.from(v):{}; static List<Map<String,dynamic>> _maps(dynamic v)=>v is List?v.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList():[]; static double _num(dynamic v)=>double.tryParse('$v')??0; static String _label(String v)=>v.replaceAll('_',' ').split(' ').map((w)=>w.isEmpty?'':w[0].toUpperCase()+w.substring(1)).join(' '); static String _money(dynamic v)=>'\u20B9${_num(v).toStringAsFixed(0)}'; static const _titles=['Project Dashboard','Project List','Project Details','Team & Tasks','Progress & Completion'];
}
