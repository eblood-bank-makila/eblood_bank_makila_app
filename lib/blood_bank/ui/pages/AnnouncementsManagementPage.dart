import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../apps/config/theme/ColorPages.dart';
import '../../../apps/config/utils/LocaleHelper.dart';
import '../../models/announcement_model.dart';
import '../../providers/announcement_provider.dart';

class AnnouncementsManagementPage extends ConsumerStatefulWidget {
  const AnnouncementsManagementPage({super.key});

  @override
  ConsumerState<AnnouncementsManagementPage> createState() => _AnnouncementsManagementPageState();
}

class _AnnouncementsManagementPageState extends ConsumerState<AnnouncementsManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForCurrentTab();
    });

    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadDataForCurrentTab();
      }
    });
  }

  void _loadDataForCurrentTab() {
    switch (_tabController.index) {
      case 0:
        ref.read(announcementProvider.notifier).fetchAnnouncements(
          announcementType: AnnouncementType.event,
        );
        break;
      case 1:
        ref.read(announcementProvider.notifier).fetchAnnouncements(
          announcementType: AnnouncementType.campaign,
        );
        break;
      case 2:
        ref.read(announcementProvider.notifier).fetchAnnouncements(
          announcementType: AnnouncementType.news,
        );
        break;
      case 3:
        ref.read(announcementProvider.notifier).fetchActiveEmergencies();
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final locale = Get.locale?.toLanguageTag() ?? Localizations.localeOf(context).toLanguageTag();
    final safeLocale = LocaleHelper.getSafeLocale(locale);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'today'.tr;
    } else if (dateToCheck == yesterday) {
      return 'yesterday'.tr;
    } else {
      return LocaleHelper.formatDate(date, 'yMMMMd', safeLocale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'communications'.tr,
          style: GoogleFonts.ubuntu(
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'events'.tr,
              icon: const Icon(Iconsax.calendar),
            ),
            Tab(
              text: 'campaigns'.tr,
              icon: const Icon(Iconsax.activity),
            ),
            Tab(
              text: 'news'.tr,
              icon: const Icon(Iconsax.notification),
            ),
            Tab(
              text: 'emergencies'.tr,
              icon: const Icon(Iconsax.warning_2),
            ),
          ],
          labelStyle: GoogleFonts.ubuntu(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsTab(),
          _buildCampaignsTab(),
          _buildNewsTab(),
          _buildEmergenciesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        onPressed: () {
          _showCreateAnnouncementDialog();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEventsTab() {
    final events = ref.watch(eventsProvider);
    final isLoading = ref.watch(announcementProvider).isLoading;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(announcementProvider.notifier).fetchAnnouncements(
          announcementType: AnnouncementType.event,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('data_updated'.tr),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      color: Colors.red,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAnnouncementList(events),
    );
  }

  Widget _buildCampaignsTab() {
    final campaigns = ref.watch(campaignsProvider);
    final isLoading = ref.watch(announcementProvider).isLoading;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(announcementProvider.notifier).fetchAnnouncements(
          announcementType: AnnouncementType.campaign,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('data_updated'.tr),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      color: Colors.red,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAnnouncementList(campaigns),
    );
  }

  Widget _buildNewsTab() {
    final news = ref.watch(newsProvider);
    final isLoading = ref.watch(announcementProvider).isLoading;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(announcementProvider.notifier).fetchAnnouncements(
          announcementType: AnnouncementType.news,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('data_updated'.tr),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      color: Colors.red,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAnnouncementList(news),
    );
  }

  Widget _buildEmergenciesTab() {
    final emergencies = ref.watch(emergenciesProvider);
    final isLoading = ref.watch(announcementProvider).isLoading;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(announcementProvider.notifier).fetchActiveEmergencies();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('data_updated'.tr),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      color: Colors.red,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAnnouncementList(emergencies),
    );
  }

  Widget _buildAnnouncementList(List<AnnouncementModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.document_text,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'no_announcements_available'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'press_plus_to_create_new'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildAnnouncementCard(announcement: item);
      },
    );
  }

  Widget _buildAnnouncementCard({
    required AnnouncementModel announcement,
  }) {
    final title = announcement.title;
    final description = announcement.description ?? '';
    final type = announcement.announcementType;
    final status = announcement.status;

    // Format date
    String dateText = '';
    if (announcement.startDate != null) {
      if (announcement.endDate != null) {
        // Date range
        final startDate = announcement.startDate!;
        final endDate = announcement.endDate!;
        dateText = '${_formatDate(startDate)} - ${_formatDate(endDate)}';
      } else {
        // Single date
        dateText = _formatDate(announcement.startDate!);
      }
    } else if (announcement.createdAt != null) {
      dateText = _formatDate(announcement.createdAt!);
    }

    IconData icon;
    Color color;

    // Determine icon and color based on type
    switch (type) {
      case AnnouncementType.event:
        icon = Iconsax.calendar;
        color = Colors.blue;
        break;
      case AnnouncementType.campaign:
        icon = Iconsax.activity;
        color = Colors.green;
        break;
      case AnnouncementType.news:
        icon = Iconsax.notification;
        color = Colors.purple;
        break;
      case AnnouncementType.emergency:
        icon = Iconsax.warning_2;
        color = Colors.red;
        break;
    }

    // Status tag and color
    String statusText;
    Color statusColor;

    switch (status) {
      case AnnouncementStatus.upcoming:
        statusText = 'ann_status_upcoming'.tr;
        statusColor = Colors.blue;
        break;
      case AnnouncementStatus.active:
        statusText = 'ann_status_active'.tr;
        statusColor = Colors.green;
        break;
      case AnnouncementStatus.past:
        statusText = 'ann_status_past'.tr;
        statusColor = Colors.grey;
        break;
      case AnnouncementStatus.ended:
        statusText = 'ann_status_ended'.tr;
        statusColor = Colors.grey;
        break;
      case AnnouncementStatus.published:
        statusText = 'ann_status_published'.tr;
        statusColor = Colors.purple;
        break;
      case AnnouncementStatus.critical:
        statusText = 'ann_status_critical'.tr;
        statusColor = Colors.red;
        break;
      case AnnouncementStatus.resolved:
        statusText = 'ann_status_resolved'.tr;
        statusColor = Colors.teal;
        break;
      case AnnouncementStatus.ongoing:
        statusText = 'ann_status_ongoing'.tr;
        statusColor = Colors.orange;
        break;
      case AnnouncementStatus.draft:
        statusText = 'ann_status_draft'.tr;
        statusColor = Colors.grey;
        break;
      case AnnouncementStatus.archived:
        statusText = 'ann_status_archived'.tr;
        statusColor = Colors.grey.shade400;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.calendar_1,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateText,
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                      ),
                      color: Colors.blue,
                      onPressed: () {
                        // Edit announcement
                        _showEditAnnouncementDialog(announcement);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                      ),
                      color: Colors.red,
                      onPressed: () {
                        // Delete announcement
                        _showDeleteConfirmationDialog(announcement);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAnnouncementDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    AnnouncementType selectedType = AnnouncementType.event;
    AnnouncementStatus selectedStatus = AnnouncementStatus.upcoming;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'new_announcement'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'new_announcement'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Title field
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'title'.tr,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'description'.tr,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type dropdown
                    DropdownButtonFormField<AnnouncementType>(
                      decoration: InputDecoration(
                        labelText: 'type'.tr,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      value: selectedType,
                      items: [
                        DropdownMenuItem(value: AnnouncementType.event, child: Text('event'.tr)),
                        DropdownMenuItem(value: AnnouncementType.campaign, child: Text('campaigns'.tr)),
                        DropdownMenuItem(value: AnnouncementType.news, child: Text('news'.tr)),
                        DropdownMenuItem(value: AnnouncementType.emergency, child: Text('emergency'.tr)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedType = value;

                            // Update status options based on type
                            switch (value) {
                              case AnnouncementType.event:
                                selectedStatus = AnnouncementStatus.upcoming;
                                break;
                              case AnnouncementType.campaign:
                                selectedStatus = AnnouncementStatus.active;
                                break;
                              case AnnouncementType.news:
                                selectedStatus = AnnouncementStatus.published;
                                break;
                              case AnnouncementType.emergency:
                                selectedStatus = AnnouncementStatus.critical;
                                break;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status dropdown
                    DropdownButtonFormField<AnnouncementStatus>(
                      decoration: InputDecoration(
                        labelText: 'status'.tr,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.info_outline),
                      ),
                      value: selectedStatus,
                      items: _getStatusItemsForType(selectedType),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'cancel'.tr,
                            style: GoogleFonts.ubuntu(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPages.COLOR_PRINCIPAL,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          onPressed: () async {
                            if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                              Navigator.pop(context);

                              // Show loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('creating_in_progress'.tr),
                                  duration: const Duration(seconds: 1),
                                ),
                              );

                              // Create announcement via API
                              final success = await ref.read(announcementProvider.notifier).createAnnouncement(
                                title: titleController.text,
                                description: descriptionController.text,
                                announcementType: selectedType,
                                status: selectedStatus,
                              );

                              if (mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('announcement_created_success'.tr),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  // Update the tab controller to show the newly created announcement
                                  switch (selectedType) {
                                    case AnnouncementType.event:
                                      _tabController.animateTo(0);
                                      break;
                                    case AnnouncementType.campaign:
                                      _tabController.animateTo(1);
                                      break;
                                    case AnnouncementType.news:
                                      _tabController.animateTo(2);
                                      break;
                                    case AnnouncementType.emergency:
                                      _tabController.animateTo(3);
                                      break;
                                  }
                                } else {
                                  final error = ref.read(announcementProvider).error ?? 'error_during_creation'.tr;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('please_fill_all_required_fields'.tr),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text(
                            'create'.tr,
                            style: GoogleFonts.ubuntu(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditAnnouncementDialog(AnnouncementModel announcement) {
    final titleController = TextEditingController(text: announcement.title);
    final descriptionController = TextEditingController(text: announcement.description);
    AnnouncementType selectedType = announcement.announcementType;
    AnnouncementStatus selectedStatus = announcement.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'edit_announcement'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Title field
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'title'.tr,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'description'.tr,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type dropdown
                    DropdownButtonFormField<AnnouncementType>(
                      decoration: InputDecoration(
                        labelText: 'type'.tr,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      value: selectedType,
                      items: [
                        DropdownMenuItem(value: AnnouncementType.event, child: Text('event'.tr)),
                        DropdownMenuItem(value: AnnouncementType.campaign, child: Text('campaigns'.tr)),
                        DropdownMenuItem(value: AnnouncementType.news, child: Text('news'.tr)),
                        DropdownMenuItem(value: AnnouncementType.emergency, child: Text('emergency'.tr)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status dropdown
                    DropdownButtonFormField<AnnouncementStatus>(
                      decoration: InputDecoration(
                        labelText: 'status'.tr,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.info_outline),
                      ),
                      value: selectedStatus,
                      items: _getStatusItemsForType(selectedType),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'cancel'.tr,
                            style: GoogleFonts.ubuntu(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPages.COLOR_PRINCIPAL,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          onPressed: () async {
                            if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                              Navigator.pop(context);

                              // Show loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('updating_in_progress'.tr),
                                  duration: const Duration(seconds: 1),
                                ),
                              );

                              // Update announcement via API
                              final success = await ref.read(announcementProvider.notifier).updateAnnouncement(
                                announcementId: announcement.id!,
                                title: titleController.text,
                                description: descriptionController.text,
                                announcementType: selectedType,
                                status: selectedStatus,
                              );

                              if (mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('announcement_updated_success'.tr),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  final error = ref.read(announcementProvider).error ?? 'error_during_update'.tr;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('please_fill_all_required_fields'.tr),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text(
                            'update'.tr,
                            style: GoogleFonts.ubuntu(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'delete_announcement'.tr,
            style: GoogleFonts.ubuntu(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'delete_announcement_confirm'.trParams({'title': announcement.title}),
            style: GoogleFonts.ubuntu(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'cancel'.tr,
                style: GoogleFonts.ubuntu(),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);

                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('deleting_in_progress'.tr),
                    duration: const Duration(seconds: 1),
                  ),
                );

                // Delete announcement via API
                final success = await ref.read(announcementProvider.notifier).deleteAnnouncement(
                  announcement.id!,
                  announcement.announcementType,
                );

                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Communication supprimée avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    final error = ref.read(announcementProvider).error ?? 'error_during_delete'.tr;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'delete'.tr,
                style: GoogleFonts.ubuntu(),
              ),
            ),
          ],
        );
      },
    );
  }

  List<DropdownMenuItem<AnnouncementStatus>> _getStatusItemsForType(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.event:
        return [
          DropdownMenuItem(value: AnnouncementStatus.upcoming, child: Text('ann_status_upcoming'.tr)),
          DropdownMenuItem(value: AnnouncementStatus.ongoing, child: Text('ann_status_ongoing'.tr)),
          DropdownMenuItem(value: AnnouncementStatus.past, child: Text('ann_status_past'.tr)),
        ];
      case AnnouncementType.campaign:
        return [
          DropdownMenuItem(value: AnnouncementStatus.upcoming, child: Text('ann_status_upcoming'.tr)),
          DropdownMenuItem(value: AnnouncementStatus.active, child: Text('ann_status_active'.tr)),
          DropdownMenuItem(value: AnnouncementStatus.ended, child: Text('ann_status_ended'.tr)),
        ];
      case AnnouncementType.news:
        return [
          DropdownMenuItem(value: AnnouncementStatus.draft, child: Text('ann_status_draft'.tr)),
          DropdownMenuItem(value: AnnouncementStatus.published, child: Text('ann_status_published'.tr)),
          DropdownMenuItem(value: AnnouncementStatus.archived, child: Text('ann_status_archived'.tr)),
        ];
      case AnnouncementType.emergency:
        return [
          DropdownMenuItem(value: AnnouncementStatus.critical, child: Text('ann_status_critical'.tr)),
          DropdownMenuItem(value: AnnouncementStatus.ongoing, child: Text('ann_status_ongoing'.tr)),
          DropdownMenuItem(value: AnnouncementStatus.resolved, child: Text('ann_status_resolved'.tr)),
        ];
    }
  }
}