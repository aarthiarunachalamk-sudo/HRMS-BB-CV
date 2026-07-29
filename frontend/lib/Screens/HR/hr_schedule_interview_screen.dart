import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'hr_service.dart';
import 'hr_shared.dart';

class HrScheduleInterviewScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onChanged;

  const HrScheduleInterviewScreen({
    super.key,
    required this.data,
    required this.userId,
    required this.onChanged,
  });

  @override
  State<HrScheduleInterviewScreen> createState() =>
      _HrScheduleInterviewScreenState();
}

class _HrScheduleInterviewScreenState
    extends State<HrScheduleInterviewScreen> {
  int? _candidateId;
  DateTime? _date;
  TimeOfDay? _time;
  String _mode = 'Online';
  final _location = TextEditingController();
  final _interviewers = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _location.dispose();
    _interviewers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final candidates = hrList(widget.data, 'candidates')
        .where((candidate) => !{'hired', 'rejected'}.contains('${candidate['stage']}'))
        .toList();
    if (_candidateId == null && candidates.isNotEmpty) {
      _candidateId = int.tryParse('${candidates.first['id']}');
    }
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        Text(
          'Schedule Candidate Interview',
          style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Select a candidate, interview slot, mode and interviewer.',
          style: TextStyle(color: c.muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        if (candidates.isEmpty)
          HrCard(
            child: Text(
              'No eligible candidates are available for interview.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 12),
            ),
          )
        else ...[
          HrCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Candidate', c),
                DropdownButtonFormField<int>(
                  value: _candidateId,
                  dropdownColor: c.surface,
                  decoration: _decoration(Icons.person_search_rounded, c),
                  items: candidates
                      .map(
                        (candidate) => DropdownMenuItem<int>(
                          value: int.tryParse('${candidate['id']}'),
                          child: Text(
                            '${candidate['name']} • ${candidate['job_title']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _candidateId = value),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PickerTile(
                        label: 'Date',
                        value: _date == null
                            ? 'Select date'
                            : _date!.toIso8601String().split('T').first,
                        icon: Icons.calendar_today_rounded,
                        color: c.primary,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PickerTile(
                        label: 'Time',
                        value: _time?.format(context) ?? 'Select time',
                        icon: Icons.schedule_rounded,
                        color: c.warning,
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _label('Interview Mode', c),
                DropdownButtonFormField<String>(
                  value: _mode,
                  dropdownColor: c.surface,
                  decoration: _decoration(Icons.video_call_rounded, c),
                  items: const ['Online', 'In Person', 'Phone']
                      .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                      .toList(),
                  onChanged: (value) => setState(() => _mode = value ?? _mode),
                ),
                const SizedBox(height: 14),
                _label(_mode == 'Online' ? 'Meeting Link' : 'Location / Details', c),
                TextField(
                  controller: _location,
                  style: TextStyle(color: c.text),
                  decoration: _decoration(Icons.link_rounded, c),
                ),
                const SizedBox(height: 14),
                _label('Interviewer(s)', c),
                TextField(
                  controller: _interviewers,
                  style: TextStyle(color: c.text),
                  decoration: _decoration(Icons.groups_rounded, c),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _saving ? null : _schedule,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.event_available_rounded),
            label: Text(_saving ? 'Scheduling...' : 'Schedule Interview'),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
    );
    if (value != null && mounted) setState(() => _date = value);
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (value != null && mounted) setState(() => _time = value);
  }

  Future<void> _schedule() async {
    if (_candidateId == null || _date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select candidate, date and time.')),
      );
      return;
    }
    setState(() => _saving = true);
    final scheduled = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    try {
      await HrService().scheduleInterview(_candidateId!, {
        'user_id': widget.userId,
        'scheduled_at': scheduled.toIso8601String(),
        'mode': _mode,
        'location_or_link': _location.text.trim(),
        'interviewers': _interviewers.text.trim(),
      });
      if (!mounted) return;
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interview scheduled successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text, HrPalette c) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700)),
  );

  InputDecoration _decoration(IconData icon, HrPalette c) => InputDecoration(
    prefixIcon: Icon(icon, color: c.primary, size: 19),
    filled: true,
    fillColor: c.row,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.border),
    ),
  );
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.row,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: c.muted, fontSize: 10)),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.text, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
