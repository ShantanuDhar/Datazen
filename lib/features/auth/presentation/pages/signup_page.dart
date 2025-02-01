import 'package:datazen/core/theme/app_pallete.dart';
import 'package:datazen/core/utils/loader.dart';
import 'package:datazen/core/utils/snackbar.dart';
import 'package:datazen/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:datazen/features/auth/presentation/widgets/auth_button.dart';
import 'package:datazen/features/auth/presentation/widgets/auth_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cpasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with Background Image
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Image(
                            image: AssetImage('assets/images/authBgImage.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Main Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthFailure) {
                      showSnackbar(context, state.message);
                    }
                    if (state is AuthSuccess) {
                      showSnackbar(context, "Account created successfully");
                      // Navigate to the next page if needed
                    }
                  },
                  builder: (context, state) {
                    if (state is AuthLoading) {
                      return const Loader();
                    }
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title Section
                        Column(
                          children: [
                            const Text(
                              "Create Account!",
                              style: TextStyle(
                                fontSize: 35,
                                fontWeight: FontWeight.w600,
                                color: Pallete.primaryColor,
                              ),
                            ),
                            Text(
                              "Enter your details to get started!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Pallete
                                    .greyColor, // Updated color for consistency
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              AuthTextfield(
                                controller: firstNameController,
                                text: 'First Name',
                              ),
                              const SizedBox(height: 20),
                              AuthTextfield(
                                controller: middleNameController,
                                text: 'Middle Name',
                              ),
                              const SizedBox(height: 20),
                              AuthTextfield(
                                controller: lastNameController,
                                text: 'Last Name',
                              ),
                              const SizedBox(height: 20),
                              AuthTextfield(
                                controller: emailController,
                                text: 'Email',
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              AuthTextfield(
                                controller: passwordController,
                                text: 'Password',
                                isPassword: true,
                              ),
                              const SizedBox(height: 20),
                              AuthTextfield(
                                controller: cpasswordController,
                                text: 'Confirm Password',
                                isPassword: true,
                              ),
                            ],
                          ),
                        ),
                        // Sign Up Button and Other Actions
                        Column(
                          children: [
                            AuthButton(
                              text: 'Sign Up',
                              onPressed: () {
                                context.read<AuthBloc>().add(AuthSignUp(
                                      emailController.text.trim(),
                                      passwordController.text.trim(),
                                      firstNameController.text.trim(),
                                      lastNameController.text.trim(),
                                      middleNameController.text.trim(),
                                    ));
                              },
                            ),
                            const SizedBox(height: 20),
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                text: "By continuing you are agreeing to the ",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                children: [
                                  TextSpan(
                                    text: "Terms of Service",
                                    style: TextStyle(
                                      color: Pallete.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " and ",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  TextSpan(
                                    text: "Privacy Policy",
                                    style: TextStyle(
                                      color: Pallete.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Divider(color: Colors.grey)),
                                const Text("Or sign in with Google"),
                                Expanded(child: Divider(color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AuthButton(
                              text: 'Continue with Google',
                              onPressed: () {
                                context
                                    .read<AuthBloc>()
                                    .add(AuthGoogleSignIn());
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already have an account?",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      color: Pallete.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
