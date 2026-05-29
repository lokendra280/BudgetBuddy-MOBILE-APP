import 'package:budgetBuddy/features/profile/ui/policy_page.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PolicyPage(
      title: "Privacy Policy",
      content: """
Last updated: May 2026

We respect your privacy.

1. Data Collection
We only collect necessary data such as app usage, expenses, and preferences.

2. How We Use Data
We use data to improve app experience and provide personalized insights.

3. Data Storage
Your data is securely stored using encrypted cloud services.

4. Third-Party Services
We may use analytics and notification services to improve performance.

5. Your Rights
You can delete your data anytime from the app settings.

6. Contact
If you have questions, contact  budgetbuddy841@gmail.com
""",
    );
  }
}
