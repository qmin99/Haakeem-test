import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../models/file_models.dart';

/// Content widget for documents mode in sidebar
class DocumentsModeContent extends StatelessWidget {
  const DocumentsModeContent({
    Key? key,
    required this.legalDocuments,
    required this.onDocumentSelected,
    required this.onDocumentUpload,
  }) : super(key: key);

  final List<dynamic> legalDocuments;
  final void Function(UploadedFile?) onDocumentSelected;
  final VoidCallback onDocumentUpload;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Documents header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLarge,
              AppSizes.paddingSmall,
              AppSizes.paddingLarge,
              AppSizes.paddingSmall,
            ),
            child: Row(
              children: [
                Text(
                  'Documents',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (legalDocuments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSmall - 2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                    ),
                    child: Text(
                      '${legalDocuments.length}',
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Upload button with glassmorphism
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge,
              vertical: AppSizes.paddingSmall,
            ),
            child: GestureDetector(
              onTap: onDocumentUpload,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall + 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingXSmall),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
                      ),
                      child: const Icon(
                        Icons.upload_file_outlined,
                        color: AppColors.primaryGreen,
                        size: AppSizes.iconSmall,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Text(
                      'Upload Documents',
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.fontSizeMedium + 1,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Documents list
          Expanded(
            child: legalDocuments.isEmpty
                ? _buildEmptyDocumentsState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLarge,
                      0,
                      AppSizes.paddingLarge,
                      80,
                    ),
                    itemCount: legalDocuments.length,
                    itemBuilder: (context, index) {
                      final doc = legalDocuments[index];
                      return _buildDocumentItem(doc);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDocumentsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingXXLarge),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusXXLarge),
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: AppColors.primaryGreen.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSizes.paddingXLarge),
            Text(
              AppStrings.documentsEmpty,
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeXXLarge,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              AppStrings.documentsEmptySubtitle,
              style: GoogleFonts.inter(
                fontSize: AppSizes.fontSizeMedium + 1,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(dynamic doc) {
    // For now, just show a placeholder since we don't have the full document model
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
          onTap: () => onDocumentSelected(doc),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall + 2),
            ),
            child: Row(
              children: [
                Container(
                  width: AppSizes.iconLarge,
                  height: AppSizes.iconLarge,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusXSmall),
                  ),
                  child: const Icon(
                    Icons.description,
                    size: 11,
                    color: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSmall + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document', // Placeholder name
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.fontSizeMedium,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '1.2 MB', // Placeholder size
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.fontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
