import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens replicating the exact Neo-Brutalist & Pop-Papercraft aesthetic
class AppColors {
  // Signature Palette from Reference
  static const Color paperCream = Color(0xFFF3EBDD);   // Base warm graph-paper cream
  static const Color dustyCoral = Color(0xFFE88C7D);   // Terracotta pink-red accent
  static const Color sageGreen = Color(0xFFC3D9A0);    // Pastel sage green
  static const Color butterYellow = Color(0xFFFBE285); // Warm butter yellow
  static const Color cardWhite = Color(0xFFFDFAF4);    // Off-white / cream fill
  static const Color pureWhite = Colors.white;
  static const Color solidBlack = Color(0xFF181818);   // Pure solid black for 2px borders, text, shadows
  static const Color gridLine = Color(0xFFE2D7C3);     // Subtle graph-paper grid stroke
  static const Color mutedText = Color(0xFF6E6E6E);    // Secondary / placeholder text

  // Functional Semantic Aliases for compatibility
  static const Color forestGreen = solidBlack;
  static const Color leafGreen = Color(0xFF2E6F40);
  static const Color emeraldGreen = sageGreen;
  static const Color mintGreen = Color(0xFFD8EAC2);
  static const Color electricMint = mintGreen;
  static const Color softSprout = paperCream;
  static const Color paleMint = Color(0xFFE5EED8);

  static const Color skyBlue = Color(0xFF7BAED5);
  static const Color softSky = Color(0xFFE0EDF8);
  static const Color paleSky = Color(0xFFEAF2F8);
  static const Color deepOcean = solidBlack;

  static const Color earthBrown = solidBlack;
  static const Color terracotta = dustyCoral;
  static const Color warmCream = paperCream;
  static const Color subtleGray = Color(0xFFEBE6DC);

  static const Color sunAmber = dustyCoral;
  static const Color warmGold = butterYellow;

  // Dark Theme support
  static const Color darkForestBg = Color(0xFF181B18);
  static const Color darkForestCard = Color(0xFF232823);
  static const Color darkForestCardBorder = Color(0xFF384038);
}

class AppGradients {
  static const LinearGradient lightNatureMesh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF3EBDD),
      Color(0xFFF3EBDD),
    ],
  );

  static const LinearGradient skyEarthGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.paperCream, AppColors.paperCream],
  );

  static const LinearGradient heroGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.sageGreen, AppColors.sageGreen],
  );

  static const LinearGradient amberGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.butterYellow, AppColors.butterYellow],
  );

  static const LinearGradient oceanSkyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.skyBlue, AppColors.skyBlue],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.solidBlack,
      scaffoldBackgroundColor: AppColors.paperCream,
      colorScheme: const ColorScheme.light(
        primary: AppColors.solidBlack,
        secondary: AppColors.dustyCoral,
        tertiary: AppColors.butterYellow,
        surface: AppColors.cardWhite,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.solidBlack,
        ),
        iconTheme: const IconThemeData(color: AppColors.solidBlack),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.butterYellow,
          foregroundColor: AppColors.solidBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.solidBlack, width: 2.0),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}

/// Custom painter for the faint graph-paper grid texture across the background
class GridPaperPainter extends CustomPainter {
  final Color lineColor;
  final double step;

  const GridPaperPainter({
    this.lineColor = const Color(0xFFE2D7C3),
    this.step = 26.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPaperPainter oldDelegate) => false;
}

/// Full-screen ambient graph-paper background (replaces EcoBackground)
class PaperGridBackground extends StatelessWidget {
  final Widget child;

  const PaperGridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.paperCream,
      child: CustomPaint(
        painter: const GridPaperPainter(),
        child: child,
      ),
    );
  }
}

/// Backward compatibility alias
typedef EcoBackground = PaperGridBackground;

/// Signature Neo-Brutalist Sticker Card (Solid fill, 2px solid black border, 0-blur hard offset shadow)
class NeoCard extends StatefulWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  final double borderWidth;
  final Offset shadowOffset;
  final double? width;
  final double? height;

  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.margin,
    this.radius = 20.0,
    this.onTap,
    this.borderWidth = 2.0,
    this.shadowOffset = const Offset(3.5, 4.0),
    this.width,
    this.height,
  });

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.cardWhite;
    final currentOffset = _isPressed ? const Offset(1.5, 1.5) : widget.shadowOffset;

    Widget cardContent = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: AppColors.solidBlack,
          width: widget.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.solidBlack,
            offset: currentOffset,
            blurRadius: 0, // Hard shadow
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      cardContent = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: cardContent,
      );
    }

    if (widget.margin != null) {
      return Padding(padding: widget.margin!, child: cardContent);
    }
    return cardContent;
  }
}

/// Compatibility aliases for existing GlassCard/GlassContainer
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 20,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      radius: radius,
      padding: padding,
      margin: margin,
      onTap: onTap,
      color: color ?? AppColors.cardWhite,
      child: child,
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 20,
    this.blurSigma = 0,
    this.padding,
    this.margin,
    this.color,
    this.border,
    this.shadows,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      radius: radius,
      padding: padding,
      margin: margin,
      onTap: onTap,
      color: color ?? AppColors.cardWhite,
      width: width,
      height: height,
      child: child,
    );
  }
}

