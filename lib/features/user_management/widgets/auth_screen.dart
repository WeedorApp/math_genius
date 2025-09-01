import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:email_validator/email_validator.dart';

import '../models/user_model.dart' as user_models;
import '../barrel.dart' as user_management;
import '../../../core/barrel.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  user_models.UserRole _selectedRole = user_models.UserRole.student;

  @override
  void initState() {
    super.initState();
    // Ensure _selectedRole is never guest when dropdown is used
    if (_selectedRole == user_models.UserRole.guest) {
      _selectedRole = user_models.UserRole.student;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Icon(
                          Icons.school,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Math Genius',
                          style: themeData.typography.headlineMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLogin
                              ? 'Welcome back!'
                              : 'Join the learning journey',
                          style: themeData.typography.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Form Fields
                        if (!_isLogin) ...[
                          _buildNameFields(themeData, colorScheme),
                          const SizedBox(height: 8),
                          _buildRoleSelector(themeData, colorScheme),
                          const SizedBox(height: 8),
                        ],

                        _buildEmailField(themeData, colorScheme),
                        const SizedBox(height: 8),
                        _buildPasswordField(themeData, colorScheme),
                        const SizedBox(height: 8),

                        if (!_isLogin) ...[
                          _buildConfirmPasswordField(themeData, colorScheme),
                          const SizedBox(height: 8),
                        ],

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Sign In' : 'Create Account',
                                    style: themeData.typography.labelLarge
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Toggle Login/Register
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _isLogin
                                    ? "Don't have an account? "
                                    : 'Already have an account? ',
                                style: themeData.typography.bodyMedium.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            TextButton(
                              onPressed: _toggleMode,
                              child: Text(
                                _isLogin ? 'Sign Up' : 'Sign In',
                                style: themeData.typography.labelLarge.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_isLogin) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _handleForgotPassword,
                            child: Text(
                              'Forgot Password?',
                              style: themeData.typography.labelMedium.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Trial Button for Guest Access
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _handleGuestAccess,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.secondary,
                              side: BorderSide(color: colorScheme.secondary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Try as Guest',
                              style: themeData.typography.labelLarge.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Test Firebase Connection Button
                        if (kDebugMode)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _testFirebaseConnection,
                              child: Text(
                                'Test Firebase Connection',
                                style: themeData.typography.labelSmall.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameFields(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'First name is required';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Last name is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'I am a:',
          style: themeData.typography.labelLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: DropdownButtonFormField<user_models.UserRole>(
            value: _selectedRole == user_models.UserRole.guest
                ? user_models.UserRole.student
                : _selectedRole,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              isDense: true,
            ),
            hint: Text(
              'Select your role',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            items: user_models.UserRole.values
                .where((role) => role != user_models.UserRole.guest)
                .map((role) {
                  return DropdownMenuItem<user_models.UserRole>(
                    value: role,
                    child: Tooltip(
                      message: _getRoleDescription(role),
                      child: Text(
                        _getRoleLabel(role),
                        style: themeData.typography.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                })
                .toList(),
            onChanged: (user_models.UserRole? value) {
              if (value != null && value != user_models.UserRole.guest) {
                setState(() {
                  _selectedRole = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email is required';
        }
        if (!EmailValidator.validate(value.trim())) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
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
        return 'Monitor your child\'s progress';
      case user_models.UserRole.teacher:
        return 'Create and manage learning content';
      case user_models.UserRole.admin:
        return 'Manage the learning platform';
      case user_models.UserRole.guest:
        return 'Limited access mode';
    }
  }

  void _handleGuestAccess() {
    // Navigate directly to home with guest access
    context.go('/home');
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _selectedRole = user_models.UserRole.student;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // For students, we'll navigate to class selection screen
    if (!_isLogin && _selectedRole == user_models.UserRole.student) {
      // Show privacy consent dialog first
      final privacyConsent = await _showPrivacyConsentDialog();
      if (!privacyConsent) {
        return;
      }

      // Navigate to class selection screen with registration data
      if (mounted) {
        context.go(
          '/class-selection',
          extra: {
            'userRole': _selectedRole,
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'displayName':
                '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                    .trim(),
          },
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = ref.read(
        user_management.userManagementServiceProvider,
      );

      // Log service type for debugging
      if (kDebugMode) {
        print('Auth screen: Using UserManagementService');
      }

      // Get current session to check if user is already logged in
      final currentSession = await userService.getCurrentSession();
      if (currentSession != null) {
        if (kDebugMode) {
          print('Auth screen: User already has active session');
        }
      }

      if (_isLogin) {
        // Login
        if (kDebugMode) {
          print('Auth screen: Attempting login...');
        }
        try {
          if (kDebugMode) {
            print('Auth screen: Calling loginUser method...');
          }
          final user = await userService.loginUser(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          if (kDebugMode) {
            print('Auth screen: Login successful, user: ${user?.displayName}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Auth screen: Login error: $e');
          }
          rethrow;
        }
        if (kDebugMode) {
          print('Auth screen: Login successful, navigating to home...');
        }

        // Navigate to home after successful login (will auto-redirect students)
        if (mounted) {
          if (kDebugMode) {
            print('Auth screen: Executing navigation to /home');
          }
          context.go('/home');
        }
      } else {
        // Register
        if (kDebugMode) {
          print('Auth screen: Attempting registration...');
        }

        // Show privacy consent dialog for non-student registrations
        if (_selectedRole != user_models.UserRole.student) {
          final privacyConsent = await _showPrivacyConsentDialog();
          if (!privacyConsent) {
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        try {
          if (kDebugMode) {
            print('Auth screen: Calling registerUser...');
          }
          final user = await userService.registerUser(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName:
                '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                    .trim(),
            role: _selectedRole,
          );

          if (kDebugMode) {
            print(
              'Auth screen: Registration successful, user: ${user.displayName}',
            );
          }

          // Navigate based on user role after successful registration
          if (mounted) {
            if (kDebugMode) {
              print('Auth screen: Navigating based on user role...');
            }
            // Redirect based on user role
            if (user.role == user_models.UserRole.student) {
              context.go('/student');
            } else {
              context.go('/home');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Auth screen: Registration error: $e');
          }
          rethrow;
        }
        if (kDebugMode) {
          print('Auth screen: Registration successful, navigating to home...');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Registration Error', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show privacy consent dialog
  Future<bool> _showPrivacyConsentDialog() async {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Privacy Consent',
                style: themeData.typography.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Math Genius collects and processes your data to provide personalized learning experiences.',
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'By continuing, you agree to our:',
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Privacy Policy\n• Terms of Service\n• Data Processing Consent',
                    style: themeData.typography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Decline',
                    style: themeData.typography.labelLarge.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: Text(
                    'Accept',
                    style: themeData.typography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Show error dialog with detailed information
  void _showErrorDialog(String title, String message) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    AdaptiveUISystem.showAdaptiveDialog(
      context: context,
      child: AlertDialog(
        title: Text(
          title,
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please try again or contact support if the problem persists.',
              style: themeData.typography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: themeData.typography.labelLarge.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      AdaptiveUISystem.showAdaptiveSnackBar(
        context: context,
        message: 'Please enter your email first',
        isError: true,
      );
      return;
    }

    try {
      final userService = ref.read(
        user_management.userManagementServiceProvider,
      );
      await userService.resetPassword(_emailController.text.trim());

      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Password reset email sent!',
        );
      }
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userService = ref.read(
        user_management.userManagementServiceProvider,
      );

      if (kDebugMode) {
        print('Auth screen: Testing Firebase connection...');
      }

      final isConnected = await userService.testFirebaseConnection();

      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: isConnected
              ? 'Firebase connection successful! ✅'
              : 'Firebase connection failed! ❌',
          isError: !isConnected,
        );
      }
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Firebase test error: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
