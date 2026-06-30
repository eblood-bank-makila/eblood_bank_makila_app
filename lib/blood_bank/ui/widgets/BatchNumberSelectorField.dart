import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/blood_bank/controllers/batch_numbers_provider.dart';
import 'package:eblood_bank_mak_app/blood_bank/controllers/selected_batch_number_provider.dart';

/// Sentinel popped by the sheet when the currently-selected batch number was
/// deleted, so the caller clears its selection (distinct from `null`, which
/// just means the sheet was dismissed).
const String kBatchSelectionCleared = '__batch_cleared__';

/// Reusable "numéro de lot" (batch number) searchable selector.
///
/// Renders a tappable field (participating in the enclosing [Form] via a
/// [FormField]) that opens a searchable bottom sheet listing the organization's
/// batch numbers (paginated by 20). The sheet always offers an "Autres" option
/// to type + save a brand-new lot number, asks the user to confirm the
/// selection, and supports renaming / deleting existing entries. The confirmed
/// value is also stored in [selectedBatchNumberProvider] so it sticks for the
/// rest of the blood-bag-creation session.
class BatchNumberSelectorField extends ConsumerStatefulWidget {
  /// Currently selected batch number (drives the field text + checkmark).
  final String? value;

  /// Fired with the confirmed batch number, or null when the selection is
  /// cleared (e.g. the selected lot was deleted).
  final ValueChanged<String?> onChanged;

  /// Optional field label (defaults to `'batch_number'.tr`).
  final String? label;

  /// Whether a value is required (drives the inline Form validation).
  final bool isRequired;

  const BatchNumberSelectorField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.isRequired = true,
  });

  @override
  ConsumerState<BatchNumberSelectorField> createState() =>
      _BatchNumberSelectorFieldState();
}

