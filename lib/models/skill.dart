/// Maps to the `Skills` table (master skill list).
class Skill {
  final int skillId;
  final String skillName;

  const Skill({required this.skillId, required this.skillName});

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      skillId: (json['skill_id'] as num?)?.toInt() ?? 0,
      skillName: json['skill_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'skill_id': skillId, 'skill_name': skillName};
  }
}
