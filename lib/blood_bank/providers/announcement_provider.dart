import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_provider.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';

/// State class for announcements
class AnnouncementState {
  final List<AnnouncementModel> announcements;
  final bool isLoading;
  final String? error;

  AnnouncementState({
    this.announcements = const [],
    this.isLoading = false,
    this.error,
  });

  AnnouncementState copyWith({
    List<AnnouncementModel>? announcements,
    bool? isLoading,
    String? error,
  }) {
    return AnnouncementState(
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing announcement state
class AnnouncementNotifier extends StateNotifier<AnnouncementState> {
  final AnnouncementService _service;

  AnnouncementNotifier(this._service) : super(AnnouncementState());

  /// Fetch announcements with optional filters
  Future<void> fetchAnnouncements({
    AnnouncementType? announcementType,
    AnnouncementStatus? status,
    String? search,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getAnnouncements(
      announcementType: announcementType,
      status: status,
      search: search,
    );

    if (result['success']) {
      state = state.copyWith(
        announcements: result['data'] as List<AnnouncementModel>,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message'] as String?,
      );
    }
  }

  /// Create a new announcement
  Future<bool> createAnnouncement({
    required String title,
    String? description,
    required AnnouncementType announcementType,
    AnnouncementStatus status = AnnouncementStatus.draft,
    AnnouncementPriority priority = AnnouncementPriority.medium,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? contactInfo,
    List<String>? bloodTypesNeeded,
    List<String>? targetAudience,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.createAnnouncement(
      title: title,
      description: description,
      announcementType: announcementType,
      status: status,
      priority: priority,
      startDate: startDate,
      endDate: endDate,
      location: location,
      contactInfo: contactInfo,
      bloodTypesNeeded: bloodTypesNeeded,
      targetAudience: targetAudience,
      imageUrl: imageUrl,
    );

    if (result['success']) {
      // Refresh the list after creating
      await fetchAnnouncements(announcementType: announcementType);
      state = state.copyWith(isLoading: false);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message'] as String?,
      );
      return false;
    }
  }

  /// Update an announcement
  Future<bool> updateAnnouncement({
    required String announcementId,
    String? title,
    String? description,
    AnnouncementType? announcementType,
    AnnouncementStatus? status,
    AnnouncementPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? contactInfo,
    List<String>? bloodTypesNeeded,
    List<String>? targetAudience,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.updateAnnouncement(
      announcementId: announcementId,
      title: title,
      description: description,
      announcementType: announcementType,
      status: status,
      priority: priority,
      startDate: startDate,
      endDate: endDate,
      location: location,
      contactInfo: contactInfo,
      bloodTypesNeeded: bloodTypesNeeded,
      targetAudience: targetAudience,
      imageUrl: imageUrl,
    );

    if (result['success']) {
      // Refresh the list after updating
      await fetchAnnouncements(announcementType: announcementType);
      state = state.copyWith(isLoading: false);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message'] as String?,
      );
      return false;
    }
  }

  /// Delete an announcement
  Future<bool> deleteAnnouncement(String announcementId, AnnouncementType type) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.deleteAnnouncement(announcementId);

    if (result['success']) {
      // Refresh the list after deleting
      await fetchAnnouncements(announcementType: type);
      state = state.copyWith(isLoading: false);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message'] as String?,
      );
      return false;
    }
  }

  /// Get active emergencies
  Future<void> fetchActiveEmergencies() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getActiveEmergencies();

    if (result['success']) {
      state = state.copyWith(
        announcements: result['data'] as List<AnnouncementModel>,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message'] as String?,
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for AnnouncementService
final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  final rbac = ref.read(rbacProvider.notifier);
  var crudInfo = rbac.getCrudInfoByPath('flutter_apps_eblood_bank_bb_home_announcements');
  if (crudInfo.isEmpty) {
    crudInfo = rbac.getCrudInfoByPath('flutter_apps_eblood_bank_cnts_home_announcements');
  }
  return AnnouncementService(crudInfo);
});

/// Provider for AnnouncementNotifier
final announcementProvider =
    StateNotifierProvider<AnnouncementNotifier, AnnouncementState>((ref) {
  final service = ref.watch(announcementServiceProvider);
  return AnnouncementNotifier(service);
});

/// Provider for events only
final eventsProvider = Provider<List<AnnouncementModel>>((ref) {
  final state = ref.watch(announcementProvider);
  return state.announcements
      .where((a) => a.announcementType == AnnouncementType.event)
      .toList();
});

/// Provider for campaigns only
final campaignsProvider = Provider<List<AnnouncementModel>>((ref) {
  final state = ref.watch(announcementProvider);
  return state.announcements
      .where((a) => a.announcementType == AnnouncementType.campaign)
      .toList();
});

/// Provider for news only
final newsProvider = Provider<List<AnnouncementModel>>((ref) {
  final state = ref.watch(announcementProvider);
  return state.announcements
      .where((a) => a.announcementType == AnnouncementType.news)
      .toList();
});

/// Provider for emergencies only
final emergenciesProvider = Provider<List<AnnouncementModel>>((ref) {
  final state = ref.watch(announcementProvider);
  return state.announcements
      .where((a) => a.announcementType == AnnouncementType.emergency)
      .toList();
});
