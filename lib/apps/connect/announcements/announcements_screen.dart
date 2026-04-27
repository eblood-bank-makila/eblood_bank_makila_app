import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/rbac/providers/rbac_provider.dart';
import '../../config/theme/ColorPages.dart';
import 'announcements_controller.dart';
import 'create_announcements_screen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/notification/NotificationPage.dart';

class AnnouncementsScreen extends ConsumerWidget {
  final bool showBackButton;

  const AnnouncementsScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = Get.isRegistered<AnnouncementsController>()
        ? Get.find<AnnouncementsController>()
        : Get.put(AnnouncementsController());
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop() && showBackButton;

    // RBAC gates for sub-menu actions reachable from this screen.
    final rbac = ref.watch(rbacProvider.notifier);
    final canCreate = rbac.hasMenuFlag('flutter_apps_eblood_bank_cust_announcement_create');
    final canDetail = rbac.hasMenuFlag('flutter_apps_eblood_bank_cust_announcement_detail');

    return Scaffold(
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              heroTag: 'announcements_add_fab',
              onPressed: () => _showCreateSheet(context, controller),
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('add'.tr, style: const TextStyle(color: Colors.white)),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade100,
              Colors.red.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top header like Banquepage
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (canPop) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Center(
                              child: Image.asset('assets/icons/app_icon.png', fit: BoxFit.contain),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('app_name'.tr, style: GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.bold, color: ColorPages.COLOR_PRINCIPAL)),
                            Text('announcements'.tr, style: GoogleFonts.ubuntu(fontSize: 12, color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.7))),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      // decoration: BoxDecoration(color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
                      child: Stack(children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage(notification: [])));
                          },
                          icon: const Icon(Iconsax.notification, color: ColorPages.COLOR_PRINCIPAL, size: 24),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Obx(() => controller.unreadCount.value > 0
                              ? Container(width: 8, height: 8, decoration:  BoxDecoration(color: ColorPages.COLOR_PRINCIPAL, shape: BoxShape.circle))
                              : const SizedBox.shrink()),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _priorityBanner(controller),
                      _filterTabs(theme, controller),
                      Expanded(child: _list(theme, controller, canDetail: canDetail)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _priorityBanner(AnnouncementsController controller) {
    return Obx(() => controller.urgentAnnouncements.isNotEmpty
        ? Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red, Colors.redAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.priority_high, color: Colors.white, size: 20), const SizedBox(width: 8), Text('urgent_blood_needed'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
              const SizedBox(height: 8),
              Text(controller.urgentAnnouncements.first.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(controller.urgentAnnouncements.first.location, style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red), child: Text('respond'.tr)),
              ])
            ]),
          )
        : const SizedBox.shrink());
  }

  Widget _filterTabs(ThemeData theme, AnnouncementsController controller) {
    // Take a snapshot of tabs to avoid rebuilding the whole list on selection changes
    final tabs = controller.filterTabs.toList(growable: false);
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Obx(() {
              final isSelected = controller.selectedFilter.value == tab;
              return ChoiceChip(
                label: Text(tab.tr),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected && controller.selectedFilter.value != tab) {
                    controller.selectFilter(tab);
                  }
                },
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                selectedColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
                side: BorderSide(
                  color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.black.withValues(alpha: 0.4),
                  width: 0.4,
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _list(ThemeData theme, AnnouncementsController controller, {required bool canDetail}) {
    return Obx(() => controller.isLoading.value
        ? const Center(child: CircularProgressIndicator())
    : controller.filteredAnnouncements.isEmpty
      ? Center(child: Text('no_announcements'.tr, style: theme.textTheme.titleMedium))
            : RefreshIndicator(
                onRefresh: controller.loadAnnouncements,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.filteredAnnouncements.length,
                  itemBuilder: (context, index) {
                    final a = controller.filteredAnnouncements[index];
                    return GestureDetector(
                      onLongPress: () => _showManageSheet(context, controller, a),
                      child: _card(theme, a, canDetail: canDetail),
                    );
                  },
                ),
              ));
  }

  Widget _card(ThemeData theme, AnnouncementModel a, {required bool canDetail}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.4),
          width: 0.4,
        ),
      ),
      child: Opacity(
        opacity: canDetail ? 1.0 : 0.5,
        child: ListTile(
          leading: const Icon(Icons.campaign),
          title: Text(a.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(a.location),
          trailing: const Icon(Icons.chevron_right),
          onTap: canDetail ? () {} : null,
        ),
      ),
    );
  }

  void _showManageSheet(BuildContext context, AnnouncementsController controller, AnnouncementModel a) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('edit'.tr),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAnnouncementsScreen())).then((_) => controller.loadAnnouncements());
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text('delete'.tr),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                await controller.delete(a.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('announcement_deleted'.tr)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, AnnouncementsController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.bloodtype),
                title: Text('blood_request'.tr),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAnnouncementsScreen(initialType: 'Blood Request'),
                    ),
                  ).then((_) => controller.loadAnnouncements());
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: Text('campaign'.tr),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAnnouncementsScreen(initialType: 'Campaign'),
                    ),
                  ).then((_) => controller.loadAnnouncements());
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text('event'.tr),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAnnouncementsScreen(initialType: 'Event'),
                    ),
                  ).then((_) => controller.loadAnnouncements());
                },
              ),
              ListTile(
                leading: const Icon(Icons.newspaper),
                title: Text('news'.tr),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAnnouncementsScreen(initialType: 'News'),
                    ),
                  ).then((_) => controller.loadAnnouncements());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}
