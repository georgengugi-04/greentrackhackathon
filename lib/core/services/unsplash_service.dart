// Auto-fetches a representative photo for a crop by name (e.g. "Lettuce",
// "Carrots") from Unsplash, so farmers no longer need to take/upload a
// photo themselves when logging a new batch.
//
// ── To go live ────────────────────────────────────────────────────────
// 1. Get a free Access Key: https://unsplash.com/developers (Demo tier:
//    50 requests/hour — plenty for a class demo; Production tier is free
//    too, just requires Unsplash's review before going out to real users).
// 2. Run with `--dart-define=UNSPLASH_ACCESS_KEY=your_key_here`.
// 3. Nothing else changes — every screen calls through
//    `UnsplashService.instance`, same pattern as AiVisionService.
//
// Unsplash's API guidelines require: (a) hotlinking their CDN URL rather
// than re-hosting the image, and (b) firing `trackDownload` when a photo
// is actually used in-app (not just previewed) — both handled here.
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UnsplashPhoto {
  final String url; // hotlink-ready CDN url (Unsplash's `regular` size)
  final String thumbUrl;
  final String photographerName;
  final String photographerProfileUrl;
  final String? downloadLocation; // ping this once the photo is actually used

  const UnsplashPhoto({
    required this.url,
    required this.thumbUrl,
    required this.photographerName,
    required this.photographerProfileUrl,
    this.downloadLocation,
  });
}

abstract class UnsplashService {
  /// Looks up the single best-matching photo for [query] (e.g. a crop
  /// name). Returns null if unavailable — callers should treat that as
  /// "no photo" and fall back to the leaf-icon placeholder, never an error.
  Future<UnsplashPhoto?> photoFor(String query);

  /// Confirms actual use of a previously-returned photo, per Unsplash API
  /// guidelines. Safe to call even if [photo.downloadLocation] is null.
  Future<void> trackDownload(UnsplashPhoto photo);

  /// Swap this for `RemoteUnsplashService(accessKey: ...)` once a key is
  /// available; every screen calls through this single access point.
  static UnsplashService instance = _NoopUnsplashService();
}

/// Default when no access key is configured — returns no photo, so the UI
/// falls back to its placeholder rather than erroring.
class _NoopUnsplashService implements UnsplashService {
  @override
  Future<UnsplashPhoto?> photoFor(String query) async => null;
  @override
  Future<void> trackDownload(UnsplashPhoto photo) async {}
}

class RemoteUnsplashService implements UnsplashService {
  final String accessKey;
  final http.Client _client;
  RemoteUnsplashService({required this.accessKey, http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<UnsplashPhoto?> photoFor(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || accessKey.isEmpty) return null;

    try {
      final uri = Uri.https('api.unsplash.com', '/search/photos', {
        'query': '$trimmed crop farm produce',
        'per_page': '1',
        'orientation': 'landscape',
        'content_filter': 'high',
      });
      final res = await _client.get(uri, headers: {
        'Authorization': 'Client-ID $accessKey',
        'Accept-Version': 'v1',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final r = results.first as Map<String, dynamic>;
      final urls = r['urls'] as Map<String, dynamic>;
      final user = r['user'] as Map<String, dynamic>;
      final links = r['links'] as Map<String, dynamic>?;
      final userLinks = user['links'] as Map<String, dynamic>?;

      return UnsplashPhoto(
        url: urls['regular'] as String,
        thumbUrl: (urls['small'] ?? urls['regular']) as String,
        photographerName: user['name'] as String? ?? 'Unknown',
        photographerProfileUrl: userLinks?['html'] as String? ?? 'https://unsplash.com',
        downloadLocation: links?['download_location'] as String?,
      );
    } catch (e) {
      // Network hiccup, rate limit, or bad key — never let a photo lookup
      // block crop logging. Caller falls back to the placeholder.
      return null;
    }
  }

  @override
  Future<void> trackDownload(UnsplashPhoto photo) async {
    final loc = photo.downloadLocation;
    if (loc == null || loc.isEmpty) return;
    try {
      await _client
          .get(Uri.parse(loc), headers: {'Authorization': 'Client-ID $accessKey'})
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Attribution ping is best-effort — never block the save flow on it.
    }
  }
}
