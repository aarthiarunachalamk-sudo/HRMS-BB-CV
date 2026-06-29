import 'package:flutter/material.dart';
import 'hr_shared.dart';

class HrLeaveRequestsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrLeaveRequestsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    final leaves = hrList(data, 'leave_requests');
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        Row(children: [
          _Tab(label: 'Pending (${leaves.length})', active: true),
          const SizedBox(width: 8),
          const _Tab(label: 'Approved'),
          const SizedBox(width: 8),
          const _Tab(label: 'Rejected'),
        ]),
        const SizedBox(height: 12),
        ...leaves.map((leave) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HrCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  HrListTile(icon: Icons.person_rounded, title: '${leave['name']}', subtitle: '${leave['subtitle']}', trailing: '${leave['days']}', color: c.primary),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.success, foregroundColor: Colors.white), onPressed: () {}, child: const Text('Approve'))),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white), onPressed: () {}, child: const Text('Reject'))),
                  ]),
                ]),
              ),
            )),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;

  const _Tab({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Expanded(
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: active ? c.primary.withAlpha(30) : c.row, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
        child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? c.primary : c.muted, fontSize: 11, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
