import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../models/file_models.dart';

/// Widget that displays an icon based on file type
class FileTypeIcon extends StatelessWidget {
  const FileTypeIcon({
    Key? key,
    required this.fileType,
    this.size = AppSizes.iconLarge,
    this.showBackground = true,
  }) : super(key: key);

  final MyFileType fileType;
  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconForFileType(fileType);
    final color = _getColorForFileType(fileType);

    return Container(
      width: size,
      height: size,
      decoration: showBackground ? BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ) : null,
      child: Icon(
        iconData,
        size: size * 0.6,
        color: color,
      ),
    );
  }

  IconData _getIconForFileType(MyFileType fileType) {
    switch (fileType) {
      case MyFileType.pdf:
        return Icons.picture_as_pdf;
      case MyFileType.doc:
      case MyFileType.docx:
        return Icons.description;
      case MyFileType.txt:
        return Icons.text_fields;
      case MyFileType.jpeg:
      case MyFileType.png:
        return Icons.image;
      case MyFileType.other:
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getColorForFileType(MyFileType fileType) {
    switch (fileType) {
      case MyFileType.pdf:
        return const Color(0xFFFF5722); // Deep Orange
      case MyFileType.doc:
      case MyFileType.docx:
        return AppColors.accentBlue;
      case MyFileType.txt:
        return AppColors.accentPurple;
      case MyFileType.jpeg:
      case MyFileType.png:
        return AppColors.accentGreen;
      case MyFileType.other:
      default:
        return AppColors.textSecondary;
    }
  }
}

