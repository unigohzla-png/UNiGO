import 'package:flutter/material.dart';

class GlassInputBox extends StatelessWidget {
  final String value;
  final IconData? icon;

  const GlassInputBox({super.key, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: "IBMPlexSans",
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          if (icon != null) Icon(icon, size: 18, color: Colors.black54),
        ],
      ),
    );
  }
}

