class AppConstants {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String googleMapsIosKey = String.fromEnvironment(
    'GOOGLE_MAPS_IOS_API_KEY',
  );
  static const String mapboxPublicToken = String.fromEnvironment('MAPBOX_PUBLIC_TOKEN');

  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  static const String defaultParkName = 'Masai Mara National Reserve';
  static const String rangerRole = 'Ranger';

  static const fallbackParks = [
    {
      'id': '3467cff0-ca7d-4c6c-ad28-2d202f2372ce',
      'name': 'Masai Mara National Reserve',
      'description': 'Famous wildlife reserve in Kenya',
      'location': 'Narok County, Kenya',
    },
    {
      'id': '0dba0933-f39f-4c78-a943-45584f383d20',
      'name': 'Nairobi National Park',
      'description': 'Nairobi National Park',
      'location': 'Langata',
    },
    {
      'id': 'dc9b8bdc-7e14-4219-a35a-0ab1fb0a4513',
      'name': 'Meru National Park',
      'description': 'Meru National Park',
      'location': 'Meru',
    },
  ];
}
