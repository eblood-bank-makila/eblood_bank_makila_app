import 'package:get/get.dart';
import 'announcements_service.dart';

class AnnouncementsController extends GetxController {
  final isLoading = false.obs;
  final unreadCount = 0.obs;
  final filterTabs = ['All', 'Urgent', 'Campaigns', 'Events', 'News'].obs;
  final selectedFilter = 'All'.obs;
  final announcements = <AnnouncementModel>[].obs;
  final filteredAnnouncements = <AnnouncementModel>[].obs;
  final urgentAnnouncements = <AnnouncementModel>[].obs;
  final AnnouncementsService _service = AnnouncementsService();

  @override
  void onInit() {
    super.onInit();
    loadAnnouncements();
    loadUnreadCount();
  }

  void loadUnreadCount() {
    unreadCount.value = 2; // demo
  }

  Future<void> loadAnnouncements() async {
    isLoading.value = true;
    try {
      final list = await _service.fetchAll();
      announcements.value = list.map(_fromJson).toList();
      urgentAnnouncements.value = announcements.where((a) => a.priority == 'urgent').toList();
      _applyFilters();
    } catch (e) {
      // Fallback to empty on error; keep UX responsive
      announcements.clear();
      filteredAnnouncements.clear();
      urgentAnnouncements.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void selectFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = announcements.toList();
    if (selectedFilter.value != 'All') {
      switch (selectedFilter.value) {
        case 'Urgent':
          filtered = filtered.where((a) => a.priority == 'urgent').toList();
          break;
        case 'Campaigns':
          filtered = filtered.where((a) => a.type == 'Campaign').toList();
          break;
        case 'Events':
          filtered = filtered.where((a) => a.type == 'Event').toList();
          break;
        case 'News':
          filtered = filtered.where((a) => a.type == 'News').toList();
          break;
      }
    }
    filteredAnnouncements.value = filtered;
  }
}

class AnnouncementModel {
  final String id;
  final String type;
  final String priority;
  final String title;
  final String location;

  AnnouncementModel({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.location,
  });
}

AnnouncementModel _fromJson(Map<String, dynamic> json) {
  return AnnouncementModel(
    id: (json['id'] ?? json['uuid'] ?? json['pk'] ?? '').toString(),
    type: (json['type'] ?? json['category'] ?? 'News').toString(),
    priority: (json['priority'] ?? json['level'] ?? 'normal').toString(),
    title: (json['title'] ?? json['subject'] ?? '').toString(),
    location: (json['location'] ?? json['place'] ?? '').toString(),
  );
}
