import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

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
  late MapController _mapController;
  late LatLng _selectedPosition;
  late TextEditingController _nameController;

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
    _mapController = MapController();
    _selectedPosition = LatLng(
      widget.initialLatitude ?? AppConstants.defaultLatitude,
      widget.initialLongitude ?? AppConstants.defaultLongitude,
    );
    _nameController =
        TextEditingController(text: widget.initialLocationName ?? '');
  }

  @override
  void dispose() {
    _mapController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedPosition = position;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text =
            'Spot at ${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
      }
    });
  }

  void _selectQuickLocation(Map<String, dynamic> loc) {
    final pos = LatLng(loc['lat'] as double, loc['lng'] as double);
    setState(() {
      _selectedPosition = pos;
      _nameController.text = loc['name'] as String;
    });
    _mapController.move(pos, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
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
                    color: AppColors.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pin_drop_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pick Memory Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // Quick City Presets
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickLocations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final loc = _quickLocations[index];
                return ActionChip(
                  avatar: const Icon(Icons.location_city_rounded, size: 14),
                  label: Text(
                    loc['name'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _selectQuickLocation(loc),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Map view
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedPosition,
                      initialZoom: 13.0,
                      onTap: _onMapTapped,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: AppConstants.osmTileUrl,
                        userAgentPackageName: AppConstants.mapPackageUserAgent,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPosition,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 46,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Hint banner at top
                  Positioned(
                    top: 10,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white)
                            .withAlpha(210),
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
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap anywhere on map to drop pin',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          final name = _nameController.text.trim().isNotEmpty
                              ? _nameController.text.trim()
                              : 'Lat: ${_selectedPosition.latitude.toStringAsFixed(4)}, Lng: ${_selectedPosition.longitude.toStringAsFixed(4)}';
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
    );
  }
}
