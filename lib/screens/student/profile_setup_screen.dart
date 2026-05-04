import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared_preferences/local_storage.dart';
import '../student/student_home.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedYear;
  bool _isLoading = false;

  final List<String> _departments = [
    'Computer Science & Engineering',
    'Information Technology',
    'Electronics & Communication',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
  ];

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartment == null || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await LocalStorage.setUserName(_nameController.text.trim());
      await LocalStorage.setUserDepartment(_selectedDepartment!);
      await LocalStorage.setUserYear(_selectedYear!);
      await LocalStorage.setUserPhone(_phoneController.text.trim());
      await LocalStorage.setProfileSetup(true);
      await LocalStorage.setUserRole('student');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(
                Icons.person_add,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to NIT Notice Board',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please set up your profile to continue',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Full Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Department
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.school_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _departments.map((dept) {
                  return DropdownMenuItem(value: dept, child: Text(dept));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDepartment = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select your department';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Year
              DropdownButtonFormField<String>(
                initialValue: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year of Study',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _years.map((year) {
                  return DropdownMenuItem(value: year, child: Text(year));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedYear = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select your year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
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
                    : const Text(
                        'Save Profile',
                        style: TextStyle(
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
