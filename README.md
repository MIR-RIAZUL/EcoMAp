# 🗺️ EchoMap

<div align="center">

**Your Life as a Memory Map**

*A peaceful, offline-first personal memory journal that grounds your life moments onto an interactive map.*

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State_Management-Riverpod_2.6-blueviolet?style=for-the-badge)](https://riverpod.dev)
[![Database](https://img.shields.io/badge/Local_DB-Drift_(SQLite)-4169E1?style=for-the-badge)](https://drift.simonbinder.eu/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](#license)

</div>

---

## 📖 Overview

**EchoMap** is a mobile journaling application designed around spatial memory. Instead of burying your memories in endless linear feeds, EchoMap turns your experiences into interactive map pins, chronological timeline cards, and rich media entries.

Built with a **Privacy-First & 100% Offline** architecture: your memories, thoughts, photos, and location coordinates remain strictly on your local device — no tracking, no ads, no cloud requirement, and zero telemetry.

---

## ✨ Key Features

### 📍 Interactive Memory Map
- **OpenStreetMap Integration**: 100% free and open map layer using `flutter_map` (no Google Maps API billing or key required).
- **Custom Tile Styling**: Tailored light mode and an inverted contrast dark mode tile matrix filter.
- **Mood-Color Pins**: Every map pin visually reflects the emotional mood of that moment with distinct colors and emojis.
- **Quick Preview Sheet**: Tap any map marker to preview photos, date, tags, and notes, with direct navigation to full memory details.
- **GPS Auto-Center**: Quick button to locate and zoom directly to your current live location.

### 📝 Rich Journaling & Memory Capture
- **Media Attachments**: Capture and attach photos directly from camera or device gallery.
- **Location Geocoding**: Pick points on an interactive map picker with automatic reverse geocoding into readable street and city names.
- **Mood Tracking**: Tag memories with 7 expressive emotional states (`Happy`, `Sad`, `Love`, `Excited`, `Peaceful`, `Angry`, `Neutral`).
- **Flexible Tagging**: Organize with default preset tags (`Travel`, `Family`, `Friends`, `Food`, `Nature`, `Work`, `Milestone`, etc.) or add custom tags.
- **Favorites**: Star memories for quick recall.

### ⏳ Chronological Timeline
- Seamless timeline stream grouped by date with visual connector nodes and mood accents.
- Card view highlighting title, description, timestamp, location name, and attached photography.

### 🔍 Advanced Search & Filter Engine
- **Instant Search**: Search across memory titles, descriptions, and location names.
- **Filter Sheet**: Multi-criteria filtering by:
  - Date ranges
  - Mood categories
  - Tag lists
  - Favorites only

### 📊 Insights & Stats Dashboard
- Summary card displaying total logged memories, favorite counts, top mood distribution, and total places visited.

### 🌗 Dynamic Theming & Design System
- Modern Material 3 design system with custom brand colors (`#3A6D8C`, `#6A9AB0`, `#EAD8B1`, `#001F3F`).
- Support for **System**, **Light**, and **Dark** themes with persistent theme preference.

### 🔒 100% Private & Offline-First
- Powered by [Drift](https://drift.simonbinder.eu/) (SQLite) with reactive query streams.
- All photos stored in local app-sandboxed internal storage.

---

## 🏗️ Architecture & Tech Stack

```
lib/
├── app.dart                   # Root MaterialApp with theme & routing configuration
├── main.dart                  # Flutter entrypoint & ProviderScope initialization
├── core/
│   ├── constants/             # App constants, defaults, and Mood enum definitions
│   ├── theme/                 # AppColors, custom ColorSchemes & AppTheme (Light & Dark)
│   └── utils/                 # Date formatting & helper utilities
├── data/
│   └── database/              # Drift SQLite database, table definitions & migration logic
│       ├── app_database.dart  # AppDatabase class & queries
│       └── tables/            # Drift table schemas (memories_table.dart)
├── features/
│   └── memories/
│       ├── models/            # MemoryItem model & companion converters
│       ├── providers/         # Riverpod providers (database, search, filter, theme)
│       ├── screens/           # MainNavScaffold, Home, Map, Timeline, Details, Add, Settings
│       └── widgets/           # Map picker sheet, MemoryCard, MoodSelector, SearchBar, etc.
└── shared/
    └── widgets/               # Reusable confirmation dialogs & UI primitives
```

### Core Technologies

| Technology | Purpose |
|---|---|
| **Flutter SDK** (Dart 3.8+) | Cross-platform UI toolkit |
| **flutter_riverpod** (`^2.6.1`) | Reactive state management & dependency injection |
| **drift** & **drift_flutter** (`^2.24.2`) | Type-safe, reactive SQLite persistence |
| **flutter_map** (`^7.0.2`) & **latlong2** | Leaflet-style OpenStreetMap rendering |
| **geolocator** (`^13.0.2`) & **geocoding** | GPS location access & reverse geocoding |
| **image_picker** (`^1.1.2`) | Photo selection from camera & gallery |
| **shared_preferences** (`^2.3.5`) | Lightweight persistent key-value storage (theme mode) |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.8.1`)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code with Flutter extension
- Android device or emulator with Google Play Services (API 21+)

### Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/MIR-RIAZUL/EcoMAp.git
   cd EcoMAp
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Drift Database code**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

Run the automated test suite including repository unit tests and search/filter verification:

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/memory_repository_test.dart
flutter test test/search_filter_test.dart
```

---

## 📱 Permissions Configuration

### Android (`android/app/src/main/AndroidManifest.xml`)

EchoMap declares the following permissions:
- `android.permission.INTERNET`: Required for fetching OpenStreetMap raster tiles.
- `android.permission.ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION`: Required for pinning live GPS coordinates and auto-centering on the map.
- `android.permission.CAMERA`: Required for capturing photos within memories.
- `android.permission.READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`: Required for choosing existing photos from device gallery.

> [!NOTE]
> Location permissions are requested at runtime only when the user taps the GPS auto-center button or uses current location in the location picker.

---

## 🛡️ Privacy Policy

EchoMap takes privacy seriously:
- **No telemetry**: There are no analytics libraries, crashlytics reporting, or marketing trackers embedded in the app.
- **No remote account required**: All memories and photos exist strictly within your device's isolated app sandbox storage.
- **No remote server synchronization**: Data is stored inside an on-device SQLite database managed by Drift.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
