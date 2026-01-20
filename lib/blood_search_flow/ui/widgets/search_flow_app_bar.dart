/// Search Flow App Bar
/// Custom app bar for blood search flow pages

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../apps/config/theme/ColorPages.dart';

class SearchFlowAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  final bool showClose;
  final List<Widget>? actions;

  const SearchFlowAppBar({
    super.key,
    required this.title,
    required this.onBack,
    this.showClose = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: onBack,
        icon: Icon(
          showClose ? Iconsax.close_circle : Iconsax.arrow_left_2,
          color: Colors.grey.shade800,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.ubuntu(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      centerTitle: true,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}
