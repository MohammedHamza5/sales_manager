import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../models/app_version_model.dart';

abstract class UpdateRemoteDataSource {
  Future<AppVersionModel?> getLatestVersion(List<String> platforms);
}

class UpdateRemoteDataSourceImpl implements UpdateRemoteDataSource {
  final SupabaseClient? _client;

  UpdateRemoteDataSourceImpl([this._client]);

  SupabaseClient get _supabase => _client ?? SupabaseConfig.client;

  @override
  Future<AppVersionModel?> getLatestVersion(List<String> platforms) async {
    try {
      final response = await _supabase
          .from('app_versions')
          .select()
          .filter('platform', 'in', platforms)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (response == null) return null;
      return AppVersionModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching latest version from Supabase: $e');
      return null;
    }
  }
}
