import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Center(
              child: Column(
                children: [
                  Icon(Icons.help_center, size: 60, color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text(
                    'How can we help you?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Find answers to common questions',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // FAQ Sections
            _buildHelpCategory(
              icon: Icons.account_circle,
              title: 'Account & Profile',
              questions: [
                'How do I login to my account?',
                'How to update my profile information?',
                'I forgot my password, what to do?',
                'How to logout from the app?',
              ],
            ),
            const SizedBox(height: 16),

            _buildHelpCategory(
              icon: Icons.notifications_active,
              title: 'Notices',
              questions: [
                'How to view notice details?',
                'Can I save notices for later?',
                'How to filter notices by category?',
                'Why some notices are not visible?',
              ],
            ),
            const SizedBox(height: 16),

            _buildHelpCategory(
              icon: Icons.thumb_up,
              title: 'Likes & Interactions',
              questions: [
                'How to like a notice?',
                'Can I unlike a notice?',
                'Who can see my liked notices?',
              ],
            ),
            const SizedBox(height: 16),

            _buildHelpCategory(
              icon: Icons.bug_report,
              title: 'Troubleshooting',
              questions: [
                'App is loading slowly',
                'Notices not updating',
                'Login issues',
                'Report a bug',
              ],
            ),
            const SizedBox(height: 32),

            // Contact Support
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Still need help?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.email, color: AppTheme.primaryColor),
                      title: const Text('Email Support'),
                      subtitle: const Text('zachariachristophersugilo@gmail.com'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.feedback, color: AppTheme.primaryColor),
                      title: const Text('Send Feedback'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHelpCategory({
    required IconData icon,
    required String title,
    required List<String> questions,
  }) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: questions.map((question) {
          return ListTile(
            title: Text(
              question,
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () {},
          );
        }).toList(),
      ),
    );
  }
}