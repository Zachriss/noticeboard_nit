import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I view notices?',
      'answer':
          'Notices are displayed on the Home and Notices tabs. You can search and filter notices by category.',
    },
    {
      'question': 'How do I like a notice?',
      'answer':
          'Tap on the heart icon on any notice card to like or unlike it.',
    },
    {
      'question': 'How can I submit feedback?',
      'answer':
          'Go to the Feedback tab, enter your feedback in the text field, and tap Submit.',
    },
    {
      'question': 'How do I update my profile?',
      'answer':
          'Tap on your profile avatar in the top right of the Home screen to access profile options.',
    },
    {
      'question': 'Who can post notices?',
      'answer':
          'Only admins and super admins can create, edit, and delete notices. Students can only view and like notices.',
    },
    {
      'question': 'How do I contact the admin?',
      'answer':
          'Use the Feedback tab to submit any queries or issues. Your feedback will be reviewed by the administration.',
    },
    {
      'question': 'Is my data secure?',
      'answer':
          'Yes, your profile data is stored locally on your device using secure local storage.',
    },
    {
      'question': 'How do I logout?',
      'answer':
          'Tap on your profile avatar and select Logout from the menu options.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              iconColor: AppTheme.primaryColor,
              collapsedIconColor: Colors.grey,
              title: Text(
                faq['question']!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              children: [
                Text(
                  faq['answer']!,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
