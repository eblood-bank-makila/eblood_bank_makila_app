import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../apps/config/theme/ColorPages.dart';

/// A pagination widget that shows page information and navigation controls
class PaginationWidget extends StatelessWidget {
  final int currentPage; // Zero-based page index
  final int? totalPages;
  final int? totalItems;
  final bool hasMorePages;
  final bool isLoading;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;
  
  const PaginationWidget({
    Key? key,
    required this.currentPage,
    this.totalPages,
    this.totalItems,
    required this.hasMorePages,
    this.isLoading = false,
    this.onNextPage,
    this.onPreviousPage,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Don't show the widget if we're on page 0 and there are no more pages
    if (currentPage == 0 && !hasMorePages) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous page button
          if (currentPage > 0)
            TextButton.icon(
              onPressed: isLoading ? null : onPreviousPage,
              icon: const Icon(Icons.navigate_before, size: 18),
              label: Text(
                'Précédent',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            )
          else
            const SizedBox(width: 80), // Placeholder to keep layout balanced
          
          // Page information
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page ${currentPage + 1}${totalPages != null ? '/$totalPages' : ''}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (totalItems != null)
                Text(
                  '$totalItems éléments',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          
          // Next page button
          if (hasMorePages)
            TextButton.icon(
              onPressed: isLoading ? null : onNextPage,
              icon: const Icon(Icons.navigate_next, size: 18),
              label: Text(
                'Suivant',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: ColorPages.COLOR_PRINCIPAL,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            )
          else
            const SizedBox(width: 80), // Placeholder to keep layout balanced
        ],
      ),
    );
  }
}

/// A simplified version that just shows a "Load More" button
class LoadMoreWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final bool hasMorePages;
  
  const LoadMoreWidget({
    Key? key,
    required this.isLoading,
    required this.onLoadMore,
    required this.hasMorePages,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!hasMorePages) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoading
          ? const CircularProgressIndicator(color: Colors.red)
          : ElevatedButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                'Charger plus',
                style: GoogleFonts.poppins(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
      ),
    );
  }
}