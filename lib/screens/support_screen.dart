import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  int _selectedAmount = 100;
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _launchUpiPayment(int amount) async {
    final upiUrl = 'upi://pay?pa=8080956037-2@ybl&pn=Green%20Yuva%20Foundation&am=$amount&cu=INR&tn=Support%20Climate%20Action';
    try {
      final uri = Uri.parse(upiUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        _showPaymentModal(amount);
      }
    } catch (_) {
      if (!mounted) return;
      _showPaymentModal(amount);
    }
  }

  void _showPaymentModal(int amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.paperCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.solidBlack, width: 3.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.solidBlack.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.volunteer_activism_rounded, color: AppColors.solidBlack, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Support Green Yuva',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.butterYellow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contribution Amount:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.solidBlack,
                    ),
                  ),
                  Text(
                    '₹$amount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.solidBlack,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Payment Option',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.solidBlack,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentOptionTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'UPI / Google Pay / PhonePe',
              subtitle: 'UPI ID: 8080956037-2@ybl',
              onTap: () {
                Navigator.pop(context);
                _showQrDialog(amount);
              },
            ),
            const SizedBox(height: 10),
            _buildPaymentOptionTile(
              icon: Icons.credit_card_rounded,
              title: 'Debit / Credit Card',
              subtitle: 'Visa, Mastercard, RuPay',
              onTap: () => _simulatePaymentSuccess(amount),
            ),
            const SizedBox(height: 10),
            _buildPaymentOptionTile(
              icon: Icons.account_balance_rounded,
              title: 'Net Banking',
              subtitle: 'All Major Indian Banks',
              onTap: () => _simulatePaymentSuccess(amount),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.solidBlack, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.solidBlack,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.softSky,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.solidBlack, width: 1.2),
              ),
              child: Icon(icon, color: AppColors.solidBlack, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solidBlack,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.solidBlack.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.solidBlack),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(int amount) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.paperCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.solidBlack, width: 2.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan & Pay ₹$amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.solidBlack,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scan with GPay, PhonePe, Paytm, or BHIM',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.solidBlack.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.solidBlack, width: 2.0),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: 'upi://pay?pa=8080956037-2@ybl&pn=Green%20Yuva&am=$amount&cu=INR&tn=Support%20Green%20Yuva',
                      version: QrVersions.auto,
                      size: 190,
                      backgroundColor: Colors.white,
                      errorStateBuilder: (cxt, err) {
                        return const Center(
                          child: Text(
                            'Could not generate QR code',
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      'UPI ID: 8080956037-2@ybl',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricMint,
                  foregroundColor: AppColors.solidBlack,
                  side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(double.infinity, 46),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _simulatePaymentSuccess(amount);
                },
                child: Text(
                  'I Have Completed Payment',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _simulatePaymentSuccess(int amount) {
    if (Navigator.canPop(context)) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.solidBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.butterYellow, width: 2.0),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.electricMint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Thank you for contributing ₹$amount! +100 Karma Coins earned 🌿',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.solidBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Support Green Yuva',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.solidBlack,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.butterYellow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.solidBlack, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.solidBlack,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco_rounded, size: 28, color: AppColors.solidBlack),
                      const SizedBox(width: 10),
                      Text(
                        'Power Youth Climate Action',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your contribution funds campus recycling drives, tree plantation kits, and student green innovation awards across India.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.solidBlack.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Select Contribution Amount',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.solidBlack,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [50, 100, 500].map((amount) {
                final isSelected = _selectedAmount == amount;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAmount = amount;
                        _customAmountController.clear();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.electricMint : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.solidBlack, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.solidBlack,
                            offset: isSelected ? const Offset(1, 1) : const Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '₹$amount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Pay Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.butterYellow,
                foregroundColor: AppColors.solidBlack,
                side: const BorderSide(color: AppColors.solidBlack, width: 2.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(double.infinity, 54),
                elevation: 0,
              ),
              onPressed: () => _launchUpiPayment(_selectedAmount),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Proceed to Contribute ₹$_selectedAmount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}