class _BatchNumberSelectorFieldState
    extends ConsumerState<BatchNumberSelectorField> {
  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.value,
      validator: (v) =>
          (widget.isRequired && (v == null || v.trim().isEmpty))
              ? 'batch_number_required'.tr
              : null,
      builder: (field) {
        final hasValue = widget.value != null && widget.value!.isNotEmpty;
        final hasError = field.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _openSheet(field),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasError ? Colors.red : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.barcode, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label ?? 'batch_number'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasValue
                                ? widget.value!
                                : 'select_batch_number'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: hasValue
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Iconsax.arrow_right_3, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openSheet(FormFieldState<String> field) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _BatchNumberSelectorSheet(currentValue: widget.value),
    );

    if (result == null) return; // dismissed — keep current selection

    if (result == kBatchSelectionCleared) {
      ref.read(selectedBatchNumberProvider.notifier).state = null;
      field.didChange(null);
      widget.onChanged(null);
      return;
    }

    // A batch number was chosen/created and confirmed.
    ref.read(selectedBatchNumberProvider.notifier).state = result;
    field.didChange(result);
    widget.onChanged(result);
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Bottom sheet
// ──────────────────────────────────────────────────────────────────────────

class _BatchNumberSelectorSheet extends ConsumerStatefulWidget {
  final String? currentValue;

  const _BatchNumberSelectorSheet({this.currentValue});

  @override
  ConsumerState<_BatchNumberSelectorSheet> createState() =>
      _BatchNumberSelectorSheetState();
}

class _BatchNumberSelectorSheetState
    extends ConsumerState<_BatchNumberSelectorSheet> {
  final _searchController = TextEditingController();
  final _createController = TextEditingController();
  Timer? _debounce;
  bool _createMode = false;
  String? _createError;

  @override
  void initState() {
    super.initState();
    // Start each open on a clean, unfiltered list.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(batchNumbersProvider.notifier).clearSearch();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _createController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(batchNumbersProvider.notifier).searchLocal(query);
    });
  }

  Future<void> _confirmAndSelect(String batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm_batch_selection_title'.tr),
        content: Text(
          'confirm_batch_selection_body'.trParams({'batch': batch}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context, batch);
    }
  }

  Future<void> _submitCreate() async {
    final text = _createController.text.trim();
    if (text.isEmpty) {
      setState(() => _createError = 'batch_number_empty_error'.tr);
      return;
    }
    setState(() => _createError = null);
    final notifier = ref.read(batchNumbersProvider.notifier);
    final result = await notifier.createOrFind(text);
    if (!mounted) return;
    if (result == null) {
      final msg = ref.read(batchNumbersProvider).errorMessage;
      setState(() => _createError =
          msg.isNotEmpty ? msg : 'batch_number_create_failed'.tr);
      return;
    }
    await _confirmAndSelect(result);
  }

  Future<void> _openRowMenu(BatchNumber item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.edit),
              title: Text('edit_batch_number'.tr),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Iconsax.trash, color: Colors.red),
              title: Text(
                'delete_batch_number'.tr,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _renameRow(item);
    } else if (action == 'delete') {
      await _deleteRow(item);
    }
  }

  Future<void> _renameRow(BatchNumber item) async {
    final controller = TextEditingController(text: item.batchNumber);
    final newValue = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('edit_batch_number'.tr),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'enter_batch_number_hint'.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || newValue == null || newValue.isEmpty) return;
    final updated =
        await ref.read(batchNumbersProvider.notifier).updateBatchNumber(
              item.id,
              newValue,
            );
    if (!mounted) return;
    if (updated == null) {
      _showSnack(ref.read(batchNumbersProvider).errorMessage, isError: true);
    }
  }

  Future<void> _deleteRow(BatchNumber item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_batch_number'.tr),
        content: Text(
          'confirm_batch_selection_body'.trParams({'batch': item.batchNumber}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('delete_batch_number'.tr),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final ok =
        await ref.read(batchNumbersProvider.notifier).deleteBatchNumber(item.id);
    if (!mounted) return;
    if (!ok) {
      _showSnack(ref.read(batchNumbersProvider).errorMessage, isError: true);
      return;
    }
    // If the deleted lot was the active selection, tell the caller to clear it.
    if (widget.currentValue != null &&
        widget.currentValue == item.batchNumber) {
      Navigator.pop(context, kBatchSelectionCleared);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.isNotEmpty ? message : 'something_went_wrong'.tr),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchNumbersProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle + title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'select_batch_number'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'search_batch_number_hint'.tr,
                    prefixIcon: const Icon(Iconsax.search_normal),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {}); // refresh the clear button
                    _onSearchChanged(value);
                  },
                ),
              ),

              // Pinned "Autres" row / inline create panel
              _buildAutresSection(state),
              const Divider(height: 1),

              // List
              Expanded(child: _buildListArea(state, scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAutresSection(BatchNumberListState state) {
    if (!_createMode) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.12),
          child: Icon(Iconsax.add, color: ColorPages.COLOR_PRINCIPAL),
        ),
        title: Text(
          'batch_number_others'.tr,
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('add_batch_number'.tr),
        onTap: () => setState(() {
          _createMode = true;
          _createError = null;
          _createController.clear();
        }),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _createController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitCreate(),
                  decoration: InputDecoration(
                    hintText: 'enter_batch_number_hint'.tr,
                    errorText: _createError,
                    prefixIcon: const Icon(Iconsax.barcode),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              state.isCreating
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: ColorPages.COLOR_PRINCIPAL,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Iconsax.tick_circle),
                      onPressed: _submitCreate,
                    ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: state.isCreating
                  ? null
                  : () => setState(() {
                        _createMode = false;
                        _createError = null;
                      }),
              child: Text('cancel'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListArea(
    BatchNumberListState state,
    ScrollController scrollController,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isError && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                state.errorMessage.isNotEmpty
                    ? state.errorMessage
                    : 'something_went_wrong'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.read(batchNumbersProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Pin the active selection (checked) at the top, and drop it from the body
    // list to avoid showing it twice.
    final selected = widget.currentValue;
    final hasSelected = selected != null && selected.isNotEmpty;
    final body = state.filteredItems
        .where((b) => !(hasSelected && b.batchNumber == selected))
        .toList();

    if (body.isEmpty && !hasSelected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isSearchActive ? Icons.search_off : Iconsax.barcode,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              state.isSearchActive
                  ? 'no_batch_numbers_found'.tr
                  : 'no_batch_numbers_registered'.tr,
              style: GoogleFonts.ubuntu(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    final showFooter = !state.isSearchActive && state.hasMorePages;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent * 0.85) {
          if (!state.isLoading && state.hasMorePages && !state.isSearchActive) {
            ref.read(batchNumbersProvider.notifier).loadNextPage();
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        itemCount:
            (hasSelected ? 1 : 0) + body.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          // Pinned selected row first.
          if (hasSelected && index == 0) {
            return _buildTile(
              BatchNumber(id: '', batchNumber: selected),
              isSelected: true,
            );
          }
          final bodyIndex = hasSelected ? index - 1 : index;

          if (bodyIndex >= body.length) {
            // Footer
            if (state.isLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'end_of_list'.tr,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            );
          }

          final item = body[bodyIndex];
          return _buildTile(item, isSelected: false);
        },
      ),
    );
  }

  Widget _buildTile(BatchNumber item, {required bool isSelected}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.shade50,
        child: Icon(Iconsax.barcode, color: Colors.red.shade400, size: 20),
      ),
      title: Text(
        item.batchNumber,
        style: GoogleFonts.ubuntu(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: ColorPages.COLOR_PRINCIPAL)
          : (item.id.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  tooltip: 'edit_batch_number'.tr,
                  onPressed: () => _openRowMenu(item),
                )),
      onTap: () => _confirmAndSelect(item.batchNumber),
      onLongPress: item.id.isEmpty ? null : () => _openRowMenu(item),
    );
  }
}
