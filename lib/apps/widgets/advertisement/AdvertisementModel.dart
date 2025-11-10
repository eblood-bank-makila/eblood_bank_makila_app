/// Advertisement/Banner Model
class AdvertisementModel {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? videoUrl;
  final String? actionUrl;
  final String? actionType; // 'internal', 'external', 'none', 'modal'
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final int priority; // Higher priority shows first
  final String? targetAudience; // 'hospital', 'blood_bank', 'all'
  final String? advertisementType; // 'campaign', 'promotion', 'urgent', etc.

  AdvertisementModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.videoUrl,
    this.actionUrl,
    this.actionType = 'none',
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.priority = 0,
    this.targetAudience = 'all',
    this.advertisementType,
  });

  /// Check if advertisement is currently valid
  bool get isValid {
    if (!isActive) return false;
    
    final now = DateTime.now();
    
    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }
    
    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }
    
    return true;
  }

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    // Normalize target_audience which may come as a string or list
    final dynamic ta = json['target_audience'] ?? json['targetAudience'];
    String? targetAudienceStr;
    if (ta is List) {
      final list = ta.whereType<String>().map((e) => e.trim()).toList();
      if (list.contains('all')) {
        targetAudienceStr = 'all';
      } else if (list.isNotEmpty) {
        targetAudienceStr = list.first;
      }
    } else if (ta is String) {
      targetAudienceStr = ta.trim();
    }

    // Normalize isActive which may be is_active, isActive, or is_activated
    final dynamic isActiveRaw = json['is_active'] ?? json['isActive'] ?? json['is_activated'];
    final bool isActiveVal = isActiveRaw is bool
        ? isActiveRaw
        : (isActiveRaw is String ? isActiveRaw.toLowerCase() == 'true' : true);

    // Normalize priority to int
    final dynamic p = json['priority'];
    final int priorityVal = p is int
        ? p
        : (p is num
            ? p.toInt()
            : (p is String ? int.tryParse(p) ?? 0 : 0));

    return AdvertisementModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
      videoUrl: json['video_url'] ?? json['videoUrl'],
      actionUrl: json['action_url'] ?? json['actionUrl'],
      actionType: json['action_type'] ?? json['actionType'] ?? 'none',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      isActive: isActiveVal,
      priority: priorityVal,
      targetAudience: targetAudienceStr ?? 'all',
      advertisementType: json['advertisement_type'] ?? json['advertisementType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'action_url': actionUrl,
      'action_type': actionType,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'priority': priority,
      'target_audience': targetAudience,
      'advertisement_type': advertisementType,
    };
  }

  AdvertisementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? videoUrl,
    String? actionUrl,
    String? actionType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? priority,
    String? targetAudience,
    String? advertisementType,
  }) {
    return AdvertisementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionType: actionType ?? this.actionType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      targetAudience: targetAudience ?? this.targetAudience,
      advertisementType: advertisementType ?? this.advertisementType,
    );
  }
}

