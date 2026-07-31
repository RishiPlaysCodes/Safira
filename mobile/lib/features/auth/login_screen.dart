import 'package:flutter/material.dart';

import '../../repositories/settings_repository.dart';
import '../../services/auth_service.dart';

/// Login / Signup screen. On success, AuthService notifies listeners and the
/// AuthGate swaps to the HomeScreen automatically.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _settings = SettingsRepository();
  final _formKey = GlobalKey<FormState>();

  final _backendUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSignup = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillBackendUrl();
  }

  Future<void> _prefillBackendUrl() async {
    final url = await _settings.loadBackendUrl();
    if (url.isNotEmpty && mounted) {
      _backendUrlController.text = url;
    }
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final backendUrl = _backendUrlController.text.trim();
    // Persist backend URL and guardian phone so the home screen can use them.
    await _settings.save(
      parentPhone: _phoneController.text.trim(),
      backendUrl: backendUrl,
      destination: await _settings.loadDestination(),
    );

    String? error;
    if (_isSignup) {
      error = await widget.authService.signup(
        backendUrl: backendUrl,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
      );
    } else {
      error = await widget.authService.login(
        backendUrl: backendUrl,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (error != null && mounted) {
      setState(() => _error = error);
    }
    // On success, AuthGate rebuilds automatically via the AuthService listener.
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authService,
      builder: (context, _) {
        final loading = widget.authService.isLoading;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.shield_moon_outlined,
                          size: 64, color: Color(0xFF146C94)),
                      const SizedBox(height: 12),
                      Text(
                        'SafeRide Guardian',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSignup ? 'Create your account' : 'Welcome back',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _backendUrlController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Backend URL',
                          hintText: 'https://your-app.a.run.app',
                          prefixIcon: Icon(Icons.dns_outlined),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Backend URL is required';
                          final uri = Uri.tryParse(value);
                          if (uri == null || !uri.hasScheme) {
                            return 'Enter a valid URL (with http:// or https://)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Username is required'
                            : null,
                      ),
                      if (_isSignup) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (!_isSignup) return null;
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Email is required';
                            if (!value.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Guardian phone (parent)',
                            hintText: '+911234567890',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) {
                            if (!_isSignup) return null;
                            return (v ?? '').trim().isEmpty
                                ? 'Guardian phone is required'
                                : null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          final value = v ?? '';
                          if (value.isEmpty) return 'Password is required';
                          if (_isSignup && value.length < 10) {
                            return 'Use at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isSignup ? 'Create Account' : 'Login'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () => setState(() {
                                  _isSignup = !_isSignup;
                                  _error = null;
                                }),
                        child: Text(_isSignup
                            ? 'Already have an account? Login'
                            : 'New user? Create an account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
