import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/theme/ColorPages.dart';
import 'announcements_controller.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/notification/NotificationPage.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnnouncementsController());
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorPages.COLOR_PRINCIPAL,
              ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
              Colors.grey.shade50,
            ],
            stops: const [0.0, 0.15, 1.0],
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
                        Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
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
                            Text('E-Blood Bank', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Annonces', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: Stack(children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage(notification: [])));
                          },
                          icon: const Icon(Iconsax.notification, color: Colors.white, size: 24),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Obx(() => controller.unreadCount.value > 0
                              ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle))
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
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _priorityBanner(controller),
                      _filterTabs(theme, controller),
                      Expanded(child: _list(theme, controller)),
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
              Row(children: const [Icon(Icons.priority_high, color: Colors.white, size: 20), SizedBox(width: 8), Text('URGENT BLOOD NEEDED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
              const SizedBox(height: 8),
              Text(controller.urgentAnnouncements.first.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(controller.urgentAnnouncements.first.location, style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red), child: const Text('RESPOND')),
              ])
            ]),
          )
        : const SizedBox.shrink());
  }

  Widget _filterTabs(ThemeData theme, AnnouncementsController controller) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.filterTabs.length,
        itemBuilder: (context, index) {
          final tab = controller.filterTabs[index];
          final isSelected = controller.selectedFilter.value == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tab),
              selected: isSelected,
              onSelected: (_) => controller.selectFilter(tab),
              backgroundColor: theme.chipTheme.backgroundColor,
              selectedColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              side: BorderSide(color: isSelected ? ColorPages.COLOR_PRINCIPAL : theme.dividerColor),
            ),
          );
        },
      )),
    );
  }

  Widget _list(ThemeData theme, AnnouncementsController controller) {
    return Obx(() => controller.isLoading.value
        ? const Center(child: CircularProgressIndicator())
        : controller.filteredAnnouncements.isEmpty
            ? Center(child: Text('No announcements', style: theme.textTheme.titleMedium))
            : RefreshIndicator(
                onRefresh: controller.loadAnnouncements,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.filteredAnnouncements.length,
                  itemBuilder: (context, index) {
                    final a = controller.filteredAnnouncements[index];
                    return _card(theme, a);
                  },
                ),
              ));
  }

  Widget _card(ThemeData theme, AnnouncementModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0,2))]),
      child: ListTile(
        leading: const Icon(Icons.campaign),
        title: Text(a.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(a.location),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
