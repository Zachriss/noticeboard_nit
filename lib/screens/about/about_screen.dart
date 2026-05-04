import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             // App Logo
             Center(
               child: CircleAvatar(
                 radius: 60,
                 backgroundColor: AppTheme.primaryColor,
                 child: Image.asset(
                   'assets/images/logo.png',
                   fit: BoxFit.contain,
                 ),
               ),
             ),
            const SizedBox(height: 24),

            // App Name
            const Text(
              'NIT Noticeboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),

            // Version
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Description
            const Text(
              'Official noticeboard application for National Institute of Transportstudents. Stay updated with all academic announcements, exam schedules, events, and important notices in real-time.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Features
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(Icons.notifications_active, 'Real-time Notices'),
                    _buildFeatureItem(Icons.category, 'Category Wise Filter'),
                    _buildFeatureItem(Icons.search, 'Advanced Search'),
                    _buildFeatureItem(Icons.thumb_up, 'Like & Save Notices'),
                    _buildFeatureItem(Icons.person, 'Student Profile'),
                    _buildFeatureItem(Icons.feedback, 'Feedback System'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Developed By
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Text(
                      'Developed By',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Zacharia Sugilo',
                      style: TextStyle(fontSize: 15),
                    ),
                    Text(
                      'National Institute of Transport',
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Copyright
            const Text(
              '© 2026 National Institute of Transport. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}