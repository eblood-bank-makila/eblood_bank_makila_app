import 'package:json_annotation/json_annotation.dart';

part 'announcement_model.g.dart';

/// Enum for announcement types
enum AnnouncementType {
  @JsonValue('event')
  event,
  @JsonValue('campaign')
  campaign,
  @JsonValue('news')
  news,
  @JsonValue('emergency')
  emergency,
}

/// Enum for announcement status
enum AnnouncementStatus {
  // Event statuses
  @JsonValue('upcoming')
  upcoming,
  @JsonValue('ongoing')
  ongoing,
  @JsonValue('past')
  past,
  
  // Campaign statuses
  @JsonValue('active')
  active,
  @JsonValue('ended')
  ended,
  
  // News statuses
  @JsonValue('draft')
  draft,
  @JsonValue('published')
  published,
  @JsonValue('archived')
  archived,
  
  // Emergency statuses
  @JsonValue('critical')
  critical,
  @JsonValue('resolved')
  resolved,
}

/// Enum for announcement priority
enum AnnouncementPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

@JsonSerializable()
class AnnouncementModel {
  final String? id;
  final String identifier;
  final String title;
  final String? description;
  
  @JsonKey(name: 'announcement_type')
  final AnnouncementType announcementType;
  
  final AnnouncementStatus status;
  final AnnouncementPriority priority;
  
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  
  final String? location;
  
  @JsonKey(name: 'contact_info')
  final String? contactInfo;
  
  @JsonKey(name: 'blood_types_needed')
  final List<String>? bloodTypesNeeded;
  
  @JsonKey(name: 'target_audience')
  final List<String>? targetAudience;
  
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  
  @JsonKey(name: 'views_count')
  final int viewsCount;
  
  @JsonKey(name: 'published_at')
  final DateTime? publishedAt;
  
  @JsonKey(name: 'health_structure_id')
  final String? healthStructureId;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  
  @JsonKey(name: 'is_activated')
  final bool isActivated;

  AnnouncementModel({
    this.id,
    required this.identifier,
    required this.title,
    this.description,
    required this.announcementType,
    this.status = AnnouncementStatus.draft,
    this.priority = AnnouncementPriority.medium,
    this.startDate,
    this.endDate,
    this.location,
    this.contactInfo,
    this.bloodTypesNeeded,
    this.targetAudience,
    this.imageUrl,
    this.viewsCount = 0,
    this.publishedAt,
    this.healthStructureId,
    this.createdAt,
    this.updatedAt,
    this.isActivated = true,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementModelFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementModelToJson(this);

  AnnouncementModel copyWith({
    String? id,
    String? identifier,
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
    int? viewsCount,
    DateTime? publishedAt,
    String? healthStructureId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActivated,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      title: title ?? this.title,
      description: description ?? this.description,
      announcementType: announcementType ?? this.announcementType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      contactInfo: contactInfo ?? this.contactInfo,
      bloodTypesNeeded: bloodTypesNeeded ?? this.bloodTypesNeeded,
      targetAudience: targetAudience ?? this.targetAudience,
      imageUrl: imageUrl ?? this.imageUrl,
      viewsCount: viewsCount ?? this.viewsCount,
      publishedAt: publishedAt ?? this.publishedAt,
      healthStructureId: healthStructureId ?? this.healthStructureId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActivated: isActivated ?? this.isActivated,
    );
  }
}
