import 'package:flutter/material.dart';
import '../models/user.dart';

class SocialLoginButton extends StatelessWidget {
  final SocialProvider provider;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(icon, color: textColor, size: 22),
              ),
            ),
            Text(
              '${provider.label}로 시작하기',
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
