import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/location_service.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String locationName;

  LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });
}

class LocationPickerSheet extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;

  const LocationPickerSheet({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
  });

  static Future<LocationPickerResult?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    String? initialLocationName,
  }) {
    return showModalBottomSheet<LocationPickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      builder: (context) => LocationPickerSheet(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
        initialLocationName: initialLocationName,
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  late LatLng _selectedPosition;
  late TextEditingController _nameController;
  bool _isLoadingGps = false;

  final List<Map<String, dynamic>> _quickLocations = [
    {'name': 'Paris, France', 'lat': 48.8566, 'lng': 2.3522},
    {'name': 'New York, USA', 'lat': 40.7128, 'lng': -74.0060},
    {'name': 'Tokyo, Japan', 'lat': 35.6762, 'lng': 139.6503},
    {'name': 'Dhaka, Bangladesh', 'lat': 23.8103, 'lng': 90.4125},
    {'name': 'London, UK', 'lat': 51.5074, 'lng': -0.1278},
    {'name': 'Sydney, Australia', 'lat': -33.8688, 'lng': 151.2093},
  ];

  @override
  void initState() {
    super.initState();
    _selectedPosition = LatLng(
      widget.initialLatitude ?? AppConstants.defaultLatitude,
      widget.initialLongitude ?? AppConstants.defaultLongitude,
    );
    _nameController =
        TextEditingController(text: widget.initialLocationName ?? '');

    // Auto-detect GPS only when no starting position provided.
    // Must wait for map to be ready (onMapReady) before calling move().
    if (widget.initialLatitude == null || widget.initialLongitude == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _detectCurrentLocation(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation({bool silent = false}) async {
    setState(() => _isLoadingGps = true);

    try {
      final result = await LocationService.getCurrentLocation(promptSettings: !silent);

      if (!mounted) return;

      if (result != null) {
        final pos = LatLng(result.latitude, result.longitude);
        setState(() {
          _selectedPosition = pos;
          _nameController.text = result.locationName;
        });
        if (_mapReady) _mapController.move(pos, 15.0);
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not acquire GPS position. Please check location permissions and GPS settings.',
            ),
            backgroundColor: AppColors.favorite,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Unable to access location services right now.',
            ),
            backgroundColor: AppColors.favorite,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingGps = false);
      }
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng position) async {
    setState(() {
      _selectedPosition = position;
    });

    // Auto reverse geocode on tap with safe fallback
    try {
      final place = await LocationService.getPlaceName(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _nameController.text = place;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nameController.text =
            'Spot (${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)})';
      });
    }
  }

  void _selectQuickLocation(Map<String, dynamic> loc) {
    final pos = LatLng(loc['lat'] as double, loc['lng'] as double);
    setState(() {
      _selectedPosition = pos;
      _nameController.text = loc['name'] as String;
    });
    if (_mapReady) _mapController.move(pos, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTextStyle.merge(
      style: const TextStyle(color: AppColors.pureWhite),
      child: IconTheme(
        data: const IconThemeData(color: AppColors.brightCyan),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.deepNavy,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightCyan.withAlpha(90),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brightCyan.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pin_drop_rounded,
                    color: AppColors.brightCyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Memory Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tap map or use one-tap auto GPS',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.lightCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // One-Tap "Detect Current Location" Automated Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _isLoadingGps ? null : () => _detectCurrentLocation(),
                    icon: _isLoadingGps
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(
                      _isLoadingGps ? 'Locating GPS...' : 'Use My Current Location',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick City Presets
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickLocations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final loc = _quickLocations[index];
                return ActionChip(
                  avatar: const Icon(Icons.location_city_rounded, size: 13),
                  label: Text(
                    loc['name'] as String,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => _selectQuickLocation(loc),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Modern Map Canvas
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedPosition,
                      initialZoom: 14.0,
                      onTap: _onMapTapped,
                      onMapReady: () => setState(() => _mapReady = true),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                        enableMultiFingerGestureRace: true,
                      ),
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
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPosition,
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulsing halo circle
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(40),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.place_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating GPS Re-center button on map
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: FloatingActionButton.small(
                      heroTag: 'picker_gps_fab',
                      backgroundColor:
                          isDark ? AppColors.darkSurface : AppColors.navyBlue,
                      foregroundColor: AppColors.brightCyan,
                      onPressed: () => _detectCurrentLocation(),
                      tooltip: 'Snap to current location',
                      child: const Icon(Icons.gps_fixed_rounded, size: 20),
                    ),
                  ),

                  // Tap anywhere hint banner
                  Positioned(
                    top: 10,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkNavy : AppColors.deepNavy)
                            .withAlpha(230),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.touch_app_rounded,
                            size: 16, color: AppColors.brightCyan),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap anywhere to reposition pin with auto place name',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Location Name Input and Confirm Button
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Location Name',
                    hintText: 'e.g. United International University',
                    prefixIcon: const Icon(Icons.edit_location_alt_rounded),
                    suffixIcon: _nameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setState(() => _nameController.clear()),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          final name = _nameController.text.trim().isNotEmpty
                              ? _nameController.text.trim()
                              : 'Location at ${_selectedPosition.latitude.toStringAsFixed(3)}, ${_selectedPosition.longitude.toStringAsFixed(3)}';
                          Navigator.of(context).pop(
                            LocationPickerResult(
                              latitude: _selectedPosition.latitude,
                              longitude: _selectedPosition.longitude,
                              locationName: name,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Confirm Location'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
