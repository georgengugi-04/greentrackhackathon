# 🌿 GreenTrack — Garden-to-Table Crop Tracking App

A complete, production-grade Flutter mobile application for tracking crop production,
monitoring garden plots, logging harvests, and analyzing agricultural data — built to
match the **GreenTrack** brand ("Cultivating Conscious Consumption").

This is a full month-scale build: ~20 screens, a complete design system, multi-step
forms, animated charts, and a realistic mock-data layer that mirrors a production
backend's shape so it's a straightforward swap to real API/Firebase/Supabase calls.

---

## ✨ Features

### Core Tracking
- **Crop Lifecycle Management** — 9-stage lifecycle (seedling → sprouting → vegetative →
  flowering → fruiting → ready-to-harvest → harvested, plus concern/failed states), each
  with its own color, emoji, and animated progress value.
- **Garden Plot Management** — multiple plots/beds/containers with soil type, sun
  exposure, irrigation, and per-plot crop rosters.
- **Growth Tracking** — height, leaf count, health status, flowering/fruiting flags,
  freeform notes, charted over time with `fl_chart`.
- **Harvest Logging** — quantity, quality rating (5-point emoji scale), destination
  (consumed / sold / donated / stored / composted), price-per-kg and buyer info for
  sales, full harvest history log.
- **Activity Timeline** — watering, fertilizing, pruning, pest control, transplanting,
  and observation logs, rendered as a vertical timeline per crop.

### Analytics & Reporting
- Season KPI dashboard (active crops, yield vs. goal, near-harvest count, attention flags)
- Monthly yield bar charts (year-over-year comparison)
- Crop status distribution pie chart
- Yield-by-crop ranked bar chart with "Top Performers" leaderboard
- Water usage line chart + per-crop usage breakdown
- Produce destination donut chart
- Report generation list (season summary, yield analysis, resource usage, etc.)

### UX Details
- Animated splash screen + 3-page onboarding carousel
- Multi-step "Add Crop" wizard (Basics → Location → Schedule → Review) with progress stepper
- Bottom-sheet "Quick Actions" launcher (Add Crop / Water / Harvest / Growth / Fertilize / Photo)
- Swipe-to-action crop & notification list items (`flutter_slidable`)
- Pull-through navigation: Dashboard → Crop Detail (4 tabs: Overview/Growth/Activity/Photos)
- Weather bar with garden-relevant tips
- Achievement badges, season goal progress ring
- Full notification center with read/unread state and swipe-to-delete

---

## 🏗️ Architecture

```
lib/
├── core/
│   └── theme/
│       └── app_theme.dart        # Design tokens: colors, typography, spacing, shadows
├── data/
│   └── models/
│       └── models.dart           # All enums, data models, and MockData seed dataset
├── features/
│   ├── auth/screens/             # Splash, Onboarding, Login
│   ├── dashboard/
│   │   ├── screens/              # MainShell (bottom nav host) + Dashboard home
│   │   └── widgets/              # Quick action bottom sheet
│   ├── crops/screens/            # Crop list, detail, add-crop wizard
│   ├── garden/screens/           # Plot list, plot detail
│   ├── harvest/screens/          # Harvest log list, log-harvest form
│   ├── growth/screens/           # Add growth-measurement form
│   ├── analytics/screens/        # 4-tab analytics dashboard
│   ├── notifications/screens/    # Notification center
│   ├── profile/screens/          # Profile, achievements, settings menu
│   └── shared/widgets/           # Reusable EmptyState, StatusBadge, SectionCard, etc.
└── main.dart                     # App entry point, theme wiring, go_router routes
```

**State management:** `flutter_riverpod` is wired in at the app root (`ProviderScope`)
and ready for provider-based state; the current build uses a static `MockData` class
in `data/models/models.dart` standing in for a repository layer so every screen has
realistic, interconnected data (crops reference plots, harvests reference crops, etc.)
out of the box. Swapping in real persistence means writing repository classes that
return the same model types and wiring them through Riverpod providers — no UI changes
required.

**Navigation:** `go_router` with named paths (`/crops/:id`, `/garden/:id`, etc.) so deep
linking and push notifications can route directly into detail screens.

**Design system:** every color, spacing value, radius, and shadow lives in
`core/theme/app_theme.dart` as static constants (`AppColors`, `AppTextStyles`,
`AppSpacing`, `AppRadius`, `AppShadows`) — change the brand palette in one file and
the whole app updates.

---

## 📦 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.16.0 (`flutter --version` to check)
- Dart SDK ≥ 3.2.0
- Android Studio / Xcode for platform builds, or VS Code with Flutter extension

### Setup

```bash
# 1. Get dependencies
flutter pub get

# 2. Generate platform folders (if not present)
flutter create .

# 3. Run on a connected device or emulator
flutter run

# 4. Build release artifacts
flutter build apk --release          # Android
flutter build ios --release          # iOS (requires macOS + Xcode)
```

### Fonts
The app uses **Google Fonts** (`google_fonts` package) for Playfair Display + Inter,
fetched at runtime — no manual font files needed unless you want offline-bundled fonts
for App Store review consistency, in which case drop `.ttf` files into `assets/fonts/`
(a placeholder reference is already in `pubspec.yaml`).

---

## 🔌 Wiring Up a Real Backend

Replace `MockData` calls with Riverpod `FutureProvider`/`StreamProvider` repositories,
e.g.:

```dart
final cropsProvider = StreamProvider<List<CropModel>>((ref) {
  return FirebaseFirestore.instance
    .collection('crops')
    .snapshots()
    .map((snap) => snap.docs.map((d) => CropModel.fromJson(d.data())).toList());
});
```

Then in any screen, swap `MockData.crops` for `ref.watch(cropsProvider).value ?? []`.
The model shapes (`CropModel`, `GardenPlot`, `HarvestRecord`, `GrowthRecord`,
`ActivityLog`) are already structured to map cleanly onto Firestore documents, a
REST API, or local SQLite (`sqflite` is already in `pubspec.yaml` for offline-first
support).

---

## 🎨 Brand

| Token | Value |
|---|---|
| Forest (primary) | `#1B4332` |
| Leaf (secondary) | `#40916C` |
| Mint (accent) | `#95D5B2` |
| Amber (harvest) | `#D4A017` |
| Parchment (bg) | `#F8F4EE` |
| Display font | Playfair Display |
| Body/UI font | Inter |
| Data/mono font | JetBrains Mono |

---

## 📄 License

Internal project deliverable — adapt freely for your own GreenTrack deployment.
