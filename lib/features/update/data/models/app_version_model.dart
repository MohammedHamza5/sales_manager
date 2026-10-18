import '../../domain/entities/app_version.dart';

class AppVersionModel extends AppVersion {
  const AppVersionModel({
    required super.version,
    required super.platform,
    required super.downloadUrl,
    super.releaseNotes,
    super.isRequired,
    super.createdAt,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      version: (json['version'] as String?)?.trim() ?? '',
      platform: (json['platform'] as String?)?.trim() ?? '',
      downloadUrl: (json['download_url'] as String?)?.trim() ?? '',
      releaseNotes: json['release_notes'] as String?,
      isRequired: json['is_required'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'platform': platform,
      'download_url': downloadUrl,
      'release_notes': releaseNotes,
      'is_required': isRequired,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
