import '../models/favorite.dart';
import '../models/job.dart';
import '../models/labor_profile.dart';
import '../models/laborer_detail.dart';
import '../models/location_entry.dart';
import '../models/review.dart';
import '../models/skill.dart';
import '../models/user.dart';
import 'app_repository.dart';

/// Fully in-memory implementation with realistic Pakistani demo data.
/// Used while [kUseApi] is false so the app runs instantly with no backend.
class MockRepository implements AppRepository {
  final List<User> _users = [];
  final Map<int, String> _passwords = {};
  final List<Skill> _skills = [];
  final List<LaborProfile> _profiles = [];
  final Map<int, List<int>> _laborSkills = {};
  final List<Job> _jobs = [];
  final List<Review> _reviews = [];
  final List<Favorite> _favorites = [];
  final List<LocationEntry> _locations = [];

  int _userSeq = 1;
  int _laborSeq = 1;
  int _jobSeq = 1;
  int _reviewSeq = 1;
  int _favSeq = 1;
  int _locSeq = 1;

  MockRepository() {
    _seed();
  }

  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 200));

  // ---------------------------------------------------------------- seed --

  void _seed() {
    _addUser('Hamza Khan', '03331234567', 'customer');
    _addUser('Ahmed Khan', '03337654321', 'laborer');
    _addUser('Admin', '03330000000', 'admin');
    _addUser('Bilal Ahmed', '03331112233', 'laborer');
    _addUser('Usman Ali', '03332223344', 'laborer');
    _addUser('Imran Shah', '03333334455', 'laborer');
    _addUser('Tariq Mehmood', '03334445566', 'laborer');
    _addUser('Shahid Khan', '03335556677', 'laborer');
    _addUser('Nasir Ali', '03336667788', 'laborer');
    _addUser('Faisal Rehman', '03337778899', 'laborer');

    const skillNames = [
      'Mason (Mistri)',
      'Electrician',
      'Plumber',
      'Painter',
      'Carpenter',
      'Welder',
      'Driver',
      'Cook',
      'Gardener (Mali)',
      'Cleaner',
      'Tailor',
      'AC Technician',
      'Mobile Repair',
      'Construction Helper',
    ];
    for (var i = 0; i < skillNames.length; i++) {
      _skills.add(Skill(skillId: i + 1, skillName: skillNames[i]));
    }

    _addLabor(2, 'Expert mason for houses, boundary walls and plaster work.',
        8, 2500, 350, 'available', [1, 4, 14]);
    _addLabor(4, 'Certified electrician: house wiring and AC installation.', 5,
        2000, 300, 'available', [2, 12]);
    _addLabor(5, 'Plumber for bathrooms, kitchens and water tanks.', 6, 2200,
        300, 'busy', [3]);
    _addLabor(6, 'Carpenter and welder: furniture, doors, gates and grills.',
        10, 3000, 400, 'available', [5, 6]);
    _addLabor(7, 'Experienced driver with LTV licence, city and long routes.',
        7, 1800, 250, 'available', [7]);
    _addLabor(8, 'Cook for events and homes, desi and fast food.', 4, 1500,
        200, 'available', [8, 10]);
    _addLabor(9, 'Gents tailor and mobile repair specialist.', 9, 2000, 280,
        'busy', [11, 13]);
    _addLabor(10, 'Mali for lawns and painter for houses.', 3, 1600, 220,
        'available', [9, 4]);

    // Favorites: customer 1 saved laborers 1 and 3.
    _favorites.add(Favorite(
        favoriteId: _favSeq++,
        customerId: 1,
        laborId: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 3))));
    _favorites.add(Favorite(
        favoriteId: _favSeq++,
        customerId: 1,
        laborId: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 2))));

    _addJob(1, 1, 'Boundary wall construction (100 ft), Sheikh Maltoon Town',
        15000, 'pending', daysAgo: 1);
    _addJob(1, 2, 'Complete house wiring + 4 ceiling fans installation', 5000,
        'pending', daysAgo: 0);
    _addJob(1, 4, 'Wooden wardrobe for master bedroom', 20000, 'in_progress',
        daysAgo: 5);
    _addJob(1, 5, 'Driver for family trip to Islamabad (2 days)', 4000,
        'in_progress', daysAgo: 2);
    _addJob(1, 1, 'Plaster repair in drawing room', 3000, 'completed',
        daysAgo: 12);
    _addJob(1, 6, 'Cook for wedding dinner, 200 guests', 12000, 'completed',
        daysAgo: 20);
    _addJob(1, 2, 'AC installation in office', 8000, 'completed', daysAgo: 15);
    _addJob(1, 3, 'Fix leaking bathroom pipe', 2500, 'completed', daysAgo: 9);
    _addJob(1, 4, 'Dining table repair and polish', 3500, 'completed',
        daysAgo: 25);

    _addReview(5, 1, 1, 5,
        'Excellent masonry work, finished before time. Highly recommended.');
    _addReview(5, 1, 1, 4, 'Good work, quality achi thi.');
    _addReview(6, 1, 6, 5, 'Khana bohat acha tha, guests loved it!');
    _addReview(6, 1, 6, 4, 'On time and professional.');
    _addReview(7, 1, 2, 5, 'Quick and clean wiring work.');
    _addReview(8, 1, 3, 4, 'Pipe fixed properly, reasonable charges.');
    _addReview(9, 1, 4, 5, 'Beautiful polish work on the table.');

    _addLocation(1, 34.1988, 72.0422);
    _addLocation(2, 34.2050, 72.0500);
  }

  void _addUser(String name, String phone, String role) {
    final id = _userSeq++;
    _users.add(User(
        userId: id,
        name: name,
        phone: phone,
        role: role,
        createdAt: DateTime.now().subtract(const Duration(days: 60))));
    _passwords[id] = '123456';
  }

  void _addLabor(int userId, String about, int experience, double dailyWage,
      double hourlyRate, String availability, List<int> skillIds) {
    final id = _laborSeq++;
    _profiles.add(LaborProfile(
        laborId: id,
        userId: userId,
        skills: about,
        experience: experience,
        dailyWage: dailyWage,
        hourlyRate: hourlyRate,
        availabilityStatus: availability));
    _laborSkills[id] = List.of(skillIds);
  }

  void _addJob(int customerId, int laborId, String description, double budget,
      String status, {required int daysAgo}) {
    _jobs.add(Job(
        jobId: _jobSeq++,
        customerId: customerId,
        laborId: laborId,
        jobDescription: description,
        budget: budget,
        status: status,
        createdAt: DateTime.now().subtract(Duration(days: daysAgo))));
  }

  void _addReview(
      int jobId, int customerId, int laborId, int rating, String comment) {
    _reviews.add(Review(
        reviewId: _reviewSeq++,
        jobId: jobId,
        customerId: customerId,
        laborId: laborId,
        rating: rating,
        comment: comment));
  }

  void _addLocation(int laborId, double latitude, double longitude) {
    _locations.add(LocationEntry(
        locationId: _locSeq++,
        laborId: laborId,
        latitude: latitude,
        longitude: longitude,
        updatedAt: DateTime.now().subtract(const Duration(hours: 5))));
  }

  User? _userById(int id) {
    for (final u in _users) {
      if (u.userId == id) return u;
    }
    return null;
  }

  Skill? _skillById(int id) {
    for (final s in _skills) {
      if (s.skillId == id) return s;
    }
    return null;
  }

  // --------------------------------------------------------------- auth ----

  @override
  Future<User> register(
      {required String name,
      required String phone,
      required String password,
      required String role}) async {
    await _tick();
    if (_users.any((u) => u.phone == phone)) {
      throw Exception('This phone number is already registered');
    }
    final id = _userSeq++;
    final user = User(
        userId: id,
        name: name,
        phone: phone,
        role: role,
        createdAt: DateTime.now());
    _users.add(user);
    _passwords[id] = password;
    if (role == 'laborer') {
      final laborId = _laborSeq++;
      _profiles.add(LaborProfile(
          laborId: laborId, userId: id, availabilityStatus: 'available'));
      _laborSkills[laborId] = [];
    }
    return user;
  }

  @override
  Future<User> login({required String phone, required String password}) async {
    await _tick();
    for (final u in _users) {
      if (u.phone == phone) {
        if (_passwords[u.userId] == password) return u;
        throw Exception('Invalid phone or password');
      }
    }
    throw Exception('Invalid phone or password');
  }

  // -------------------------------------------------------------- skills ---

  @override
  Future<List<Skill>> getSkills() async {
    await _tick();
    return List.of(_skills);
  }

  // ------------------------------------------------------------ laborers ---

  @override
  Future<List<LaborProfile>> getLaborers(
      {String? query, int? skillId}) async {
    await _tick();
    final q = query?.trim().toLowerCase() ?? '';
    return _profiles.where((p) {
      if (skillId != null &&
          !(_laborSkills[p.laborId]?.contains(skillId) ?? false)) {
        return false;
      }
      if (q.isEmpty) return true;
      final user = _userById(p.userId);
      final skillNames = (_laborSkills[p.laborId] ?? [])
          .map((id) => _skillById(id)?.skillName ?? '')
          .join(' ')
          .toLowerCase();
      return (user?.name.toLowerCase().contains(q) ?? false) ||
          skillNames.contains(q) ||
          (p.skills?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Future<LaborerDetail> getLaborerDetail(int laborId) async {
    await _tick();
    final profile = _profiles.firstWhere(
        (p) => p.laborId == laborId,
        orElse: () => throw Exception('Laborer not found'));
    final skills = (_laborSkills[laborId] ?? [])
        .map(_skillById)
        .whereType<Skill>()
        .toList();
    final reviews = _reviews.where((r) => r.laborId == laborId).toList();
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length;
    return LaborerDetail(
        profile: profile, skills: skills, reviews: reviews, avgRating: avg);
  }

  @override
  Future<LaborProfile?> getLaborProfileByUser(int userId) async {
    await _tick();
    for (final p in _profiles) {
      if (p.userId == userId) return p;
    }
    return null;
  }

  @override
  Future<LaborProfile> updateLaborProfile(LaborProfile profile,
      {List<int>? skillIds}) async {
    await _tick();
    final i = _profiles.indexWhere((p) => p.laborId == profile.laborId);
    if (i == -1) throw Exception('Labor profile not found');
    _profiles[i] = profile;
    if (skillIds != null) {
      _laborSkills[profile.laborId] = List.of(skillIds);
    }
    return profile;
  }

  // ---------------------------------------------------------------- jobs ---

  @override
  Future<List<Job>> getJobs(
      {int? customerId, int? laborId, String? status}) async {
    await _tick();
    return _jobs.where((j) {
      if (customerId != null && j.customerId != customerId) return false;
      if (laborId != null && j.laborId != laborId) return false;
      if (status != null && j.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Future<Job> createJob(
      {required int customerId,
      required int laborId,
      required String description,
      required double budget}) async {
    await _tick();
    final job = Job(
        jobId: _jobSeq++,
        customerId: customerId,
        laborId: laborId,
        jobDescription: description,
        budget: budget,
        status: 'pending',
        createdAt: DateTime.now());
    _jobs.add(job);
    return job;
  }

  @override
  Future<Job> updateJobStatus(int jobId, String status) async {
    await _tick();
    final i = _jobs.indexWhere((j) => j.jobId == jobId);
    if (i == -1) throw Exception('Job not found');
    _jobs[i] = _jobs[i].copyWith(status: status);
    return _jobs[i];
  }

  @override
  Future<void> deleteJob(int jobId) async {
    await _tick();
    _jobs.removeWhere((j) => j.jobId == jobId);
    _reviews.removeWhere((r) => r.jobId == jobId);
  }

  // -------------------------------------------------------------- reviews --

  @override
  Future<List<Review>> getReviews({int? laborId, int? jobId}) async {
    await _tick();
    return _reviews.where((r) {
      if (laborId != null && r.laborId != laborId) return false;
      if (jobId != null && r.jobId != jobId) return false;
      return true;
    }).toList();
  }

  @override
  Future<Review> addReview(
      {required int jobId,
      required int customerId,
      required int laborId,
      required int rating,
      required String comment}) async {
    await _tick();
    final review = Review(
        reviewId: _reviewSeq++,
        jobId: jobId,
        customerId: customerId,
        laborId: laborId,
        rating: rating.clamp(1, 5),
        comment: comment);
    _reviews.add(review);
    return review;
  }

  // ------------------------------------------------------------ favorites --

  @override
  Future<bool> toggleFavorite(
      {required int customerId, required int laborId}) async {
    await _tick();
    final i = _favorites.indexWhere(
        (f) => f.customerId == customerId && f.laborId == laborId);
    if (i != -1) {
      _favorites.removeAt(i);
      return false;
    }
    _favorites.add(Favorite(
        favoriteId: _favSeq++,
        customerId: customerId,
        laborId: laborId,
        createdAt: DateTime.now()));
    return true;
  }

  @override
  Future<List<Favorite>> getFavorites(int customerId) async {
    await _tick();
    return _favorites.where((f) => f.customerId == customerId).toList();
  }

  @override
  Future<bool> isFavorite(
      {required int customerId, required int laborId}) async {
    await _tick();
    return _favorites.any(
        (f) => f.customerId == customerId && f.laborId == laborId);
  }

  // ------------------------------------------------------------ locations --

  @override
  Future<LocationEntry> updateLocation(
      {required int laborId,
      required double latitude,
      required double longitude}) async {
    await _tick();
    final entry = LocationEntry(
        locationId: _locSeq++,
        laborId: laborId,
        latitude: latitude,
        longitude: longitude,
        updatedAt: DateTime.now());
    _locations.add(entry);
    return entry;
  }

  @override
  Future<LocationEntry?> getLatestLocation(int laborId) async {
    await _tick();
    LocationEntry? latest;
    for (final l in _locations) {
      if (l.laborId == laborId &&
          (latest == null || l.locationId > latest.locationId)) {
        latest = l;
      }
    }
    return latest;
  }

  // ---------------------------------------------------------------- users --

  @override
  Future<List<User>> getUsers() async {
    await _tick();
    return List.of(_users);
  }

  @override
  Future<void> deleteUser(int userId) async {
    await _tick();
    _users.removeWhere((u) => u.userId == userId);
    _passwords.remove(userId);
    final laborIds =
        _profiles.where((p) => p.userId == userId).map((p) => p.laborId).toSet();
    _profiles.removeWhere((p) => p.userId == userId);
    for (final id in laborIds) {
      _laborSkills.remove(id);
      _locations.removeWhere((l) => l.laborId == id);
      _favorites.removeWhere((f) => f.laborId == id);
    }
    _jobs.removeWhere((j) => j.customerId == userId);
    _reviews.removeWhere((r) => r.customerId == userId);
    _favorites.removeWhere((f) => f.customerId == userId);
  }
}
