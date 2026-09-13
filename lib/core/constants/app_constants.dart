class AppConstants {
  static const String appName = 'EchoMap';
  static const String appTagline = 'Your Life as a Memory Map';
  static const String appVersion = '1.0.0';

  // Modern Map configuration (Voyager & Dark Matter)
  static const String mapLightTileUrl = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const String mapDarkTileUrl = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String osmFallbackTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> mapSubdomains = ['a', 'b', 'c', 'd'];
  static const String mapPackageUserAgent = 'com.echomap.app';
  static const double defaultLatitude = 23.7985; // Pleasant default
  static const double defaultLongitude = 90.4497;
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
