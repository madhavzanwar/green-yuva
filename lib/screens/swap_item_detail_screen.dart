import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/swap_item.dart';
import '../services/yuvaswap_service.dart';
import '../theme/app_theme.dart';

class SwapItemDetailScreen extends StatefulWidget {
  final SwapItem item;

  const SwapItemDetailScreen({super.key, required this.item});

  @override
  State<SwapItemDetailScreen> createState() => _SwapItemDetailScreenState();
}

class _SwapItemDetailScreenState extends State<SwapItemDetailScreen> {
  final TextEditingController _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _showRequestDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.paperCream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.solidBlack, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.solidBlack,
                offset: Offset(0, -4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.solidBlack,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.item.swapType == SwapType.freeGiveaway
                    ? 'Claim Free Item'
                    : 'Propose Swap Exchange',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Send a note to ${widget.item.donorName} with your convenient campus pickup spot or exchange offer.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(2.5, 3.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _msgController,
                  maxLines: 3,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.solidBlack,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Hi! I am a 1st year student at ${widget.item.campusName}. Can we meet at the campus library?',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.solidBlack.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              NeoButton(
                text: 'Send Request (+25 Karma Coins)',
                leading: const Icon(Icons.send_rounded, color: AppColors.solidBlack, size: 20),
                color: AppColors.butterYellow,
                textColor: AppColors.solidBlack,
                onPressed: () {
                  final note = _msgController.text;
                  YuvaSwapService().requestItem(
                    widget.item.id,
                    note,
                  );
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  setState(() {});
                  _showExchangeCoordinatorDialog(context, note);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showExchangeCoordinatorDialog(BuildContext context, String userNote) {
    final cleanNote = userNote.trim().isNotEmpty
        ? userNote.trim()
        : 'Can we meet at the campus library or canteen to coordinate handover?';
    final messageText =
        'Hi ${widget.item.donorName}! I requested your item "${widget.item.title}" on GreenYuva YuvaSwap. $cleanNote';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.sageGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.solidBlack, width: 1.5),
              ),
              child: const Icon(Icons.handshake_rounded, color: AppColors.solidBlack, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus Exchange',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: AppColors.solidBlack,
                    ),
                  ),
                  Text(
                    'Request sent • +25 Karma Coins! 🪙',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.leafGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coordinate handover directly with ${widget.item.donorName}:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 10),

              // Pre-filled Handover Note Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.paperCream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.solidBlack, width: 1.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HANDOVER MESSAGE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppColors.mutedText,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: messageText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Message copied to clipboard!'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.copy_rounded, size: 14, color: AppColors.solidBlack),
                              SizedBox(width: 4),
                              Text(
                                'Copy Note',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.solidBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      messageText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.solidBlack,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // WhatsApp Chat Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
                  ),
                ),
                onPressed: () async {
                  final waUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(messageText)}');
                  try {
                    final launched = await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                    if (!launched) throw Exception('Could not launch WhatsApp');
                  } catch (e) {
                    Clipboard.setData(ClipboardData(text: messageText));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Could not launch WhatsApp. Note copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Open WhatsApp Chat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campus Handover Checklist
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.solidBlack, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.solidBlack),
                        const SizedBox(width: 6),
                        Text(
                          'Campus Handover Checklist',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildChecklistRow(Icons.place_outlined, 'Meet in public zones (Canteen, Library, SAC)'),
                    const SizedBox(height: 4),
                    _buildChecklistRow(Icons.check_box_outlined, 'Inspect item condition before accepting'),
                    const SizedBox(height: 4),
                    _buildChecklistRow(Icons.money_off_rounded, 'Zero cash exchange — 100% circular campus barter'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardWhite,
              foregroundColor: AppColors.solidBlack,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.solidBlack, width: 1.5),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Done',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.solidBlack),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.solidBlack.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
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
                child: const Icon(Icons.arrow_back_rounded, color: AppColors.solidBlack, size: 20),
              ),
            ),
          ),
        ),
        title: Text(
          'Swap Details',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.solidBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: PaperGridBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image with 2px solid black border & hard shadow
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(3.5, 4.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.sageGreen.withValues(alpha: 0.3),
                            child: const Center(
                              child: Icon(Icons.school_rounded, color: AppColors.solidBlack, size: 54),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.solidBlack, width: 2.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.swapType == SwapType.freeGiveaway
                                    ? Icons.volunteer_activism
                                    : Icons.sync_alt,
                                size: 14,
                                color: AppColors.solidBlack,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.swapTypeDisplay,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.solidBlack,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.butterYellow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.solidBlack, width: 2.0),
                          ),
                          child: Text(
                            item.conditionDisplay,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.solidBlack,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title & Campus
              Text(
                item.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.solidBlack,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.school_rounded, size: 18, color: AppColors.solidBlack),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.campusName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Environmental Impact Card (NeoCard in Sage Green)
              NeoCard(
                color: AppColors.sageGreen,
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eco_rounded, color: AppColors.solidBlack, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Circular Impact Metrics',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric(
                          Icons.delete_sweep_rounded,
                          '${item.wasteDivertedKg} kg',
                          'Landfill Saved',
                        ),
                        Container(height: 36, width: 2, color: AppColors.solidBlack),
                        _buildMetric(
                          Icons.cloud_done_rounded,
                          '${item.co2SavedKg} kg',
                          'CO₂ Prevented',
                        ),
                        Container(height: 36, width: 2, color: AppColors.solidBlack),
                        _buildMetric(
                          Icons.monetization_on_rounded,
                          '₹0 Free',
                          'Student Cost',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'ITEM DETAILS',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 8),
              NeoCard(
                color: AppColors.cardWhite,
                radius: 16,
                padding: const EdgeInsets.all(16),
                child: Text(
                  item.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.solidBlack,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Swap Preference if any
              if (item.swapPreference != null && item.swapPreference!.isNotEmpty) ...[
                Text(
                  'EXCHANGE PREFERENCE',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.8,
                    color: AppColors.solidBlack,
                  ),
                ),
                const SizedBox(height: 8),
                NeoCard(
                  color: AppColors.butterYellow,
                  radius: 16,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    item.swapPreference!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Donor Profile snippet
              Text(
                'LISTED BY PEER',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 8),
              NeoCard(
                color: AppColors.cardWhite,
                radius: 16,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.dustyCoral,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.solidBlack, width: 2.0),
                      ),
                      child: Center(
                        child: Text(
                          item.donorName.isNotEmpty ? item.donorName[0] : 'S',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.donorName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.solidBlack,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.butterYellow,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.solidBlack, width: 1.2),
                                ),
                                child: Text(
                                  '${item.donorKarmaScore} Karma Coins',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.solidBlack,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.sageGreen,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.solidBlack, width: 1.2),
                                ),
                                child: Text(
                                  'Verified Student',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
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
              ),
              const SizedBox(height: 28),

              // Action Button
              NeoButton(
                text: item.status == 'requested'
                    ? 'Request Pending with Donor'
                    : (item.swapType == SwapType.freeGiveaway
                        ? 'Request Free Item'
                        : 'Propose Swap Exchange'),
                leading: Icon(
                  item.status == 'requested'
                      ? Icons.hourglass_top_rounded
                      : (item.swapType == SwapType.freeGiveaway
                          ? Icons.handshake_rounded
                          : Icons.swap_horiz_rounded),
                  color: AppColors.solidBlack,
                  size: 20,
                ),
                color: (item.status == 'requested' ||
                        item.status == 'completed' ||
                        item.donorId == 'current_user')
                    ? Colors.grey[300]!
                    : AppColors.butterYellow,
                textColor: AppColors.solidBlack,
                height: 54,
                onPressed: item.status == 'requested' ||
                        item.status == 'completed' ||
                        item.donorId == 'current_user'
                    ? null
                    : () => _showRequestDialog(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.solidBlack, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.solidBlack,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.solidBlack.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
