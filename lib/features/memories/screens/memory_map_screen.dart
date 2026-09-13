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
  late MapController _mapController;
  bool _onlyFavorites = false;
  Mood? _filterMood;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

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

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allMemoriesAsync = ref.watch(allMemoriesStreamProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Map Canvas
          allMemoriesAsync.when(
            data: (allMemories) {
              var localized = allMemories.where((m) => m.hasLocation).toList();

              if (_onlyFavorites) {
                localized = localized.where((m) => m.isFavorite).toList();
              }

              if (_filterMood != null) {
                localized = localized.where((m) => m.mood == _filterMood).toList();
              }

              final markers = localized.map((memory) {
                return Marker(
                  point: LatLng(memory.latitude!, memory.longitude!),
                  width: 48,
                  height: 48,
                  child: GestureDetector(
                    onTap: () => _onMarkerTapped(memory),
                    child: Container(
                      decoration: BoxDecoration(
                        color: memory.mood.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: memory.mood.color.withAlpha(140),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
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
              }).toList();

              final initialCenter = localized.isNotEmpty
                  ? LatLng(localized.first.latitude!, localized.first.longitude!)
                  : const LatLng(
                      AppConstants.defaultLatitude, AppConstants.defaultLongitude);

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: localized.isNotEmpty ? 13.0 : 4.0,
                ),
                children: [
                  TileLayer(
                    // Use appropriate tile URL based on theme (light/dark) and provide subdomains.
                    urlTemplate: isDark ? AppConstants.mapDarkTileUrl : AppConstants.mapLightTileUrl,
                    subdomains: AppConstants.mapSubdomains,
                    userAgentPackageName: AppConstants.mapPackageUserAgent,
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Map Error: $e')),
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
                    color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                        .withAlpha(235),
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
                          color: AppColors.primary.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.map_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Memory Map',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Explore moments across the globe',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Recenter button
                      IconButton(
                        icon: const Icon(Icons.my_location_rounded),
                        tooltip: 'Fit all memories',
                        onPressed: () {
                          final all = allMemoriesAsync.value ?? [];
                          final loc = all.where((m) => m.hasLocation).toList();
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

          // No memories with location notice
          allMemoriesAsync.maybeWhen(
            data: (memories) {
              final localized = memories.where((m) => m.hasLocation).toList();
              if (localized.isEmpty) {
                return Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                          .withAlpha(240),
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
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'No memories with coordinates yet. When adding a memory, tap "Pick on Map" to see pins here!',
                            style: TextStyle(fontSize: 12),
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
                );
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
