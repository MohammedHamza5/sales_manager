import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://xxhqzdeymxrekeizzbws.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4aHF6ZGV5bXhyZWtlaXp6YndzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzNjc0NTMsImV4cCI6MjEwNTk0MzQ1M30.fvoHlVhYy4UnyeVTeO5EubBDtUdxk6CFD23f--7F1e0';

  static SupabaseClient? _fallbackClient;

  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return _fallbackClient ??= SupabaseClient(url, anonKey);
    }
  }

  static Future<void> initialize() async {
    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: false,
      );
    } catch (e) {
      _fallbackClient ??= SupabaseClient(url, anonKey);
    }
  }
}
