import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String locationName;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });
}

class LocationService {
  /// Fetches the user's current GPS location and automatically reverse-geocodes
  /// it to a human-readable place name.
  ///
  /// Returns `null` if permission is permanently denied or service is off.
  /// Call [openAppSettings] / [openLocationSettings] to guide the user.
  static Future<LocationResult?> getCurrentLocation({bool promptSettings = false}) async {
    try {
      // ── 1. Check if location service is enabled ──────────────────────────
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (promptSettings) {
          await Geolocator.openLocationSettings();
        }
        return null;
      }

      // ── 2. Request permission ────────────────────────────────────────────
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (promptSettings) {
          await Geolocator.openAppSettings();
        }
        return null;
      }

      // ── 3. Get current position ──────────────────────────────────────────
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );

        final String placeName =
            await getPlaceName(position.latitude, position.longitude);

        return LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          locationName: placeName,
        );
      } catch (_) {
        // Fallback: use last known position if current times out
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          final String placeName =
              await getPlaceName(lastKnown.latitude, lastKnown.longitude);
          return LocationResult(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
            locationName: placeName,
          );
        }
        return null;
      }
    } catch (_) {
      // Return null gracefully if plugin or hardware unavailable
      return null;
    }
  }

  /// Converts latitude and longitude to a user-friendly location name.
  static Future<String> getPlaceName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];

        if (place.name != null &&
            place.name!.isNotEmpty &&
            place.name != place.street &&
            place.name != place.subLocality) {
          parts.add(place.name!);
        } else if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          parts.add(place.subAdministrativeArea!);
        }

        if (place.country != null && place.country!.isNotEmpty) {
          parts.add(place.country!);
        }

        if (parts.isNotEmpty) {
          // Keep it concise — e.g. "Badda, Dhaka, Bangladesh"
          return parts.take(3).join(', ');
        }
      }
    } catch (_) {
      // Fallback if reverse geocoding is offline or rate-limited.
    }

    return 'Spot (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})';
  }
}
