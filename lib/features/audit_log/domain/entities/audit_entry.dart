import 'package:equatable/equatable.dart';

/// Pure domain entity representing an audit log entry.
/// Independent of any database or presentation framework.
class AuditEntry extends Equatable {
  final int id;
  final String entityType;
  final int entityId;
  final String action;
  final String? payloadBefore;
  final String? payloadAfter;
  final DateTime performedAt;
  final String? note;
  final String userId;

  const AuditEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.payloadBefore,
    this.payloadAfter,
    required this.performedAt,
    this.note,
    required this.userId,
  });

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        action,
        payloadBefore,
        payloadAfter,
        performedAt,
        note,
        userId,
      ];
}
