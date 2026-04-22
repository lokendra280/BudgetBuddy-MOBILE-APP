import 'package:expensetracker/common/wrapper/update_wrapper.dart';
import 'package:expensetracker/features/dashboard/widget/dashboard_widget.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UpdateWrapper(child: const DashboardWidget());
  }
}
