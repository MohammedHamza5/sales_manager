import 'package:equatable/equatable.dart';

class AppVersion extends Equatable {
  final String version;
  final String platform;
  final String downloadUrl;
  final String? releaseNotes;
  final bool isRequired;
  final DateTime? createdAt;

  const AppVersion({
    required this.version,
    required this.platform,
    required this.downloadUrl,
    this.releaseNotes,
    this.isRequired = false,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        version,
        platform,
        downloadUrl,
        releaseNotes,
        isRequired,
        createdAt,
      ];
}
