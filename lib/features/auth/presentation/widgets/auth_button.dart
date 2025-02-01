import 'package:datazen/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';


class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isInverted;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isInverted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: isInverted ? Pallete.whiteColor : Pallete.primaryColor,
        foregroundColor: isInverted ? Pallete.primaryColor : Pallete.whiteColor,
        minimumSize: const Size(200, 38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Pallete.primaryColor,
            width: 3,
          ),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
            ),
    );
  }
}
