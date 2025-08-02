import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

// Core imports
import '../../../core/barrel.dart' hide UserRole;

// User Management imports
import '../barrel.dart';
import '../models/user_model.dart' as user_models;

/// Authentication Widget - Login and Registration
class AuthWidget extends ConsumerStatefulWidget {
  const AuthWidget({super.key});

  @override
  ConsumerState<AuthWidget> createState() => _AuthWidgetState();
}

class _AuthWidgetState extends ConsumerState<AuthWidget> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  user_models.UserRole _selectedRole = user_models.UserRole.student;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await ref
          .read(userManagementServiceProvider)
          .loginUser(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome back, ${user.displayName}!')),
          );
          // Navigate to home or refresh
          ref.invalidate(userManagementServiceProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed. Please check your credentials.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _displayNameController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
      }
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await ref
          .read(userManagementServiceProvider)
          .registerUser(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim(),
            phone: _phoneController.text.isNotEmpty
                ? _phoneController.text.trim()
                : null,
            role: _selectedRole,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created successfully! Welcome, ${user.displayName}!',
            ),
          ),
        );
        // Switch to login mode
        setState(() {
          _isLogin = true;
        });
        ref.invalidate(userManagementServiceProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await ref.read(userManagementServiceProvider).logoutUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
        ref.invalidate(userManagementServiceProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              _isLogin ? 'Welcome Back!' : 'Create Account',
              style: themeData.typography.headlineMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isLogin
                  ? 'Sign in to continue your learning journey'
                  : 'Join Math Genius and start your learning adventure',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Email Field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email address',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Display Name Field (Registration only)
            if (!_isLogin) ...[
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 16),

              // Phone Field (Registration only)
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone (Optional)',
                  hintText: 'Enter your phone number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Role Selection (Registration only)
              Text(
                'Account Type',
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: user_models.UserRole.values.map((role) {
                  return RadioListTile<user_models.UserRole>(
                    title: Text(_getRoleLabel(role)),
                    subtitle: Text(_getRoleDescription(role)),
                    value: role,
                    groupValue: _selectedRole,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Password Field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 16),

            // Confirm Password Field (Registration only)
            if (!_isLogin) ...[
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                obscureText: _obscureConfirmPassword,
              ),
              const SizedBox(height: 16),
            ],

            // Action Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_isLogin ? _login : _register),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isLogin ? 'Login' : 'Register',
                        style: themeData.typography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Toggle Mode Button
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isLogin = !_isLogin;
                        // Clear fields when switching modes
                        _emailController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                        _displayNameController.clear();
                        _phoneController.clear();
                      });
                    },
              child: Text(
                _isLogin
                    ? 'Don\'t have an account? Register'
                    : 'Already have an account? Login',
                style: themeData.typography.labelLarge.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Current User Info
            Consumer(
              builder: (context, ref, child) {
                return FutureBuilder<user_models.User?>(
                  future: ref
                      .read(userManagementServiceProvider)
                      .getCurrentUser(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final user = snapshot.data;
                    if (user == null) return const SizedBox.shrink();

                    return Card(
                      color: colorScheme.surface,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current User',
                              style: themeData.typography.titleLarge.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primary,
                                child: Text(
                                  user.displayName[0].toUpperCase(),
                                  style: themeData.typography.labelLarge
                                      .copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              title: Text(
                                user.displayName,
                                style: themeData.typography.labelLarge.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${user.email} • ${user.role.name}',
                                style: themeData.typography.bodySmall.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(user.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user.status.name.toUpperCase(),
                                  style: themeData.typography.labelSmall
                                      .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _logout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  foregroundColor: colorScheme.onError,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Logout'),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  String _getRoleLabel(user_models.UserRole role) {
    switch (role) {
      case user_models.UserRole.student:
        return 'Student';
      case user_models.UserRole.parent:
        return 'Parent';
      case user_models.UserRole.teacher:
        return 'Teacher';
      case user_models.UserRole.admin:
        return 'Administrator';
      case user_models.UserRole.guest:
        return 'Guest';
    }
  }

  String _getRoleDescription(user_models.UserRole role) {
    switch (role) {
      case user_models.UserRole.student:
        return 'Learn and practice math skills';
      case user_models.UserRole.parent:
        return 'Monitor and support your child\'s learning';
      case user_models.UserRole.teacher:
        return 'Create lessons and track student progress';
      case user_models.UserRole.admin:
        return 'Manage the entire platform';
      case user_models.UserRole.guest:
        return 'Limited access to basic features';
    }
  }

  Color _getStatusColor(AccountStatus status) {
    switch (status) {
      case AccountStatus.active:
        return Colors.green;
      case AccountStatus.inactive:
        return Colors.grey;
      case AccountStatus.suspended:
        return Colors.red;
      case AccountStatus.pending:
        return Colors.orange;
      case AccountStatus.deleted:
        return Colors.black;
    }
  }
}