/// Signature Neo-Brutalist Button (Butter yellow or white fill, 2px black border, hard offset shadow)
class NeoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final Widget? leading;
  final double height;
  final double radius;
  final double fontSize;

  const NeoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = AppColors.butterYellow,
    this.textColor = AppColors.solidBlack,
    this.leading,
    this.height = 52.0,
    this.radius = 18.0,
    this.fontSize = 16.0,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final shadowOffset = _isPressed ? const Offset(1.5, 1.5) : const Offset(3.5, 4.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: Transform.translate(
        offset: _isPressed ? const Offset(1.5, 1.5) : Offset.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: AppColors.solidBlack, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.solidBlack,
                offset: shadowOffset,
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category Pill Chip (Solid dusty coral when active, white with black outline when inactive)
class NeoPill extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final IconData? icon;

  const NeoPill({
    super.key,
    required this.text,
    this.isSelected = false,
    this.onTap,
    this.selectedColor = AppColors.dustyCoral,
    this.unselectedColor = AppColors.pureWhite,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? selectedColor : unselectedColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.solidBlack, width: 2.0),
        boxShadow: isSelected
            ? const [
                BoxShadow(
                  color: AppColors.solidBlack,
                  offset: Offset(2.0, 2.5),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.solidBlack),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.solidBlack,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

/// Compatibility alias for EcoBadge
class EcoBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final Color? textColor;

  const EcoBadge({
    super.key,
    required this.text,
    this.icon,
    this.color = AppColors.butterYellow,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.solidBlack, width: 1.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor ?? AppColors.solidBlack),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor ?? AppColors.solidBlack,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compatibility alias for EcoCard
class EcoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Border? border;
  final VoidCallback? onTap;
  final double radius;

  const EcoCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.border,
    this.onTap,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      radius: radius,
      padding: padding,
      color: color ?? AppColors.cardWhite,
      onTap: onTap,
      child: child,
    );
  }
}

/// Micro-animation pulse widget for live indicators
class PulseWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const PulseWidget({
    super.key,
    required this.child,
    this.minScale = 0.96,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

/// Standard Neo-Brutalist Back Button
class NeoBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  const NeoBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed ?? () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.cardWhite,
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
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.solidBlack,
          size: 20,
        ),
      ),
    );
  }
}

/// Pulsating Live Indicator Badge for AQI, sensor streams, and verified MRV tags
class NeoPulseBadge extends StatelessWidget {
  final String label;
  final Color badgeColor;
  final Color dotColor;
  final Color textColor;
  final IconData? icon;

  const NeoPulseBadge({
    super.key,
    required this.label,
    this.badgeColor = AppColors.butterYellow,
    this.dotColor = const Color(0xFF2E7D32),
    this.textColor = AppColors.solidBlack,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.solidBlack, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.solidBlack,
            offset: Offset(2.0, 2.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseWidget(
            minScale: 0.8,
            maxScale: 1.25,
            duration: const Duration(milliseconds: 1000),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.solidBlack, width: 1.2),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Neo-Brutalist Metric Card (used for MRV calculations, waste diverted, CO2 avoided)
class NeoMetricCard extends StatelessWidget {
  final String value;
  final String label;
  final String? subtext;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const NeoMetricCard({
    super.key,
    required this.value,
    required this.label,
    this.subtext,
    required this.icon,
    this.color = AppColors.cardWhite,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      color: color,
      radius: 18,
      borderWidth: 2.0,
      shadowOffset: const Offset(3.0, 3.5),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.solidBlack, width: 1.6),
                ),
                child: Icon(icon, size: 18, color: AppColors.solidBlack),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.mutedText),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.solidBlack,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.solidBlack,
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(
              subtext!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Celebratory Sticker Modal Dialog with Neo-Brutalist tactile styling
Future<T?> showNeoStickerModal<T>({
  required BuildContext context,
  required String stickerEmoji,
  required String title,
  required String description,
  String? badgeLabel,
  Widget? customContent,
  String actionText = 'Understood!',
  VoidCallback? onAction,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          NeoCard(
            color: AppColors.cardWhite,
            radius: 26,
            borderWidth: 2.5,
            shadowOffset: const Offset(4.0, 5.0),
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badgeLabel != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.butterYellow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.solidBlack, width: 1.8),
                    ),
                    child: Text(
                      badgeLabel.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.solidBlack.withValues(alpha: 0.8),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (customContent != null) ...[
                  const SizedBox(height: 14),
                  customContent,
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: NeoButton(
                    text: actionText,
                    color: AppColors.butterYellow,
                    onPressed: () {
                      Navigator.pop(ctx);
                      onAction?.call();
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -26,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.dustyCoral,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.solidBlack, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.solidBlack,
                    offset: Offset(2.5, 3.0),
                    blurRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                stickerEmoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

