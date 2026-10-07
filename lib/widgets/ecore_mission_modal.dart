import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ecore.dart';
import '../models/user.dart';
import '../screens/mission_proof_screen.dart';
import '../theme/app_theme.dart';

class EcoreMissionModal extends StatefulWidget {
  final Ecore ecore;
  final AppUser user;
  final VoidCallback onMissionCompleted;

  const EcoreMissionModal({
    super.key,
    required this.ecore,
    required this.user,
    required this.onMissionCompleted,
  });

  @override
  State<EcoreMissionModal> createState() => _EcoreMissionModalState();
}

class _EcoreMissionModalState extends State<EcoreMissionModal> {
  Future<void> _openCameraVerification(EcoreMission mission) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MissionProofScreen(
          ecore: widget.ecore,
          mission: mission,
          user: widget.user,
        ),
      ),
    );

    if (result == true && mounted) {
      widget.onMissionCompleted();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.paperCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(
          top: BorderSide(color: AppColors.solidBlack, width: 2.5),
          left: BorderSide(color: AppColors.solidBlack, width: 2.0),
          right: BorderSide(color: AppColors.solidBlack, width: 2.0),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.solidBlack,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.ecore.isConquered ? AppColors.mintGreen : AppColors.butterYellow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.solidBlack, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.solidBlack,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.hub_rounded, color: AppColors.solidBlack, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ecore.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.solidBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.ecore.missions.length} Action Quests • ${widget.ecore.totalPoints} Karma Coins Pool',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.solidBlack.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.ecore.isConquered ? AppColors.mintGreen : AppColors.dustyCoral,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.solidBlack, width: 1.5),
                  ),
                  child: Text(
                    widget.ecore.isConquered ? 'CONQUERED' : 'ACTIVE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // GPS Directions Action Bar (SchemeSetu style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final url = 'https://www.google.com/maps/dir/?api=1&destination=${widget.ecore.latitude},${widget.ecore.longitude}';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.electricMint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.solidBlack, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.solidBlack,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions_rounded, size: 18, color: AppColors.solidBlack),
                          const SizedBox(width: 8),
                          Text(
                            'Get GPS Directions to Campus ↗',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          const Divider(color: AppColors.solidBlack, thickness: 1.5),

          // Missions list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.ecore.missions.length,
              itemBuilder: (context, index) {
                final mission = widget.ecore.missions[index];
                return _buildMissionCard(mission);
              },
            ),
          ),

          // Bottom Close button
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardWhite,
                  foregroundColor: AppColors.solidBlack,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
                  ),
                ),
                child: Text(
                  'Dismiss Hub',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(EcoreMission mission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: NeoCard(
        color: AppColors.pureWhite,
        radius: 16,
        borderWidth: 2.0,
        shadowOffset: const Offset(2.5, 3),
        padding: const EdgeInsets.all(12),
        onTap: () => _openCameraVerification(mission),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.paperCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.solidBlack, width: 1.6),
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.leafGreen, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+${mission.points} Karma Coins',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.leafGreen,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _openCameraVerification(mission),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.solidBlack, width: 1.8),
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
                    const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.solidBlack),
                    const SizedBox(width: 4),
                    Text(
                      'Verify 📸',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
