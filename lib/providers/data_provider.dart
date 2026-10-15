import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/app_repository.dart';
import '../models/favorite.dart';
import '../models/job.dart';
import '../models/labor_profile.dart';
import '../models/laborer_detail.dart';
import '../models/location_entry.dart';
import '../models/skill.dart';
import '../models/user.dart';

/// App-wide data state. Fed by the current [AppRepository]; the signed-in
/// [User] is pushed in from [AuthProvider] via [setUser].
class DataProvider extends ChangeNotifier {
  final AppRepository repo;

  User? _user;

  DataProvider(this.repo);

  User? get currentUser => _user;
  bool get isCustomer => _user?.isCustomer ?? false;
  bool get isLaborer => _user?.isLaborer ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;

  List<Skill> skills = [];
  List<LaborProfile> laborers = [];
  Map<int, User> usersById = {};
  Map<int, LaborerDetail> detailCache = {};
  List<Job> jobs = [];
  List<Favorite> favorites = [];
  LaborProfile? myProfile;
  List<int> mySkillIds = [];
  LocationEntry? myLocation;
  String? lastError;
  bool laborersLoaded = false;

  String _query = '';
  int? _skillFilter;

  /// Called by the proxy provider whenever the auth session changes.
  /// Never notifies synchronously (it may run during a build).
  void setUser(User? user) {
    if (_user?.userId == user?.userId) return;
    _user = user;
    skills = [];
    laborers = [];
    usersById = {};
    detailCache = {};
    jobs = [];
    favorites = [];
    myProfile = null;
    mySkillIds = [];
    myLocation = null;
    lastError = null;
    laborersLoaded = false;
    _query = '';
    _skillFilter = null;
    if (user != null) {
      unawaited(refreshAll());
    }
  }

  String laborerName(LaborProfile profile) =>
      usersById[profile.userId]?.name ?? 'Laborer';

  String userName(int userId) => usersById[userId]?.name ?? 'User';

  List<String> skillNamesFor(int laborId) {
    final detail = detailCache[laborId];
    if (detail != null) {
      return detail.skills.map((s) => s.skillName).toList();
    }
    return [];
  }

  Map<int, Skill> _skillByIdMap() =>
      {for (final s in skills) s.skillId: s};

  List<String> mySkillNames() {
    final byId = _skillByIdMap();
    return [
      for (final id in mySkillIds)
        if (byId[id] != null) byId[id]!.skillName
    ];
  }

  Future<LaborerDetail> laborerDetailFuture(int laborId) =>
      repo.getLaborerDetail(laborId);

  Future<void> refreshAll() async {
    lastError = null;
    try {
      skills = await repo.getSkills();
      final users = await repo.getUsers();
      usersById = {for (final u in users) u.userId: u};
      await searchLaborers(_query, _skillFilter, notify: false);
      final u = _user;
      if (u != null) {
        if (u.isCustomer) {
          jobs = await repo.getJobs(customerId: u.userId);
          favorites = await repo.getFavorites(u.userId);
        } else if (u.isLaborer) {
          myProfile = await repo.getLaborProfileByUser(u.userId);
          final lp = myProfile;
          if (lp != null) {
            jobs = await repo.getJobs(laborId: lp.laborId);
            myLocation = await repo.getLatestLocation(lp.laborId);
            final detail = await repo.getLaborerDetail(lp.laborId);
            detailCache[lp.laborId] = detail;
            mySkillIds = detail.skills.map((s) => s.skillId).toList();
          }
        } else if (u.isAdmin) {
          jobs = await repo.getJobs();
        }
      }
    } catch (e) {
      lastError = e.toString();
    }
    notifyListeners();
  }

  Future<void> searchLaborers(String query, int? skillId,
      {bool notify = true}) async {
    _query = query;
    _skillFilter = skillId;
    try {
      laborers = await repo.getLaborers(
          query: query.isEmpty ? null : query, skillId: skillId);
      final details = await Future.wait(
          laborers.map((p) => repo.getLaborerDetail(p.laborId)));
      detailCache = {for (final d in details) d.profile.laborId: d};
      laborersLoaded = true;
      lastError = null;
    } catch (e) {
      lastError = e.toString();
    }
    if (notify) notifyListeners();
  }

  bool isFav(int laborId) => favorites.any((f) => f.laborId == laborId);

  Future<bool> toggleFavorite(int laborId) async {
    final u = _user;
    if (u == null) throw Exception('Not logged in');
    final result =
        await repo.toggleFavorite(customerId: u.userId, laborId: laborId);
    favorites = await repo.getFavorites(u.userId);
    notifyListeners();
    return result;
  }

  Future<void> createJob(
      {required int laborId,
      required String description,
      required double budget}) async {
    final u = _user;
    if (u == null) throw Exception('Not logged in');
    await repo.createJob(
        customerId: u.userId,
        laborId: laborId,
        description: description,
        budget: budget);
    jobs = await repo.getJobs(customerId: u.userId);
    notifyListeners();
  }

  Future<void> updateJobStatus(int jobId, String status) async {
    await repo.updateJobStatus(jobId, status);
    final i = jobs.indexWhere((j) => j.jobId == jobId);
    if (i != -1) jobs[i] = jobs[i].copyWith(status: status);
    notifyListeners();
  }

  Future<void> deleteJob(int jobId) async {
    await repo.deleteJob(jobId);
    jobs.removeWhere((j) => j.jobId == jobId);
    notifyListeners();
  }

  Future<void> addReview(
      {required int jobId,
      required int laborId,
      required int rating,
      required String comment}) async {
    final u = _user;
    if (u == null) throw Exception('Not logged in');
    await repo.addReview(
        jobId: jobId,
        customerId: u.userId,
        laborId: laborId,
        rating: rating,
        comment: comment);
    detailCache.remove(laborId);
    notifyListeners();
  }

  Future<void> updateProfile(
      {required double? dailyWage,
      required double? hourlyRate,
      required int? experience,
      required String availability,
      required List<int> skillIds,
      String? about}) async {
    final lp = myProfile;
    if (lp == null) throw Exception('No labor profile found');
    final updated = lp.copyWith(
      dailyWage: dailyWage,
      hourlyRate: hourlyRate,
      experience: experience,
      availabilityStatus: availability,
      skills: about,
    );
    myProfile = await repo.updateLaborProfile(updated, skillIds: skillIds);
    mySkillIds = List.of(skillIds);
    detailCache.remove(lp.laborId);
    await searchLaborers(_query, _skillFilter, notify: false);
    notifyListeners();
  }

  Future<LocationEntry> updateLocation(
      {required double latitude, required double longitude}) async {
    final lp = myProfile;
    if (lp == null) throw Exception('No labor profile found');
    final entry = await repo.updateLocation(
        laborId: lp.laborId, latitude: latitude, longitude: longitude);
    myLocation = entry;
    notifyListeners();
    return entry;
  }

  Future<void> deleteUser(int userId) async {
    await repo.deleteUser(userId);
    final users = await repo.getUsers();
    usersById = {for (final u in users) u.userId: u};
    await searchLaborers(_query, _skillFilter, notify: false);
    jobs = await repo.getJobs();
    notifyListeners();
  }
}
