import 'package:flutter/material.dart';

class ViewFeedbackScreen extends StatefulWidget {
  const ViewFeedbackScreen({super.key});

  @override
  State<ViewFeedbackScreen> createState() => _ViewFeedbackScreenState();
}

class _ViewFeedbackScreenState extends State<ViewFeedbackScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Feedback')),
      body: const Center(child: Text('Feedback details will appear here.')),
    );
  }
}
