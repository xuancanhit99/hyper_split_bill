import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_split_bill/core/router/app_router.dart';
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      // Optionally add more validation like password match here before dispatching
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red),
        );
        return;
      }
      context.read<AuthBloc>().add(AuthSignUpRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Sign Up Failed: ${state.message}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
          } else if (state is AuthAuthenticated) {
            // Optional: Show success message before redirect (redirect handled by router)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign Up Successful!'), backgroundColor: Colors.green),
            );
          }
          // Consider adding a state for AuthVerificationPending if needed
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Create Account', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) { /* ... same as login ... */
                      if (value == null || value.isEmpty || !value.contains('@')) { return 'Please enter a valid email';} return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: (value) { /* ... same as login ... */
                      if (value == null || value.isEmpty || value.length < 6) { return 'Password must be at least 6 characters';} return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField( // Confirm Password
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      ),
                    ),
                    obscureText: !_isConfirmPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) { return 'Please confirm your password';}
                      if (value != _passwordController.text) { return 'Passwords do not match'; }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>( // Loading state
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return ElevatedButton.icon(
                        icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.person_add),
                        label: Text(isLoading ? 'Creating Account...' : 'Sign Up'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: isLoading ? null : _signUp,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go(AppRouter.loginPath), // Go back to Login
                    child: const Text("Already have an account? Sign In"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}