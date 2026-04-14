import 'package:flutter/material.dart';

void showCustomAlert(BuildContext context, String title, String message, {bool isError = true}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
             isError ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isError ? Colors.redAccent : const Color(0xFF4A148C),
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isError ? Colors.redAccent : const Color(0xFF4A148C),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Entendido', style: TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    ),
  );
}
