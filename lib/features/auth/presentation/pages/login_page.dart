import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_split_bill/core/router/app_router.dart';
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // --- Helper Function for Login ---
  Future<String?> _onLogin(LoginData data, BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    authBloc.add(AuthSignInRequested(email: data.name, password: data.password));

    // Wait for the state change (success or failure)
    return await authBloc.stream.firstWhere((state) {
      return state is AuthAuthenticated || state is AuthFailure;
    }).then((state) {
      if (state is AuthFailure) {
        return state.message; // Return error message to flutter_login
      }
      return null; // Return null on success
    }).catchError((_) {
      // Handle potential stream errors if needed, though unlikely here
      return 'An unexpected error occurred.';
    });
    // Note: A timeout could be added here for robustness
  }

  // --- Helper Function for Signup ---
  Future<String?> _onSignup(SignupData data, BuildContext context) async {
    final authBloc = context.read<AuthBloc>();

    // --- Password confirmation is usually handled by flutter_login's UI validation ---
    // flutter_login typically enforces the password match *before* calling onSignup
    // if you have configured the confirm password field correctly in the widget.
    // However, double-checking is safe if you aren't sure about the configuration.
    // We access the password from `data.password`. `data.confirmPassword` DOES NOT EXIST.
    // You'd typically rely on flutter_login's internal validation for this match.

    // Basic validation (should ideally be caught by form validation first)
    if (data.name == null || data.name!.isEmpty || !data.name!.contains('@')) {
      return "Please enter a valid email";
    }
    if (data.password == null || data.password!.isEmpty || data.password!.length < 6) {
      return "Password must be at least 6 characters";
    }

    // If you *really* need to manually check confirm password here (e.g., if passing it via additionalSignupData)
    // you would access it differently. But standard flutter_login handles this.
    // Example *if* you passed confirm password via additionalSignupData:
    // final confirmPassword = data.additionalSignupData?['confirm_password'];
    // if (data.password != confirmPassword) {
    //   return "Passwords do not match";
    // }

    authBloc.add(AuthSignUpRequested(email: data.name!, password: data.password!));

    // Wait for state change (logic remains the same)
    return await authBloc.stream.firstWhere((state) {
      return state is AuthFailure || state is AuthAuthenticated;
    }).then((state) {
      if (state is AuthFailure) {
        return state.message;
      }
      return null;
    }).catchError((_) {
      return 'An unexpected error occurred during sign up.';
    });
  }


  // --- Helper Function for Password Recovery ---
  Future<String?> _onRecoverPassword(String email, BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    authBloc.add(AuthRecoverPasswordRequested(email));

    // Wait for state change
    return await authBloc.stream.firstWhere((state) {
      return state is AuthPasswordResetEmailSent || state is AuthFailure;
    }).then((state) {
      if (state is AuthFailure) {
        return state.message; // Return error message
      }
      // Return null on success (flutter_login shows a default success message)
      return null;
    }).catchError((_) {
      return 'An unexpected error occurred during password recovery.';
    });
  }


  @override
  Widget build(BuildContext context) {
    // Listen for AuthFailure to show snackbars if needed (optional, flutter_login shows errors)
    // Use BlocBuilder only if you need to react to AuthLoading *outside* flutter_login's callbacks
    return Scaffold(
      // No AppBar needed as flutter_login provides its own UI
      body: FlutterLogin(
        title: 'Hyper Split Bill', // Your App Title
        // logo: const AssetImage('assets/images/ecorp.png'), // Add your logo asset
        onLogin: (data) => _onLogin(data, context),
        onSignup: (data) => _onSignup(data, context),
        onRecoverPassword: (email) => _onRecoverPassword(email, context),
        onSubmitAnimationCompleted: () {
          // Navigation is handled by GoRouter redirect based on AuthBloc state.
          // You could manually navigate here *if* redirect wasn't set up,
          // but it's better to rely on the redirect.
          print('Submit animation completed. Router should redirect if authenticated.');
        },
        // Configure theme, messages, etc.
        theme: LoginTheme(
          primaryColor: Theme.of(context).primaryColor,
          // accentColor: Colors.yellow,
          errorColor: Theme.of(context).colorScheme.error,
          titleStyle: TextStyle(
            // color: Colors.greenAccent,
            // fontFamily: 'Quicksand',
            letterSpacing: 4,
          ),
          // ... other theme customizations
        ),
        messages: LoginMessages(
          userHint: 'Email',
          passwordHint: 'Password',
          confirmPasswordHint: 'Confirm Password',
          loginButton: 'LOG IN',
          signupButton: 'REGISTER',
          forgotPasswordButton: 'Forgot password?',
          recoverPasswordButton: 'HELP ME',
          goBackButton: 'GO BACK',
          confirmPasswordError: 'Passwords do not match!',
          recoverPasswordDescription: 'We will send instructions to this email to reset your password.',
          recoverPasswordSuccess: 'Password recovery email sent successfully!', // Default message
          // ... other custom messages
        ),
      ),
    );
  }
}