import 'package:drift/drift.dart' as drift;
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
    );
  }

  // Convert to Drift MemoriesCompanion for insert / update
  MemoriesCompanion toCompanion({bool forInsert = false}) {
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
    );
  }
}
