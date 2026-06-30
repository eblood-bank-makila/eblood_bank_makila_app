import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/theme/ColorPages.dart';
import 'network_controller.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/users/ui/pages/notification/NotificationPage.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NetworkController());
  // theme used in child builders

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
                            Text('app_name'.tr, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('medical_network'.tr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage(notification: [])));
                        },
                        icon: const Icon(Iconsax.notification, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),

              // Content container
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(context, controller),
                      _buildCategoryTabs(context, controller),
                      Expanded(child: _buildList(context, controller)),
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

  Widget _buildHeader(BuildContext context, NetworkController controller) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('medical_network'.tr, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: ColorPages.COLOR_PRINCIPAL)),
                    Text('find_nearby_hospitals_banks'.tr, style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    )),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.map_outlined)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor ?? Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: GetBuilder<NetworkController>(
              builder: (c) => TextField(
                controller: c.searchController,
                onChanged: c.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'search_hospitals_blood_banks'.tr,
                      prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, NetworkController controller) {
    final theme = Theme.of(context);
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final category = controller.categories[index];
          final isSelected = controller.selectedCategory.value == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(getCategoryIcon(category), size: 16, color: isSelected ? ColorPages.COLOR_PRINCIPAL : theme.iconTheme.color?.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Text(category.tr),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => controller.selectCategory(category),
              backgroundColor: theme.chipTheme.backgroundColor,
              selectedColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              side: BorderSide(color: isSelected ? ColorPages.COLOR_PRINCIPAL : theme.dividerColor),
            ),
          );
        },
      )),
    );
  }

  Widget _buildList(BuildContext context, NetworkController controller) {
    final theme = Theme.of(context);
    return Obx(() => controller.isLoading.value
        ? const Center(child: CircularProgressIndicator())
    : controller.filteredNetworks.isEmpty
      ? Center(child: Text('no_facilities_found'.tr, style: theme.textTheme.titleMedium))
            : RefreshIndicator(
                onRefresh: controller.loadNetworks,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.filteredNetworks.length,
                  itemBuilder: (context, index) {
                    final n = controller.filteredNetworks[index];
                    return _card(context, controller, n);
                  },
                ),
              ));
  }

  Widget _card(BuildContext context, NetworkController controller, NetworkModel n) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getCategoryColor(n.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(getCategoryIcon(n.type), color: getCategoryColor(n.type)),
        ),
        title: Text(n.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.address, style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7))),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: Colors.red),
              const SizedBox(width: 2),
              Text('${n.distance} km away', style: theme.textTheme.bodySmall?.copyWith(color: Colors.red, fontWeight: FontWeight.w500)),
            ]),
          ],
        ),
        trailing: IconButton(
          onPressed: () => controller.callNetwork(n),
          icon: const Icon(Icons.call),
        ),
      ),
    );
  }
}
