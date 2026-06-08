import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Test Supabase upsert', () async {
    final supabase = SupabaseClient(
      'https://zzasqztvviakcggfxoud.supabase.co',
      'sb_publishable_1y-Kc1xApkNhecC4XGNBcw_9pCD-lBl',
    );

    try {
      print('Testing upsert...');
      final res = await supabase.from('preferences').upsert({
        'entreprise': 'a1337c0c-60de-44b7-84a2-9111812a1f26',
        'favori': true,
      }, onConflict: 'entreprise').select();
      print('Upsert success: $res');
    } catch (e) {
      print('Upsert failed: $e');
    }
  });
}
