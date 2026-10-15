import '../models/favorite.dart';
import '../models/job.dart';
import '../models/labor_profile.dart';
import '../models/laborer_detail.dart';
import '../models/location_entry.dart';
import '../models/review.dart';
import '../models/skill.dart';
import '../models/user.dart';

/// Data-source contract for Rozgar Connect.
/// Implemented by [MockRepository] (in-memory demo data) and
/// [ApiRepository] (Node.js/Express REST backend).
abstract class AppRepository {
  Future<User> register({
    required String name,
    required String phone,
    required String password,
    required String role,
  });

  Future<User> login({required String phone, required String password});

  Future<List<Skill>> getSkills();

  Future<List<LaborProfile>> getLaborers({String? query, int? skillId});

  Future<LaborerDetail> getLaborerDetail(int laborId);

  Future<List<Job>> getJobs({int? customerId, int? laborId, String? status});

  Future<Job> createJob({
    required int customerId,
    required int laborId,
    required String description,
    required double budget,
  });

  Future<Job> updateJobStatus(int jobId, String status);

  Future<void> deleteJob(int jobId);

  Future<List<Review>> getReviews({int? laborId, int? jobId});

  Future<Review> addReview({
    required int jobId,
    required int customerId,
    required int laborId,
    required int rating,
    required String comment,
  });

  Future<bool> toggleFavorite({required int customerId, required int laborId});

  Future<List<Favorite>> getFavorites(int customerId);

  Future<bool> isFavorite({required int customerId, required int laborId});

  Future<LaborProfile?> getLaborProfileByUser(int userId);

  Future<LaborProfile> updateLaborProfile(LaborProfile profile,
      {List<int>? skillIds});

  Future<LocationEntry> updateLocation({
    required int laborId,
    required double latitude,
    required double longitude,
  });

  Future<LocationEntry?> getLatestLocation(int laborId);

  Future<List<User>> getUsers();

  Future<void> deleteUser(int userId);
}
