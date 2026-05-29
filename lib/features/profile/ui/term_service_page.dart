import 'package:budgetBuddy/features/profile/ui/policy_page.dart';
import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PolicyPage(
      title: "Terms of Service",
      content: """
Last updated: May 2026

By using this app, you agree to the following terms:

1. Usage
You agree to use the app only for personal financial tracking.

2. Account Responsibility
You are responsible for your account and data accuracy.

3. Restrictions
Do not misuse the app or attempt to hack or reverse engineer it.

4. Service Changes
We may update or modify features anytime without notice.

5. Limitation of Liability
We are not responsible for financial losses caused by incorrect data usage.

6. Termination
We may suspend accounts that violate terms.

7. Contact
For support, contact budgetbuddy841@gmail.com
""",
    );
  }
}
