import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

// Core imports
import '../../../core/barrel.dart';

// Family System imports
import '../barrel.dart';

/// Family Management Screen
class FamilyManagementScreen extends ConsumerStatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  ConsumerState<FamilyManagementScreen> createState() =>
      _FamilyManagementScreenState();
}

class _FamilyManagementScreenState
    extends ConsumerState<FamilyManagementScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String? _selectedParentId;
  int _selectedGrade = 5;
  bool _isCreatingParent = false;
  bool _isCreatingStudent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _studentNameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _createParentAccount() async {
    if (_emailController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingParent = true;
    });

    try {
      final familyService = ref.read(familyServiceProvider);
      final parentAccount = await familyService.createParentAccount(
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
      );

      _emailController.clear();
      _nameController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parent account created: ${parentAccount.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating parent account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingParent = false;
      });
    }
  }

  Future<void> _createStudentProfile() async {
    if (_selectedParentId == null || _studentNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a parent and enter student name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingStudent = true;
    });

    try {
      final familyService = ref.read(familyServiceProvider);
      final studentProfile = await familyService.createStudentProfile(
        name: _studentNameController.text.trim(),
        grade: _selectedGrade,
        parentId: _selectedParentId!,
        pin: _pinController.text.isNotEmpty ? _pinController.text.trim() : null,
      );

      _studentNameController.clear();
      _pinController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student profile created: ${studentProfile.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating student profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingStudent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: Text(
          'Family Management',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parent Account Creation
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Parent Account',
                      style: themeData.typography.headlineSmall.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'parent@example.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'Parent Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreatingParent
                            ? null
                            : _createParentAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isCreatingParent
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Create Parent Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Student Profile Creation
            Card(
              color: colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Student Profile',
                      style: themeData.typography.headlineSmall.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Parent Selection
                    Consumer(
                      builder: (context, ref, child) {
                        return FutureBuilder<List<ParentAccount>>(
                          future: ref
                              .read(familyServiceProvider)
                              .getAllParentAccounts(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            final parents = snapshot.data ?? [];

                            return DropdownButtonFormField<String>(
                              value: _selectedParentId,
                              decoration: InputDecoration(
                                labelText: 'Select Parent',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: colorScheme.surface,
                              ),
                              items: parents.map((parent) {
                                return DropdownMenuItem(
                                  value: parent.id,
                                  child: Text(parent.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedParentId = value;
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _studentNameController,
                      decoration: InputDecoration(
                        labelText: 'Student Name',
                        hintText: 'Student Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grade Selection
                    DropdownButtonFormField<int>(
                      value: _selectedGrade,
                      decoration: InputDecoration(
                        labelText: 'Grade',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text('Grade ${index + 1}'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _selectedGrade = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _pinController,
                      decoration: InputDecoration(
                        labelText: 'PIN (Optional)',
                        hintText: '4-digit PIN for student login',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreatingStudent
                            ? null
                            : _createStudentProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isCreatingStudent
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Create Student Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Family Overview
            Card(
              color: colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Family Overview',
                      style: themeData.typography.headlineSmall.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Consumer(
                      builder: (context, ref, child) {
                        return FutureBuilder<List<ParentAccount>>(
                          future: ref
                              .read(familyServiceProvider)
                              .getAllParentAccounts(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final parents = snapshot.data ?? [];

                            if (parents.isEmpty) {
                              return Center(
                                child: Text(
                                  'No parent accounts found',
                                  style: themeData.typography.bodyMedium
                                      .copyWith(
                                        color: colorScheme.onTertiaryContainer,
                                      ),
                                ),
                              );
                            }

                            return Column(
                              children: parents.map((parent) {
                                return _buildParentCard(
                                  parent,
                                  colorScheme,
                                  themeData,
                                );
                              }).toList(),
                            );
                          },
                        );
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

  Widget _buildParentCard(
    ParentAccount parent,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return Card(
      color: colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    parent.name[0].toUpperCase(),
                    style: themeData.typography.labelLarge.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parent.name,
                        style: themeData.typography.titleMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        parent.email,
                        style: themeData.typography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(parent.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    parent.status.name.toUpperCase(),
                    style: themeData.typography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Students for this parent
            Consumer(
              builder: (context, ref, child) {
                return FutureBuilder<List<StudentProfile>>(
                  future: ref
                      .read(familyServiceProvider)
                      .getStudentsForParent(parent.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 20,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final students = snapshot.data ?? [];

                    if (students.isEmpty) {
                      return Text(
                        'No students linked',
                        style: themeData.typography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Students:',
                          style: themeData.typography.labelMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...students.map(
                          (student) => _buildStudentItem(
                            student,
                            colorScheme,
                            themeData,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentItem(
    StudentProfile student,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.secondary,
            child: Text(
              student.name[0].toUpperCase(),
              style: themeData.typography.labelSmall.copyWith(
                color: colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: themeData.typography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Grade ${student.grade}',
                  style: themeData.typography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(student.status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              student.status.name.toUpperCase(),
              style: themeData.typography.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return Colors.green;
      case UserStatus.offline:
        return Colors.grey;
      case UserStatus.inQuiz:
        return Colors.orange;
      case UserStatus.idle:
        return Colors.blue;
      case UserStatus.busy:
        return Colors.red;
    }
  }
}

/// Family Login Screen
class FamilyLoginScreen extends ConsumerStatefulWidget {
  const FamilyLoginScreen({super.key});

  @override
  ConsumerState<FamilyLoginScreen> createState() => _FamilyLoginScreenState();
}

class _FamilyLoginScreenState extends ConsumerState<FamilyLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isParentLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_isParentLogin && _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isParentLogin && _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your PIN'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final familyService = ref.read(familyServiceProvider);

      final result = await familyService.authenticateUser(
        email: _isParentLogin ? _emailController.text.trim() : null,
        pin: !_isParentLogin ? _pinController.text.trim() : null,
      );

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to appropriate screen based on role
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during authentication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: Text(
          'Family Login',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Login Type Toggle
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Choose Login Type',
                      style: themeData.typography.headlineSmall.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isParentLogin = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isParentLogin
                                  ? colorScheme.primary
                                  : colorScheme.surface,
                              foregroundColor: _isParentLogin
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                            child: const Text('Parent'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isParentLogin = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_isParentLogin
                                  ? colorScheme.secondary
                                  : colorScheme.surface,
                              foregroundColor: !_isParentLogin
                                  ? colorScheme.onSecondary
                                  : colorScheme.onSurface,
                            ),
                            child: const Text('Student'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login Form
            Card(
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _isParentLogin ? 'Parent Login' : 'Student Login',
                      style: themeData.typography.headlineSmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isParentLogin) ...[
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'parent@example.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _pinController,
                        decoration: InputDecoration(
                          labelText: 'PIN',
                          hintText: 'Enter your 4-digit PIN',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                      ),
                    ],

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Login'),
                      ),
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
}
