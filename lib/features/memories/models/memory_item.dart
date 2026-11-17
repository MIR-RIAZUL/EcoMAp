import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../core/constants/mood_types.dart';
import '../../../data/database/app_database.dart';

class MemoryItem {
  final int id;
  final String title;
  final String? description;
  final String? photoPath;
  final DateTime dateTime;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final Mood mood;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final String? cloudId;
  final DateTime? updatedAt;

  const MemoryItem({
    required this.id,
    required this.title,
    this.description,
    this.photoPath,
    required this.dateTime,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.mood,
    required this.tags,
    this.isFavorite = false,
    required this.createdAt,
    this.cloudId,
    this.updatedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  // Convert from Drift Database generated row
  factory MemoryItem.fromDb(Memory memory) {
    List<String> parsedTags = [];
    if (memory.tags.isNotEmpty) {
      parsedTags = memory.tags
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }

    return MemoryItem(
      id: memory.id,
      title: memory.title,
      description: memory.description,
      photoPath: memory.photoPath,
      dateTime: memory.memoryDate,
      latitude: memory.latitude,
      longitude: memory.longitude,
      locationName: memory.locationName,
      mood: Mood.fromString(memory.mood),
      tags: parsedTags,
      isFavorite: memory.isFavorite,
      createdAt: memory.createdAt,
      cloudId: memory.cloudId,
      updatedAt: memory.updatedAt,
    );
  }

  // Convert to Drift MemoriesCompanion for insert / update
  MemoriesCompanion toCompanion({bool forInsert = false}) {
    final effectiveCloudId = cloudId ?? const Uuid().v4();
    final effectiveUpdatedAt = updatedAt ?? DateTime.now();

    return MemoriesCompanion(
      id: forInsert ? const drift.Value.absent() : drift.Value(id),
      title: drift.Value(title),
      description: drift.Value(description),
      photoPath: drift.Value(photoPath),
      memoryDate: drift.Value(dateTime),
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
      locationName: drift.Value(locationName),
      mood: drift.Value(mood.id),
      tags: drift.Value(tags.join(', ')),
      isFavorite: drift.Value(isFavorite),
      createdAt: forInsert ? const drift.Value.absent() : drift.Value(createdAt),
      cloudId: drift.Value(effectiveCloudId),
      updatedAt: drift.Value(effectiveUpdatedAt),
    );
  }

  // Map to Supabase `public.memories` row
  Map<String, dynamic> toSupabaseJson({
    required String userId,
    String? cloudPhotoPath,
  }) {
    return {
      'id': cloudId ?? const Uuid().v4(),
      'user_id': userId,
      'title': title,
      'description': description,
      'photo_path': cloudPhotoPath,
      'date_time': dateTime.toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'mood': mood.id,
      'tags': tags.join(', '),
      'is_favorite': isFavorite,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }

  // Construct MemoryItem from Supabase `public.memories` row
  factory MemoryItem.fromSupabaseJson(
    Map<String, dynamic> json, {
    String? localPhotoPath,
    int localId = 0,
  }) {
    final tagsRaw = json['tags'] as String? ?? '';
    List<String> parsedTags = [];
    if (tagsRaw.isNotEmpty) {
      parsedTags = tagsRaw
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }

    final parsedDateTime =
        DateTime.tryParse(json['date_time'] as String? ?? '')?.toLocal() ??
            DateTime.now();
    final parsedCreatedAt =
        DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
            parsedDateTime;
    final parsedUpdatedAt =
        DateTime.tryParse(json['updated_at'] as String? ?? '')?.toLocal();

    return MemoryItem(
      id: localId,
      cloudId: json['id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      photoPath: localPhotoPath,
      dateTime: parsedDateTime,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['location_name'] as String?,
      mood: Mood.fromString(json['mood'] as String? ?? 'neutral'),
      tags: parsedTags,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  MemoryItem copyWith({
    int? id,
    String? title,
    String? description,
    String? photoPath,
    DateTime? dateTime,
    double? latitude,
    double? longitude,
    String? locationName,
    Mood? mood,
    List<String>? tags,
    bool? isFavorite,
    DateTime? createdAt,
    String? cloudId,
    DateTime? updatedAt,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      dateTime: dateTime ?? this.dateTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      cloudId: cloudId ?? this.cloudId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
