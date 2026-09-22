import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single quick-action tile: icon chip, title and optional subtitle.
///
/// The card sizes itself to its content, so a title that wraps to two lines or
/// a larger system font scale makes it taller instead of overflowing.
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.locked = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// Locked cards are dimmed and not tappable (RBAC gating).
  final bool locked;

  @override
  Widget build(BuildContext context) {
    // Mirror BloodBankHomePage's locked-card pattern: disable tap, dim
    // the icon colour, and wrap the whole card in Opacity.
    final effectiveColor = locked ? Colors.grey.shade400 : color;
    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: effectiveColor, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-column layout for [QuickActionCard]s.
///
/// Rows are laid out with [IntrinsicHeight] rather than a fixed
/// `childAspectRatio`: each row is as tall as its tallest card, so a title
/// that wraps or a larger system font scale can never overflow the tile.
/// Both cards in a row are stretched to the same height so the grid still
/// reads as a grid.
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({
    super.key,
    required this.cards,
    this.spacing = 12,
  });

  final List<Widget> cards;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      final hasSecond = i + 1 < cards.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[i]),
              SizedBox(width: spacing),
              // A lone trailing card keeps its column width instead of
              // stretching across the row.
              Expanded(child: hasSecond ? cards[i + 1] : const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}
