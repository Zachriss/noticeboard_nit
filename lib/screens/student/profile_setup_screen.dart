import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../shared_preferences/local_storage.dart';
import '../../services/student_auth_service.dart';
import '../student/student_home.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isEditMode;

  const ProfileSetupScreen({super.key, this.isEditMode = false});

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
  String? _profileImageBase64;
  final ImagePicker _picker = ImagePicker();

  final List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Electronics & Telecommunication Engineering',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil & Railway Engineering',
    'Automobile Engineering',
    'Naval Architecture and Marine Engineering',
    'Logistics and Transport Management',
    'Road and Railway Transport Logistics Management',
    'Shipping and Ports Logistics Management',
    'Bussines Adminstration',
    'Procurement and Logistics Management',
    'Marketing and Public Relation',
    'Accounting and Transport Finance',
    'Pipework, Oil and Gas Engineering',
    'Shipbuilding and Repair',
    'Freight Clearing and Forwarding',
    'Library Information Studies',
    'Record Archieves and Information Management',

  ];

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      // Pre-fill fields from existing LocalStorage data
      _nameController.text = LocalStorage.userName;
      _phoneController.text = LocalStorage.userPhone;
      _selectedDepartment = LocalStorage.userDepartment.isNotEmpty
          ? LocalStorage.userDepartment
          : null;
      _selectedYear = LocalStorage.userYear.isNotEmpty
          ? LocalStorage.userYear
          : null;
      // Load existing profile image if any
      if (LocalStorage.profileImage.isNotEmpty) {
        _profileImageBase64 = LocalStorage.profileImage;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _profileImageBase64 = base64String;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    }
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
      if (!widget.isEditMode) {
        // Only sign in anonymously on first-time setup
        final studentAuth = StudentAuthService();
        await studentAuth.signInAnonymously();
      }

      await LocalStorage.setUserName(_nameController.text.trim());
      await LocalStorage.setUserDepartment(_selectedDepartment!);
      await LocalStorage.setUserYear(_selectedYear!);
      await LocalStorage.setUserPhone(_phoneController.text.trim());
      await LocalStorage.setProfileSetup(true);
      await LocalStorage.setUserRole('student');

      // Save profile image (base64) if one was selected
      if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
        await LocalStorage.setProfileImage(_profileImageBase64!);
      }

      if (!mounted) return;

      if (widget.isEditMode) {
        // In edit mode, just go back to the previous screen
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // First-time setup, navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
        );
      }
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
        title: Text(widget.isEditMode ? 'Edit Profile' : 'Profile Setup'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo
              GestureDetector(
                onTap: _pickImage,
                child: Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor,
                        backgroundImage: _profileImageBase64 != null
                            ? MemoryImage(
                                base64Decode(_profileImageBase64!),
                              ) as ImageProvider
                            : null,
                        child: _profileImageBase64 == null
                            ? Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: Text(
                    _profileImageBase64 != null
                        ? 'Change Photo'
                        : 'Upload Photo',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isEditMode
                    ? 'Edit Your Profile'
                    : 'Welcome to NIT Notice Board',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isEditMode
                    ? 'Update your details below'
                    : 'Please set up your profile to continue',
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
                onChanged: (_) => setState(() {}), // Refresh avatar initials
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  // Only allow alphabetic characters (A-Z, a-z) and spaces
                  final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
                  if (!nameRegex.hasMatch(value)) {
                    return 'Name must contain only letters and spaces';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Department
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Programs',
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
                  final phone = value.trim();
                  // Must be exactly 10 digits and start with 06 or 07
                  final phoneRegex = RegExp(r'^(06|07)\d{8}$');
                  if (!phoneRegex.hasMatch(phone)) {
                    if (phone.length != 10) {
                      return 'Phone number must be exactly 10 digits';
                    }
                    if (!phone.startsWith('06') && !phone.startsWith('07')) {
                      return 'Phone number must start with 06 or 07';
                    }
                    return 'Enter a valid phone number';
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
                    : Text(
                        widget.isEditMode ? 'Update Profile' : 'Save Profile',
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