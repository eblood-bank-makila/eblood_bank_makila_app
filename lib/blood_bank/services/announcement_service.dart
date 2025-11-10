import '../../apps/config/api/dio_client.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  AnnouncementService();

  Future<Map<String, dynamic>> createAnnouncement({
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
    try {
      final response = await postWithDio(
        '/eblood/announcements',
        body: {
          'title': title,
          'description': description,
          'announcement_type': _announcementTypeToString(announcementType),
          'status': _announcementStatusToString(status),
          'priority': _announcementPriorityToString(priority),
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'location': location,
          'contact_info': contactInfo,
          'blood_types_needed': bloodTypesNeeded,
          'target_audience': targetAudience,
          'image_url': imageUrl,
        },
      );

      if (response.success) {
        return {
          'success': true,
          'data': response.data,
          'message': response.message ?? 'Announcement created successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.message ?? 'Failed to create announcement',
          'error': response.message,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getAnnouncements({
    AnnouncementType? announcementType,
    AnnouncementStatus? status,
    String? search,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };

      if (announcementType != null) {
        queryParams['announcement_type'] = _announcementTypeToString(announcementType);
      }

      if (status != null) {
        queryParams['status'] = _announcementStatusToString(status);
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await getWithDio(
        '/eblood/announcements',
        queryParams: queryParams,
      );

      final List<AnnouncementModel> announcements = [];
      if (response.success && response.data != null) {
        final data = response.data;
        if (data is List) {
          for (var item in data) {
            announcements.add(AnnouncementModel.fromJson(item));
          }
        }
      }

      return {
        'success': response.success,
        'data': announcements,
        'message': response.message ?? 'Announcements retrieved successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getAnnouncementById(String announcementId) async {
    try {
      final response = await getWithDio(
        '/eblood/announcements/$announcementId',
      );

      if (response.success && response.data != null) {
        return {
          'success': true,
          'data': AnnouncementModel.fromJson(response.data),
          'message': response.message ?? 'Announcement retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.message ?? 'Failed to retrieve announcement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateAnnouncement({
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
    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (announcementType != null) {
        updateData['announcement_type'] = _announcementTypeToString(announcementType);
      }
      if (status != null) {
        updateData['status'] = _announcementStatusToString(status);
      }
      if (priority != null) {
        updateData['priority'] = _announcementPriorityToString(priority);
      }
      if (startDate != null) updateData['start_date'] = startDate.toIso8601String();
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String();
      if (location != null) updateData['location'] = location;
      if (contactInfo != null) updateData['contact_info'] = contactInfo;
      if (bloodTypesNeeded != null) updateData['blood_types_needed'] = bloodTypesNeeded;
      if (targetAudience != null) updateData['target_audience'] = targetAudience;
      if (imageUrl != null) updateData['image_url'] = imageUrl;

      final response = await putWithDio(
        '/eblood/announcements?announcementId=$announcementId',
        body: updateData,
      );

      if (response.success) {
        return {
          'success': true,
          'data': response.data,
          'message': response.message ?? 'Announcement updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.message ?? 'Failed to update announcement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> deleteAnnouncement(String announcementId) async {
    try {
      final response = await deleteWithDio(
        '/eblood/announcements?announcementId=$announcementId',
      );

      if (response.success) {
        return {
          'success': true,
          'data': response.data,
          'message': response.message ?? 'Announcement deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.message ?? 'Failed to delete announcement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getActiveEmergencies() async {
    try {
      final response = await getWithDio(
        '/eblood/announcements/emergencies/active',
      );

      final List<AnnouncementModel> announcements = [];
      if (response.success && response.data != null) {
        final data = response.data;
        if (data is List) {
          for (var item in data) {
            announcements.add(AnnouncementModel.fromJson(item));
          }
        }
      }

      return {
        'success': response.success,
        'data': announcements,
        'message': response.message ?? 'Active emergencies retrieved successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred',
        'error': e.toString(),
      };
    }
  }

  String _announcementTypeToString(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.event:
        return 'event';
      case AnnouncementType.campaign:
        return 'campaign';
      case AnnouncementType.news:
        return 'news';
      case AnnouncementType.emergency:
        return 'emergency';
    }
  }

  String _announcementStatusToString(AnnouncementStatus status) {
    switch (status) {
      case AnnouncementStatus.upcoming:
        return 'upcoming';
      case AnnouncementStatus.ongoing:
        return 'ongoing';
      case AnnouncementStatus.past:
        return 'past';
      case AnnouncementStatus.active:
        return 'active';
      case AnnouncementStatus.ended:
        return 'ended';
      case AnnouncementStatus.draft:
        return 'draft';
      case AnnouncementStatus.published:
        return 'published';
      case AnnouncementStatus.archived:
        return 'archived';
      case AnnouncementStatus.critical:
        return 'critical';
      case AnnouncementStatus.resolved:
        return 'resolved';
    }
  }

  String _announcementPriorityToString(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return 'low';
      case AnnouncementPriority.medium:
        return 'medium';
      case AnnouncementPriority.high:
        return 'high';
      case AnnouncementPriority.urgent:
        return 'urgent';
    }
  }
}
