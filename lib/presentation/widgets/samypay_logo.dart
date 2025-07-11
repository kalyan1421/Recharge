import 'package:flutter/material.dart';

class SamyPayLogo extends StatelessWidget {
  final double size;
  final bool showText;
  
  const SamyPayLogo({
    super.key,
    this.size = 100,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Colorful swirl design
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6C63FF), // Purple
                  Color(0xFF03DAC6), // Cyan
                  Color(0xFFFF6B35), // Orange
                  Color(0xFFF7931E), // Yellow
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          if (showText)
            Text(
              'SamyPay',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
} 