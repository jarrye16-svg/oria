class SupabaseRuntimeConfig {
  final String url;
  final String anonKey;

  const SupabaseRuntimeConfig({
    required this.url,
    required this.anonKey,
  });

  const SupabaseRuntimeConfig.fromEnvironment()
      : url = const String.fromEnvironment('SUPABASE_URL'),
        anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  bool get isMissing => url.trim().isEmpty || anonKey.trim().isEmpty;
}
