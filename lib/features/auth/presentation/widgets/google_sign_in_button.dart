import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed, this.disabled = false});

  final VoidCallback onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: disabled ? null : onPressed,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Swap for the official multicolor "G" asset before release (Google branding rules).
          Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
          SizedBox(width: 10),
          Text('Continue with Google'),
        ],
      ),
    );
  }
}
