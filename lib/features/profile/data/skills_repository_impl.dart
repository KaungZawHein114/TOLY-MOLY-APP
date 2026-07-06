import '../models/profile_models.dart';
import 'skills_api.dart';
import 'skills_repository.dart';

class SkillsRepositoryImpl implements SkillsRepository {
  final SkillsApi _api;

  SkillsRepositoryImpl({SkillsApi? api}) : _api = api ?? SkillsApi();

  @override
  Future<List<TaskerSkillEntry>> list() async {
    final json = await _api.list();
    return json.map((e) => TaskerSkillEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<TaskerSkillEntry> create({required String skillName, required int experienceYears}) async {
    final json = await _api.create(skillName: skillName, experienceYears: experienceYears);
    return TaskerSkillEntry.fromJson(json);
  }

  @override
  Future<TaskerSkillEntry> update(int id, {required String skillName, required int experienceYears}) async {
    final json = await _api.update(id, skillName: skillName, experienceYears: experienceYears);
    return TaskerSkillEntry.fromJson(json);
  }

  @override
  Future<void> delete(int id) {
    return _api.delete(id);
  }
}
