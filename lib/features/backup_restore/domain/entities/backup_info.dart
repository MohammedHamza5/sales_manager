import 'package:equatable/equatable.dart';

class BackupInfo extends Equatable {
  final int id;
  final String filePath;
  final DateTime createdAt;
  final int sizeBytes;
  final String type;
  final int schemaVersion;

  const BackupInfo({
    required this.id,
    required this.filePath,
    required this.createdAt,
    required this.sizeBytes,
    required this.type,
    required this.schemaVersion,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  List<Object?> get props => [
        id,
        filePath,
        createdAt,
        sizeBytes,
        type,
        schemaVersion,
      ];
}
