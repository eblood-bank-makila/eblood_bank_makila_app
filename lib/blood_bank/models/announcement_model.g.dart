// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnnouncementModel _$AnnouncementModelFromJson(Map<String, dynamic> json) =>
    AnnouncementModel(
      id: json['id'] as String?,
      identifier: json['identifier'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      announcementType:
          $enumDecode(_$AnnouncementTypeEnumMap, json['announcement_type']),
      status:
          $enumDecodeNullable(_$AnnouncementStatusEnumMap, json['status']) ??
              AnnouncementStatus.draft,
      priority: $enumDecodeNullable(
              _$AnnouncementPriorityEnumMap, json['priority']) ??
          AnnouncementPriority.medium,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      location: json['location'] as String?,
      contactInfo: json['contact_info'] as String?,
      bloodTypesNeeded: (json['blood_types_needed'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      targetAudience: (json['target_audience'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imageUrl: json['image_url'] as String?,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      healthStructureId: json['health_structure_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      isActivated: json['is_activated'] as bool? ?? true,
    );

Map<String, dynamic> _$AnnouncementModelToJson(AnnouncementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'identifier': instance.identifier,
      'title': instance.title,
      'description': instance.description,
      'announcement_type':
          _$AnnouncementTypeEnumMap[instance.announcementType]!,
      'status': _$AnnouncementStatusEnumMap[instance.status]!,
      'priority': _$AnnouncementPriorityEnumMap[instance.priority]!,
      'start_date': instance.startDate?.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'location': instance.location,
      'contact_info': instance.contactInfo,
      'blood_types_needed': instance.bloodTypesNeeded,
      'target_audience': instance.targetAudience,
      'image_url': instance.imageUrl,
      'views_count': instance.viewsCount,
      'published_at': instance.publishedAt?.toIso8601String(),
      'health_structure_id': instance.healthStructureId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'is_activated': instance.isActivated,
    };

const _$AnnouncementTypeEnumMap = {
  AnnouncementType.event: 'event',
  AnnouncementType.campaign: 'campaign',
  AnnouncementType.news: 'news',
  AnnouncementType.emergency: 'emergency',
};

const _$AnnouncementStatusEnumMap = {
  AnnouncementStatus.upcoming: 'upcoming',
  AnnouncementStatus.ongoing: 'ongoing',
  AnnouncementStatus.past: 'past',
  AnnouncementStatus.active: 'active',
  AnnouncementStatus.ended: 'ended',
  AnnouncementStatus.draft: 'draft',
  AnnouncementStatus.published: 'published',
  AnnouncementStatus.archived: 'archived',
  AnnouncementStatus.critical: 'critical',
  AnnouncementStatus.resolved: 'resolved',
};

const _$AnnouncementPriorityEnumMap = {
  AnnouncementPriority.low: 'low',
  AnnouncementPriority.medium: 'medium',
  AnnouncementPriority.high: 'high',
  AnnouncementPriority.urgent: 'urgent',
};
