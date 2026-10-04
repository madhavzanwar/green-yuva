import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/case.dart';
import '../theme/app_theme.dart';

class CaseCard extends StatelessWidget {
  final Case caseData;
  final VoidCallback? onReview;

  const CaseCard({
    Key? key,
    required this.caseData,
    this.onReview,
  }) : super(key: key);

  Future<void> _openSourceUrl(BuildContext context) async {
    if (caseData.sourceUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(caseData.sourceUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: ${caseData.sourceUrl}'),
              backgroundColor: AppColors.dustyCoral,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: AppColors.dustyCoral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReview,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.solidBlack, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: AppColors.solidBlack,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.softSky,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: caseData.imageUrl != null && caseData.imageUrl!.isNotEmpty
                        ? Image.network(
                            caseData.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.science_rounded,
                              color: AppColors.solidBlack,
                              size: 26,
                            ),
                          )
                        : const Icon(
                            Icons.science_rounded,
                            color: AppColors.solidBlack,
                            size: 26,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caseData.personName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (caseData.location.toLowerCase().contains('india'))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.butterYellow,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: AppColors.solidBlack, width: 1.4),
                              ),
                              child: Text(
                                '🇮🇳 India Action',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.mintGreen,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: AppColors.solidBlack, width: 1.4),
                            ),
                            child: Text(
                              caseData.impact,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.solidBlack,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              caseData.story,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.solidBlack,
                height: 1.35,
              ),
            ),
            if (caseData.description != null && caseData.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                caseData.description!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.solidBlack.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: AppColors.solidBlack, thickness: 1.5, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.solidBlack),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          caseData.location,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.solidBlack.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _openSourceUrl(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.butterYellow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.solidBlack, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.solidBlack,
                          offset: Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Research Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 13,
                          color: AppColors.solidBlack,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
