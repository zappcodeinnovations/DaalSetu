import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Curved Hero Header with warm saffron/amber gradient.
/// Implements [PreferredSizeWidget] so it can be passed directly to [Scaffold.appBar]
/// or used as a standalone top widget in a [Column] / [CustomScrollView].
class HeroHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? trailing;
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? bottom;
  final double bottomSpacing;
  final double? preferredHeight;
  final bool centerTitle;

  const HeroHeader({
    super.key,
    this.leading,
    this.trailing,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.bottom,
    this.bottomSpacing = 12,
    this.preferredHeight,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize {
    if (preferredHeight != null) {
      return Size.fromHeight(preferredHeight!);
    }
    double height = kToolbarHeight + 8 + bottomSpacing;
    if (subtitle != null) {
      height += 84;
    }
    if (bottom != null) {
      final bottomH = bottom is PreferredSizeWidget
          ? (bottom as PreferredSizeWidget).preferredSize.height
          : 56.0;
      height += bottomH + 8;
    }
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: preferredSize.height,
      flexibleSpace: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE65100), // Deep rich saffron
            Color(0xFFF57C00), // Vibrant amber orange
            Color(0xFFFFA000), // Warm gold highlight
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: topPadding + 8,
        left: 16,
        right: 16,
        bottom: bottomSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Navigation Row: Leading (Menu / Back) + Title/Logo + Trailing (Notification / Actions)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null)
                IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: leading!,
                )
              else
                const SizedBox(width: 40),
              if (titleWidget != null)
                Expanded(child: titleWidget!)
              else if (title != null && subtitle == null)
                Expanded(
                  child: Align(
                    alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        title!,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              if (trailing != null)
                IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: trailing!,
                )
              else
                const SizedBox(width: 40),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          if (bottom != null) ...[
            const SizedBox(height: 12),
            Theme(
              data: Theme.of(context).copyWith(
                tabBarTheme: TabBarThemeData(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
                  indicatorColor: Colors.white,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
              child: bottom!,
            ),
          ],
        ],
      ),
    ),
  );
}
}
