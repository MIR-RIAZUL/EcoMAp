class AppConstants {
  static const String appName = 'EchoMap';
  static const String appTagline = 'Your Life as a Memory Map';
  static const String appVersion = '1.0.0';

  // Map configuration
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapPackageUserAgent = 'com.echomap.app';
  static const double defaultLatitude = 48.8566; // Paris (fallback center)
  static const double defaultLongitude = 2.3522;
  static const double defaultZoom = 13.0;

  // Preset suggested tags
  static const List<String> defaultTags = [
    'Travel',
    'Family',
    'Friends',
    'University',
    'Food',
    'Nature',
    'Work',
    'Milestone',
    'Music',
    'Adventure',
  ];
}
