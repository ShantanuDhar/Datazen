import 'package:datazen/components/sp_layout.dart';
import 'package:datazen/core/theme/app_pallete.dart';
import 'package:datazen/core/utils/snackbar.dart';
import 'package:datazen/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthEmailVerified) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const LayoutPage(),
          ));
        } else if (state is AuthFailure) {
          showSnackbar(context, state.message); // Use custom Snackbar
        } else if (state is AuthEmailVerificationInProgress) {
          showSnackbar(context, 'Verification in progress. Please check your email.');
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header with Background Image
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: const Row(
                    children: [
                      Expanded(
                        child: Image(
                          image: AssetImage('assets/images/authBgImage.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Main Content
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeader(),
                        _buildActionButtons(state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          "Verify your email!",
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.w800,
            color: Pallete.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "Please verify your email to continue",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Pallete.greyColor, // Ensure consistent color
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons(AuthState state) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: state is AuthLoading
                ? null
                : () {
                    context.read<AuthBloc>().add(AuthEmailVerification());
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: state is AuthLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Verify Email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: state is AuthLoading
              ? null
              : () {
                  context.read<AuthBloc>().add(AuthEmailVerification());
                },
          child: const Text(
            'Resend Email',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Pallete.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
