import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/mood_types.dart';
import '../../../core/theme/app_colors.dart';
import '../models/memory_item.dart';
import '../providers/memory_providers.dart';
import '../widgets/memory_preview_sheet.dart';
import 'add_memory_screen.dart';
import 'memory_details_screen.dart';

class MemoryMapScreen extends ConsumerStatefulWidget {
  const MemoryMapScreen({super.key});

  @override
  ConsumerState<MemoryMapScreen> createState() => _MemoryMapScreenState();
}

class _MemoryMapScreenState extends ConsumerState<MemoryMapScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _initialFitDone = false;
  bool _onlyFavorites = false;
  Mood? _filterMood;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMarkerTapped(MemoryItem memory) {
    MemoryPreviewSheet.show(
      context,
      memory: memory,
      onViewDetails: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemoryDetailsScreen(initialMemory: memory),
          ),
        );
      },
    );
  }

  void _recenterOnMemories(List<MemoryItem> memoriesWithLocation) {
    if (!_mapReady) return;
    if (memoriesWithLocation.isEmpty) {
      _mapController.move(
        const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
        AppConstants.defaultZoom,
      );
      return;
    }

    if (memoriesWithLocation.length == 1) {
      final single = memoriesWithLocation.first;
      _mapController.move(LatLng(single.latitude!, single.longitude!), 14.0);
      return;
    }

    double minLat = memoriesWithLocation.first.latitude!;
    double maxLat = memoriesWithLocation.first.latitude!;
    double minLng = memoriesWithLocation.first.longitude!;
    double maxLng = memoriesWithLocation.first.longitude!;

    for (final m in memoriesWithLocation) {
      if (m.latitude! < minLat) minLat = m.latitude!;
      if (m.latitude! > maxLat) maxLat = m.latitude!;
      if (m.longitude! < minLng) minLng = m.longitude!;
      if (m.longitude! > maxLng) maxLng = m.longitude!;
    }

    // Guard against identical / near-identical coordinates to avoid divide-by-zero bounds
    if ((maxLat - minLat).abs() < 0.0001 && (maxLng - minLng).abs() < 0.0001) {
      _mapController.move(LatLng(minLat, minLng), 14.0);
      return;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
        maxZoom: 16.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allMemoriesAsync = ref.watch(allMemoriesStreamProvider);

    // Auto-center camera when memories stream emits for the first time
    ref.listen<AsyncValue<List<MemoryItem>>>(allMemoriesStreamProvider, (prev, next) {
      if (next.hasValue && !_initialFitDone && _mapReady) {
        final loc = (next.value ?? []).where((m) => m.hasLocation).toList();
        if (loc.isNotEmpty) {
          _initialFitDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _recenterOnMemories(loc);
          });
        }
      }
    });

    // Compute filtered list once — used by both markers and empty-state banner.
    final allMemories = allMemoriesAsync.value ?? [];
    var localized = allMemories.where((m) => m.hasLocation).toList();
    if (_onlyFavorites) localized = localized.where((m) => m.isFavorite).toList();
    if (_filterMood != null) localized = localized.where((m) => m.mood == _filterMood).toList();

    final initialCenter = localized.isNotEmpty
        ? LatLng(localized.first.latitude!, localized.first.longitude!)
        : const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);
    final initialZoom = localized.isNotEmpty ? 13.0 : 4.0;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map Canvas ────────────────────────────────────────────────
          // Stable ValueKey prevents FlutterMap from being torn down on
          // every setState, which would reset the camera position.
          FlutterMap(
            key: const ValueKey('memory_map'),
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              minZoom: 2.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
                enableMultiFingerGestureRace: true,
              ),
              onMapReady: () {
                setState(() => _mapReady = true);
                if (!_initialFitDone) {
                  final all = ref.read(allMemoriesStreamProvider).value ?? [];
                  final loc = all.where((m) => m.hasLocation).toList();
                  if (loc.isNotEmpty) {
                    _initialFitDone = true;
                    _recenterOnMemories(loc);
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.mapTileUrl,
                userAgentPackageName: AppConstants.mapPackageUserAgent,
                tileBuilder: isDark
                    ? (context, tileWidget, tile) => ColorFiltered(
                          colorFilter: const ColorFilter.matrix(AppConstants.darkMapMatrix),
                          child: tileWidget,
                        )
                    : null,
              ),
              if (allMemoriesAsync.hasValue)
                MarkerLayer(
                  markers: localized.map((memory) {
                    return Marker(
                      point: LatLng(memory.latitude!, memory.longitude!),
                      width: 52,
                      height: 52,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onMarkerTapped(memory),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: memory.mood.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: memory.mood.color.withAlpha(160),
                                blurRadius: 12,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            memory.mood.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  rotate: false,
                ),
            ],
          ),

          if (allMemoriesAsync.isLoading)
            const Center(child: CircularProgressIndicator()),

          if (allMemoriesAsync.hasError)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Material(
                borderRadius: BorderRadius.circular(14),
                color: Colors.red.shade700,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'Error: ${allMemoriesAsync.error}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),

          // Top Header & Filter Chips Bar
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top App Bar Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkSurface : AppColors.deepNavy)
                        .withAlpha(240),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 60 : 20),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brightCyan.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.map_rounded,
                            color: AppColors.brightCyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Memory Map',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.pureWhite,
                              ),
                            ),
                            Text(
                              localized.isEmpty
                                  ? 'No pinned memories yet'
                                  : '${localized.length} memory pin${localized.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.lightCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.my_location_rounded),
                        tooltip: 'Fit all memories',
                        onPressed: () {
                          final loc = allMemories.where((m) => m.hasLocation).toList();
                          _recenterOnMemories(loc);
                        },
                      ),
                    ],
                  ),
                ),

                // Filters Horizontal Scroll
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // All Filter
                      FilterChip(
                        label: const Text('All'),
                        selected: !_onlyFavorites && _filterMood == null,
                        onSelected: (val) {
                          setState(() {
                            _onlyFavorites = false;
                            _filterMood = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),

                      // Favorites Only Filter
                      FilterChip(
                        avatar: const Icon(Icons.favorite_rounded,
                            size: 14, color: AppColors.favorite),
                        label: const Text('Favorites'),
                        selected: _onlyFavorites,
                        onSelected: (val) {
                          setState(() => _onlyFavorites = val);
                        },
                      ),
                      const SizedBox(width: 8),

                      // Mood Filters
                      ...Mood.values.map((mood) {
                        final isSelected = _filterMood == mood;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Text(mood.emoji,
                                style: const TextStyle(fontSize: 12)),
                            label: Text(mood.label),
                            selected: isSelected,
                            selectedColor: mood.getBackgroundColor(isDark),
                            onSelected: (val) {
                              setState(() {
                                _filterMood = val ? mood : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Empty-state banner ────────────────────────────────────────
          if (allMemoriesAsync.hasValue && localized.isEmpty)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : AppColors.deepNavy)
                      .withAlpha(245),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.brightCyan),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No pinned memories. Tap "Pick on Map" when adding a memory to see pins here!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddMemoryScreen(),
                          ),
                        );
                      },
                      child: const Text('Add Now'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
