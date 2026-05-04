import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../services/notice_service.dart';
import '../../services/auth_service.dart';
import '../../models/notice_model.dart';

class CreateNoticeScreen extends StatefulWidget {
  final NoticeModel? notice; // For editing

  const CreateNoticeScreen({super.key, this.notice});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final NoticeService _noticeService = NoticeService();
  final AuthService _authService = AuthService();

  String _selectedCategory = 'General';
  bool _isLoading = false;

  final List<String> _categories = [
    'Academic',
    'Exams',
    'Events',
    'Library',
    'Placement',
    'Sports',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.notice != null) {
      _titleController.text = widget.notice!.title;
      _descriptionController.text = widget.notice!.description;
      _selectedCategory = widget.notice!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      final userData = await _authService.getUserData(user?.uid ?? '');

      if (user == null || userData == null) {
        _showError('Please login to create notices');
        return;
      }

      final notice = NoticeModel(
        id: widget.notice?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        authorId: user.uid,
        authorName: userData.name,
        createdAt: widget.notice?.createdAt ?? DateTime.now(),
        status: NoticeStatus.pending,
        likesCount: widget.notice?.likesCount ?? 0,
      );

      if (widget.notice != null) {
        await _noticeService.updateNotice(notice);
        _showSuccess('Notice updated successfully');
      } else {
        await _noticeService.createNotice(notice);
        _showSuccess('Notice submitted for approval');
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notice != null ? 'Edit Notice' : 'Create Notice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.noticeTitle,
                  hintText: 'Enter notice title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: AppStrings.noticeCategory,
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: AppStrings.noticeDescription,
                  hintText: 'Enter notice description',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Info Card
              Card(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your notice will be submitted for approval by the super admin.',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitNotice,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        widget.notice != null
                            ? AppStrings.update
                            : AppStrings.submit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
