import '../models/profile_models.dart';

/// Talks to the Django `/api/tasker/skills*` backend. Screens depend on this
/// interface, never on [SkillsApi] directly.
abstract class SkillsRepository {
  Future<List<TaskerSkillEntry>> list();

  Future<TaskerSkillEntry> create({required String skillName, required int experienceYears});

  Future<TaskerSkillEntry> update(int id, {required String skillName, required int experienceYears});

  Future<void> delete(int id);
}
