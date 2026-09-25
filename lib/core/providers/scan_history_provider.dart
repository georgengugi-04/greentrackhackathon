import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_providers.dart';
import '../../data/models/models.dart';

enum ScanKind { batch, meal }

/// One real, previously-scanned item — a crop batch or a meal — recorded
/// the moment a QR scan actually resolves (see [ScanHistoryController]).
/// Nothing here is seeded or mocked.
class ScanHistoryEntry {
  final ScanKind kind;
  final String id; // batchId or mealId — used to reopen the trace screen
  final String title; // crop name, or meal name
  final String subtitle; // "variety · farm", or restaurant name
  final bool badge; // organic-certified (batch only)
  final DateTime scannedAt;

  const ScanHistoryEntry({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.scannedAt,
  });

  factory ScanHistoryEntry.fromBatch(BatchTraceResult r) => ScanHistoryEntry(
        kind: ScanKind.batch,
        id: r.batchId,
        title: r.cropName,
        subtitle: '${r.variety} · ${r.farmName}',
        badge: r.isOrganicCertified,
        scannedAt: DateTime.now(),
      );

  factory ScanHistoryEntry.fromMeal(Meal m) => ScanHistoryEntry(
        kind: ScanKind.meal,
        id: m.id,
        title: m.name,
        subtitle: m.restaurantName,
        badge: false,
        scannedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'badge': badge,
        'scannedAt': scannedAt.toIso8601String(),
      };

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> j) {
    // Older cache entries (pre-meal-support) used batch-only field names —
    // read those too so nobody's existing history silently vanishes.
    final isLegacy = j.containsKey('batchId');
    return ScanHistoryEntry(
      kind: isLegacy
          ? ScanKind.batch
          : ScanKind.values.byName(j['kind'] as String),
      id: (isLegacy ? j['batchId'] : j['id']) as String,
      title: (isLegacy ? j['cropName'] : j['title']) as String,
      subtitle: isLegacy
          ? '${j['variety']} · ${j['farmName']}'
          : j['subtitle'] as String,
      badge: (isLegacy ? j['isOrganicCertified'] : j['badge']) as bool,
      scannedAt: DateTime.parse(j['scannedAt'] as String),
    );
  }
}

/// Persists this signed-in user's real scan history locally (most-recent
/// first, capped at 30) so "Recent Scans" reflects what they've actually
/// scanned instead of a fixed sample product.
class ScanHistoryController extends Notifier<List<ScanHistoryEntry>> {
  static const _maxEntries = 30;

  String get _prefsKey {
    final uid = ref.read(currentUserIdProvider) ?? 'guest';
    return 'greentrack_scan_history_$uid';
  }

  @override
  List<ScanHistoryEntry> build() {
    _loadSaved();
    return const [];
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => ScanHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {
      // Corrupt/old-format cache — ignore and start fresh rather than crash.
    }
  }

  Future<void> _add(ScanHistoryEntry entry) async {
    // De-dupe by (kind, id): re-scanning the same batch or meal moves it
    // to the top instead of creating a second row.
    final next = [
      entry,
      ...state.where((e) => !(e.kind == entry.kind && e.id == entry.id)),
    ].take(_maxEntries).toList();
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey, jsonEncode(next.map((e) => e.toJson()).toList()));
  }

  Future<void> recordBatch(BatchTraceResult result) =>
      _add(ScanHistoryEntry.fromBatch(result));

  Future<void> recordMeal(Meal meal) => _add(ScanHistoryEntry.fromMeal(meal));

  Future<void> clear() async {
    state = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

final scanHistoryProvider =
    NotifierProvider<ScanHistoryController, List<ScanHistoryEntry>>(
        ScanHistoryController.new);
