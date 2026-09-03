import 'dart:async';

import 'package:travelstories/features/experiences/domain/entities/experience.dart';
import 'package:travelstories/features/experiences/domain/repositories/experience_repository.dart';

/// In-memory [ExperienceRepository] for widget/unit tests — no Firestore SDK
/// involved. Does not touch the parent travel book's `experienceCount`
/// (that's Firestore-batch-write behavior tested at the repository-impl
/// level, not something a fake needs to simulate).
class FakeExperienceRepository implements ExperienceRepository {
  final Map<String, Experience> _experiences = {};
  final _byBookControllers = <String, StreamController<void>>{};
  final _byIdControllers = <String, StreamController<Experience?>>{};
  int _nextId = 0;

  StreamController<void> _byBookController(String travelBookId) {
    return _byBookControllers.putIfAbsent(
      travelBookId,
      () => StreamController<void>.broadcast(),
    );
  }

  StreamController<Experience?> _byIdController(String id) {
    return _byIdControllers.putIfAbsent(
      id,
      () => StreamController<Experience?>.broadcast(),
    );
  }

  @override
  Stream<List<Experience>> watchExperiences(String travelBookId) async* {
    List<Experience> current() =>
        _experiences.values
            .where((e) => e.travelBookId == travelBookId)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    yield current();
    yield* _byBookController(travelBookId).stream.map((_) => current());
  }

  @override
  Stream<Experience?> watchExperience({
    required String travelBookId,
    required String id,
  }) async* {
    yield _experiences[id];
    yield* _byIdController(id).stream;
  }

  @override
  Future<String> createExperience({
    required String travelBookId,
    required String ownerId,
    required String title,
    required String description,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    final id = 'experience-${_nextId++}';
    final now = DateTime.now();
    _experiences[id] = Experience(
      id: id,
      travelBookId: travelBookId,
      ownerId: ownerId,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      mediaType: ExperienceMediaType.text,
      createdAt: now,
      updatedAt: now,
    );
    _byBookController(travelBookId).add(null);
    _byIdController(id).add(_experiences[id]);
    return id;
  }

  @override
  Future<void> updateExperience({
    required String travelBookId,
    required String id,
    required String title,
    required String description,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    final existing = _experiences[id];
    if (existing == null) return;
    final updated = existing.copyWith(
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      updatedAt: DateTime.now(),
    );
    _experiences[id] = updated;
    _byBookController(travelBookId).add(null);
    _byIdController(id).add(updated);
  }

  @override
  Future<void> deleteExperience({
    required String travelBookId,
    required String id,
  }) async {
    _experiences.remove(id);
    _byBookController(travelBookId).add(null);
    _byIdController(id).add(null);
  }

  @override
  Future<void> uploadMedia({
    required String travelBookId,
    required String id,
    required ExperienceMediaType mediaType,
    required List<int> bytes,
    required String extension,
    List<int>? thumbnailBytes,
  }) async {
    final existing = _experiences[id];
    if (existing == null) return;
    final updated = existing.copyWith(
      mediaType: mediaType,
      mediaUrl: 'https://example.com/fake-media.$extension',
      thumbnailUrl: thumbnailBytes != null
          ? 'https://example.com/fake-thumbnail.jpg'
          : null,
      updatedAt: DateTime.now(),
    );
    _experiences[id] = updated;
    _byBookController(travelBookId).add(null);
    _byIdController(id).add(updated);
  }

  @override
  Future<void> removeMedia({
    required String travelBookId,
    required String id,
  }) async {
    final existing = _experiences[id];
    if (existing == null) return;
    final updated = existing.copyWith(
      mediaType: ExperienceMediaType.text,
      mediaUrl: null,
      thumbnailUrl: null,
    );
    _experiences[id] = updated;
    _byBookController(travelBookId).add(null);
    _byIdController(id).add(updated);
  }
}
