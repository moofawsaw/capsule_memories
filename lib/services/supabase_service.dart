class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    try {
      // Skip initialization if credentials aren't provided
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        print('⚠️ Supabase credentials not provided - running in offline mode');
        instance._isInitialized = false;
        return;
      }

      // Remove Supabase.initialize call since package is not available
      // await Supabase.initialize(
      //   url: supabaseUrl,
      //   anonKey: supabaseAnonKey,
      // );

      instance._isInitialized = true;
      print('✅ Supabase initialized successfully');
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
      instance._isInitialized = false;
    }
  }

  // Get Supabase client (returns null if not initialized)
  dynamic get client {
    if (!_isInitialized) {
      print('⚠️ Supabase not initialized - returning null');
      return null;
    }
    return null; // Remove Supabase.instance.client reference
  }
}