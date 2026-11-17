import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FigmaField extends StatelessWidget {
  const FigmaField({
    required this.controller,
    required this.hintText,
    this.height = 48,
    this.minLines = 1,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final double height;
  final int minLines;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(minHeight: height),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        validator: validator,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.darkText,
          fontSize: 14,
          height: 1,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 14,
          ),
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
