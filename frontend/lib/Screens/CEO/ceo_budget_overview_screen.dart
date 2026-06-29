import 'package:flutter/material.dart';

import 'ceo_service.dart';
import 'ceo_widgets.dart';

class CeoBudgetOverviewScreen extends StatelessWidget {
  final String userId;

  const CeoBudgetOverviewScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CeoShell(
      title: 'Budget Overview',
      child: CeoFutureBody(
        future: CeoService().fetchBudget(userId),
        builder: (data) => pageList([
          CeoListTile(icon: Icons.account_balance_wallet_rounded, titleText: 'Total Budget', subtitle: '${data['total_budget']}', color: CeoColors.cyan),
          CeoListTile(icon: Icons.payments_rounded, titleText: 'Total Spent', subtitle: '${data['total_spent']}', color: CeoColors.pink),
          CeoListTile(icon: Icons.savings_rounded, titleText: 'Remaining Budget', subtitle: '${data['remaining_budget']}', color: CeoColors.green),
          chartCard('Budget vs Actual', const [58, 72, 48, 66, 76, 70], color: CeoColors.cyan),
        ]),
      ),
    );
  }
}
