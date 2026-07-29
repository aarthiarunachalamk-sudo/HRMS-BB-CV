import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/utils/app_layout.dart';
import 'hr_shared.dart';

class HrDocumentsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HrDocumentsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return ListView(
      padding: AppLayout.pagePadding,
      children: [
        HrCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: c.muted, size: 18),
              const SizedBox(width: 8),
              Text(
                'Search documents...',
                style: TextStyle(
                  color: c.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...hrList(data, 'documents').map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HrListTile(
              icon: Icons.folder_rounded,
              title: '${item['title']}',
              subtitle: '${item['subtitle']}',
              color: c.warning,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document upload is not available yet.'),
              ),
            );
          },
          icon: const Icon(Icons.upload_rounded),
          label: const Text('Upload'),
        ),
      ],
    );
  }
}
