import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'hr_shared.dart';

class HrRecruitmentPipelineScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const HrRecruitmentPipelineScreen({super.key, required this.data});

  @override
  State<HrRecruitmentPipelineScreen> createState() =>
      _HrRecruitmentPipelineScreenState();
}

class _HrRecruitmentPipelineScreenState
    extends State<HrRecruitmentPipelineScreen> {
  String _selectedStage = 'all';

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final stages = hrList(widget.data, 'pipeline');
    final candidates = hrList(widget.data, 'candidates');
    final filtered = _selectedStage == 'all'
        ? candidates
        : candidates
              .where((candidate) => '${candidate['stage']}' == _selectedStage)
              .toList();
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        Text(
          'Candidate Pipeline',
          style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _StageChip(
                label: 'All',
                count: candidates.length,
                selected: _selectedStage == 'all',
                color: c.primary,
                onTap: () => setState(() => _selectedStage = 'all'),
              ),
              ...stages.map(
                (stage) => _StageChip(
                  label: '${stage['title']}',
                  count: int.tryParse('${stage['count']}') ?? 0,
                  selected: _selectedStage == '${stage['key']}',
                  color: c.purple,
                  onTap: () => setState(() => _selectedStage = '${stage['key']}'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          HrCard(
            child: Text(
              'No candidates in this stage.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 12),
            ),
          ),
        ...filtered.map(
          (candidate) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HrListTile(
              icon: Icons.person_rounded,
              title: '${candidate['name'] ?? 'Candidate'}',
              subtitle:
                  '${candidate['job_title'] ?? 'General Application'} • ${candidate['qualification'] ?? ''}',
              trailing: '${candidate['stage_label'] ?? candidate['stage'] ?? ''}',
              color: c.purple,
            ),
          ),
        ),
      ],
    );
  }
}

class _StageChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StageChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color,
      label: Text('$label  $count'),
    ),
  );
}
