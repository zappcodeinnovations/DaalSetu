import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

/// Building blocks of the offer card, the same look the buyer's Offers screen uses:
/// bordered card, small thumbnail, heart badge, status badge, a quantity | price box and
/// metadata chips. The seller's My Products card is built from these too.
BoxDecoration offerCardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? theme.cardColor : Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
      width: 1.2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Placeholder for an offer without photo or video.
class OfferNoMedia extends StatelessWidget {
  const OfferNoMedia({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF2C394F), Color(0xFF202B3D)]
              : const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.grain_rounded, size: 24, color: Color(0xFFEA580C)),
            const SizedBox(height: 2),
            Text(
              'DAAL',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfferHeartBadge extends StatelessWidget {
  const OfferHeartBadge({super.key, required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFE11D48).withValues(alpha: 0.15) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFFE11D48).withValues(alpha: 0.35) : const Color(0xFFFECDD3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, size: 11, color: Color(0xFFE11D48)),
          const SizedBox(width: 3.5),
          Text(
            count,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE11D48),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status pill tinted with [color] (green, red, amber ...).
class OfferStatusBadge extends StatelessWidget {
  const OfferStatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Small metadata chip: icon + text (bags, packing, location, date ...).
class OfferInfoChip extends StatelessWidget {
  const OfferInfoChip({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ConstrainedBox(
      // A long address wraps inside the chip instead of overflowing the card.
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 64),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 12, color: const Color(0xFFEA580C)),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Available Quantity | Offer Price" box shown under the card header.
class OfferHighlights extends StatelessWidget {
  const OfferHighlights({
    super.key,
    required this.qtyLabel,
    required this.qtyValue,
    required this.priceLabel,
    required this.priceValue,
  });

  final String qtyLabel;
  final String qtyValue;
  final String priceLabel;
  final String priceValue;

  Widget _half({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color tileColor,
    required String label,
    required String value,
    required Color valueColor,
    double valueSize = 13,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.w700, color: valueColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2235) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2D3B55) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _half(
            isDark: isDark,
            icon: IconlyLight.buy,
            iconColor: const Color(0xFFEA580C),
            tileColor: isDark ? const Color(0xFFEA580C).withValues(alpha: 0.15) : const Color(0xFFFFF7ED),
            label: qtyLabel,
            value: qtyValue,
            valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.only(right: 12),
            color: isDark ? const Color(0xFF2D3B55) : const Color(0xFFE2E8F0),
          ),
          _half(
            isDark: isDark,
            icon: IconlyLight.wallet,
            iconColor: const Color(0xFF059669),
            tileColor: isDark ? const Color(0xFF059669).withValues(alpha: 0.15) : const Color(0xFFECFDF5),
            label: priceLabel,
            value: priceValue,
            valueColor: isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C),
            valueSize: 13.5,
          ),
        ],
      ),
    );
  }
}
