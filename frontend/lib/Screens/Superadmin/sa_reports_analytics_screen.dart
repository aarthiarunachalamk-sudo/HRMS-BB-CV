import 'package:flutter/material.dart';
import 'sa_service.dart';
import 'sa_shared.dart';

class SaReportsAnalyticsScreen extends StatelessWidget {
  const SaReportsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SaPalette.of(context);
    return SaScreen(
      title: 'Reports & Analytics',
      child: FutureBuilder<Map<String, dynamic>>(
        future: SaService().fetchDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          final reports = ((snapshot.data?['reports'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          return saList([
            if (reports.isEmpty)
              _empty(context, c)
            else
              ...reports.map(
                (report) => SaInfoTile(
                  icon: Icons.description_outlined,
                  title: '${report['report_type'] ?? 'Report'}',
                  subtitle: '${report['status'] ?? ''}',
                  trailing: '${report['format'] ?? ''}',
                  color: c.blue,
                ),
              ),
            const SizedBox(height: 8),
            saTitle(context, 'Export Reports', 14),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _Export('PDF', Icons.picture_as_pdf_outlined, c.danger)),
                const SizedBox(width: 10),
                Expanded(child: _Export('Excel', Icons.table_chart_outlined, c.success)),
                const SizedBox(width: 10),
                Expanded(child: _Export('CSV', Icons.file_copy_outlined, c.blue)),
              ],
            ),
          ]);
        },
      ),
    );
  }

  Widget _empty(BuildContext context, SaPalette c) => SaCard(
        child: Center(
          child: Text(
            'No reports data found in backend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontWeight: FontWeight.w800),
          ),
        ),
      );
}

class _Export extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Export(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => SaCard(
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            saTitle(context, label, 11),
          ],
        ),
      );
}
