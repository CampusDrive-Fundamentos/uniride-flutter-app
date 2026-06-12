import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DocumentImagePicker extends StatelessWidget {
  final String label;
  final File? selectedImage;
  final VoidCallback onImagePicked;

  const DocumentImagePicker({
    super.key,
    required this.label,
    required this.selectedImage,
    required this.onImagePicked,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onImagePicked,
      icon: Icon(
        selectedImage == null ? Icons.camera_alt : Icons.check_circle, 
        color: AppColors.primary
      ),
      label: Text(
        selectedImage == null ? label : 'Documento Seleccionado', 
        style: const TextStyle(color: AppColors.textPrimary)
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}