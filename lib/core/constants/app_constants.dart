class AppConstants {
  static const String appName = 'EchoMap';
  static const String appTagline = 'Your Life as a Memory Map';
  static const String appVersion = '1.0.0';

  // Standard OpenStreetMap configuration (100% free, no API key required)
  static const String mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapPackageUserAgent = 'com.echomap.app.echomap';
  static const double defaultLatitude = 23.7985; // Pleasant default
  static const double defaultLongitude = 90.4497;
  static const double defaultZoom = 13.0;

  // Clean dark mode color filter matrix for OpenStreetMap tiles
  static const List<double> darkMapMatrix = <double>[
    -0.85, 0, 0, 0, 230,
    0, -0.85, 0, 0, 230,
    0, 0, -0.85, 0, 230,
    0, 0, 0, 1, 0,
  ];

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
