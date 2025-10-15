import 'package:get/get.dart';
import 'announcements_service.dart';

class AnnouncementsController extends GetxController {
  final isLoading = false.obs;
  final unreadCount = 0.obs;
  // Display labels use translation keys; internal filter values remain English
  final filterTabs = ['all', 'urgent', 'blood_requests', 'campaigns', 'events', 'news'].obs;
  final selectedFilter = 'all'.obs;
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

  Future<void> createOrUpdate({
    String? id,
    required String title,
    required String type,
    required String location,
    required String priority,
    required String description,
  }) async {
    isLoading.value = true;
    try {
      if (id == null || id.isEmpty) {
        await _service.createAnnouncement(
          title: title,
          type: type,
          location: location,
          priority: priority,
          description: description,
        );
      } else {
        await _service.updateAnnouncement(
          id: id,
          title: title,
          type: type,
          location: location,
          priority: priority,
          description: description,
        );
      }
      await loadAnnouncements();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> delete(String id) async {
    isLoading.value = true;
    try {
      await _service.deleteAnnouncement(id);
      await loadAnnouncements();
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
    if (selectedFilter.value != 'all') {
      switch (selectedFilter.value) {
        case 'urgent':
          filtered = filtered.where((a) => a.priority == 'urgent').toList();
          break;
        case 'blood_requests':
          filtered = filtered.where((a) => a.type == 'Blood Request').toList();
          break;
        case 'campaigns':
          filtered = filtered.where((a) => a.type == 'Campaign').toList();
          break;
        case 'events':
          filtered = filtered.where((a) => a.type == 'Event').toList();
          break;
        case 'news':
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
