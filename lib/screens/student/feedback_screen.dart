import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _sampleFeedback = [
    {
      'title': 'Exam Schedule Issue',
      'desc': 'The exam timetable for the 5th semester needs revision.',
      'date': '27 Apr 2026',
      'status': 'Resolved',
    },
    {
      'title': 'Library Hours',
      'desc': 'Can the library hours be extended during exam season?',
      'date': '25 Apr 2026',
      'status': 'Pending',
    },
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // Submit Feedback Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submit Feedback',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe your feedback or issue...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your feedback';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Submit Feedback'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Previous Feedbacks
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Feedbacks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sampleFeedback.length,
              itemBuilder: (context, index) {
                final feedback = _sampleFeedback[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      feedback['title'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(feedback['desc']),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              feedback['date'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: feedback['status'] == 'Resolved'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                feedback['status'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: feedback['status'] == 'Resolved'
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    _feedbackController.clear();
    setState(() => _isSubmitting = false);
  }
}
