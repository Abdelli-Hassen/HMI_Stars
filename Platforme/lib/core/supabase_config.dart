import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://zzasqztvviakcggfxoud.supabase.co';
  static const String anonKey = 'sb_publishable_1y-Kc1xApkNhecC4XGNBcw_9pCD-lBl';
  
  // Clé d'administration (permet de bypasser la vérification email et RLS)
  static const String serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6YXNxenR2dmlha2NnZ2Z4b3VkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODQ1NjUwNiwiZXhwIjoyMDk0MDMyNTA2fQ.cm3KLnJjgWj6BbTlqrRLlJLdKuS6HOKKsbIw8X5MuEY';

  static SupabaseClient? _adminClient;

  static SupabaseClient get client => Supabase.instance.client;
  
  // Specialized client for admin tasks (bypasses RLS, creates users without email verification)
  static SupabaseClient get adminClient {
    _adminClient ??= SupabaseClient(url, serviceRoleKey);
    return _adminClient!;
  }
}
