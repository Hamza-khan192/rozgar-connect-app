import 'labor_profile.dart';
import 'review.dart';
import 'skill.dart';

/// Aggregated view of a laborer: profile + skills (via LaborSkills) +
/// reviews + average rating.
class LaborerDetail {
  final LaborProfile profile;
  final List<Skill> skills;
  final List<Review> reviews;
  final double avgRating;

  const LaborerDetail({
    required this.profile,
    required this.skills,
    required this.reviews,
    required this.avgRating,
  });
}
