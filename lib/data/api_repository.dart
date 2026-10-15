import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/favorite.dart';
import '../models/job.dart';
import '../models/labor_profile.dart';
import '../models/laborer_detail.dart';
import '../models/location_entry.dart';
import '../models/review.dart';
import '../models/skill.dart';
import '../models/user.dart';
import 'app_repository.dart';

/// REST implementation against the Node.js/Express backend at [kApiBaseUrl].
///
/// The JWT returned by login/register is kept in memory and in
/// SharedPreferences under `auth_token`, and sent as
/// `Authorization: Bearer <token>` on every authenticated call.
class ApiRepository implements AppRepository {
  static const _tokenKey = 'auth_token';

  String? _token;

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      _token ??=
          (await SharedPreferences.getInstance()).getString(_tokenKey);
      final token = _token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    await (await SharedPreferences.getInstance()).setString(_tokenKey, token);
  }

  /// Clears the stored JWT (used on logout).
  Future<void> clearToken() async {
    _token = null;
    await (await SharedPreferences.getInstance()).remove(_tokenKey);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(res.body);
    }
    var message = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        final m = body['message'] ?? body['error'];
        if (m != null) message = m.toString();
      }
    } catch (_) {
      // fall through with the generic message
    }
    throw Exception(message);
  }

  List<dynamic> _asList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] is List) {
      return decoded['data'] as List;
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
  }

  // --------------------------------------------------------------- auth ----

  @override
  Future<User> register(
      {required String name,
      required String phone,
      required String password,
      required String role}) async {
    final res = await http.post(
      Uri.parse('$kApiBaseUrl/api/auth/register'),
      headers: await _headers(withAuth: false),
      body: jsonEncode(
          {'name': name, 'phone': phone, 'password': password, 'role': role}),
    );
    final data = _asMap(_decode(res));
    final token = data['token'] as String?;
    if (token != null) await _saveToken(token);
    return User.fromJson(_asMap(data['user']));
  }

  @override
  Future<User> login(
      {required String phone, required String password}) async {
    final res = await http.post(
      Uri.parse('$kApiBaseUrl/api/auth/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final data = _asMap(_decode(res));
    final token = data['token'] as String?;
    if (token != null) await _saveToken(token);
    return User.fromJson(_asMap(data['user']));
  }

  // -------------------------------------------------------------- skills ---

  @override
  Future<List<Skill>> getSkills() async {
    final res = await http.get(
      Uri.parse('$kApiBaseUrl/api/skills'),
      headers: await _headers(),
    );
    return _asList(_decode(res))
        .map((e) => Skill.fromJson(_asMap(e)))
        .toList();
  }

  // ------------------------------------------------------------ laborers ---

  @override
  Future<List<LaborProfile>> getLaborers(
      {String? query, int? skillId}) async {
    final uri = Uri.parse('$kApiBaseUrl/api/labor-profiles').replace(
      queryParameters: {
        if (query != null && query.isNotEmpty) 'query': query,
        if (skillId != null) 'skill_id': '$skillId',
      },
    );
    final res = await http.get(uri, headers: await _headers());
    return _asList(_decode(res))
        .map((e) => LaborProfile.fromJson(_asMap(e)))
        .toList();
  }

  @override
  Future<LaborerDetail> getLaborerDetail(int laborId) async {
    final profileRes = await http.get(
      Uri.parse('$kApiBaseUrl/api/labor-profiles/$laborId'),
      headers: await _headers(),
    );
    final profile = LaborProfile.fromJson(_asMap(_decode(profileRes)));

    final linksRes = await http.get(
      Uri.parse('$kApiBaseUrl/api/labor-skills?labor_id=$laborId'),
      headers: await _headers(),
    );
    final links = _asList(_decode(linksRes));

    final skills = <Skill>[];
    if (links.isNotEmpty && _asMap(links.first).containsKey('skill_name')) {
      for (final l in links) {
        skills.add(Skill.fromJson(_asMap(l)));
      }
    } else {
      final byId = {for (final s in await getSkills()) s.skillId: s};
      for (final l in links) {
        final sid = (_asMap(l)['skill_id'] as num?)?.toInt();
        final s = sid == null ? null : byId[sid];
        if (s != null) skills.add(s);
      }
    }

    final reviews = await getReviews(laborId: laborId);
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length;
    return LaborerDetail(
        profile: profile, skills: skills, reviews: reviews, avgRating: avg);
  }

  @override
  Future<LaborProfile?> getLaborProfileByUser(int userId) async {
    final res = await http.get(
      Uri.parse('$kApiBaseUrl/api/labor-profiles/by-user/$userId'),
      headers: await _headers(),
    );
    if (res.statusCode == 404) return null;
    final decoded = _decode(res);
    if (decoded is Map && decoded.isEmpty) return null;
    return LaborProfile.fromJson(_asMap(decoded));
  }

  @override
  Future<LaborProfile> updateLaborProfile(LaborProfile profile,
      {List<int>? skillIds}) async {
    final res = await http.put(
      Uri.parse('$kApiBaseUrl/api/labor-profiles/${profile.laborId}'),
      headers: await _headers(),
      body: jsonEncode(profile.toJson()),
    );
    final saved = LaborProfile.fromJson(_asMap(_decode(res)));

    if (skillIds != null) {
      final linksRes = await http.get(
        Uri.parse('$kApiBaseUrl/api/labor-skills?labor_id=${profile.laborId}'),
        headers: await _headers(),
      );
      final current = _asList(_decode(linksRes))
          .map((e) => (_asMap(e)['skill_id'] as num?)?.toInt())
          .whereType<int>()
          .toSet();
      final wanted = skillIds.toSet();
      for (final id in wanted.difference(current)) {
        await http.post(
          Uri.parse('$kApiBaseUrl/api/labor-skills'),
          headers: await _headers(),
          body: jsonEncode(
              {'labor_id': profile.laborId, 'skill_id': id}),
        );
      }
      for (final id in current.difference(wanted)) {
        await http.delete(
          Uri.parse('$kApiBaseUrl/api/labor-skills/${profile.laborId}/$id'),
          headers: await _headers(),
        );
      }
    }
    return saved;
  }

  // ---------------------------------------------------------------- jobs ---

  @override
  Future<List<Job>> getJobs(
      {int? customerId, int? laborId, String? status}) async {
    final uri = Uri.parse('$kApiBaseUrl/api/jobs').replace(
      queryParameters: {
        if (customerId != null) 'customer_id': '$customerId',
        if (laborId != null) 'labor_id': '$laborId',
        if (status != null) 'status': status,
      },
    );
    final res = await http.get(uri, headers: await _headers());
    return _asList(_decode(res)).map((e) => Job.fromJson(_asMap(e))).toList();
  }

  @override
  Future<Job> createJob(
      {required int customerId,
      required int laborId,
      required String description,
      required double budget}) async {
    final res = await http.post(
      Uri.parse('$kApiBaseUrl/api/jobs'),
      headers: await _headers(),
      body: jsonEncode({
        'customer_id': customerId,
        'labor_id': laborId,
        'job_description': description,
        'budget': budget,
        'status': 'pending',
      }),
    );
    return Job.fromJson(_asMap(_decode(res)));
  }

  @override
  Future<Job> updateJobStatus(int jobId, String status) async {
    final res = await http.patch(
      Uri.parse('$kApiBaseUrl/api/jobs/$jobId/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    return Job.fromJson(_asMap(_decode(res)));
  }

  @override
  Future<void> deleteJob(int jobId) async {
    final res = await http.delete(
      Uri.parse('$kApiBaseUrl/api/jobs/$jobId'),
      headers: await _headers(),
    );
    _decode(res);
  }

  // -------------------------------------------------------------- reviews --

  @override
  Future<List<Review>> getReviews({int? laborId, int? jobId}) async {
    final uri = Uri.parse('$kApiBaseUrl/api/reviews').replace(
      queryParameters: {
        if (laborId != null) 'labor_id': '$laborId',
        if (jobId != null) 'job_id': '$jobId',
      },
    );
    final res = await http.get(uri, headers: await _headers());
    return _asList(_decode(res))
        .map((e) => Review.fromJson(_asMap(e)))
        .toList();
  }

  @override
  Future<Review> addReview(
      {required int jobId,
      required int customerId,
      required int laborId,
      required int rating,
      required String comment}) async {
    final res = await http.post(
      Uri.parse('$kApiBaseUrl/api/reviews'),
      headers: await _headers(),
      body: jsonEncode({
        'job_id': jobId,
        'customer_id': customerId,
        'labor_id': laborId,
        'rating': rating,
        'comment': comment,
      }),
    );
    return Review.fromJson(_asMap(_decode(res)));
  }

  // ------------------------------------------------------------ favorites --

  @override
  Future<bool> toggleFavorite(
      {required int customerId, required int laborId}) async {
    final res = await http.post(
      Uri.parse('$kApiBaseUrl/api/favorites/toggle'),
      headers: await _headers(),
      body: jsonEncode({'customer_id': customerId, 'labor_id': laborId}),
    );
    final data = _asMap(_decode(res));
    return data['favorited'] == true;
  }

  @override
  Future<List<Favorite>> getFavorites(int customerId) async {
    final res = await http.get(
      Uri.parse('$kApiBaseUrl/api/favorites/customer/$customerId'),
      headers: await _headers(),
    );
    return _asList(_decode(res))
        .map((e) => Favorite.fromJson(_asMap(e)))
        .toList();
  }

  @override
  Future<bool> isFavorite(
      {required int customerId, required int laborId}) async {
    final favorites = await getFavorites(customerId);
    return favorites.any((f) => f.laborId == laborId);
  }

  // ------------------------------------------------------------ locations --

  @override
  Future<LocationEntry> updateLocation(
      {required int laborId,
      required double latitude,
      required double longitude}) async {
    final res = await http.post(
      Uri.parse('$kApiBaseUrl/api/locations'),
      headers: await _headers(),
      body: jsonEncode({
        'labor_id': laborId,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return LocationEntry.fromJson(_asMap(_decode(res)));
  }

  @override
  Future<LocationEntry?> getLatestLocation(int laborId) async {
    final res = await http.get(
      Uri.parse('$kApiBaseUrl/api/locations/labor/$laborId/latest'),
      headers: await _headers(),
    );
    if (res.statusCode == 404) return null;
    final decoded = _decode(res);
    if (decoded is Map && decoded.isEmpty) return null;
    return LocationEntry.fromJson(_asMap(decoded));
  }

  // ---------------------------------------------------------------- users --

  @override
  Future<List<User>> getUsers() async {
    final res = await http.get(
      Uri.parse('$kApiBaseUrl/api/users'),
      headers: await _headers(),
    );
    return _asList(_decode(res))
        .map((e) => User.fromJson(_asMap(e)))
        .toList();
  }

  @override
  Future<void> deleteUser(int userId) async {
    final res = await http.delete(
      Uri.parse('$kApiBaseUrl/api/users/$userId'),
      headers: await _headers(),
    );
    _decode(res);
  }
}
