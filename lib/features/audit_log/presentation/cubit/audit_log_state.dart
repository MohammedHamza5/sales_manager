import 'package:equatable/equatable.dart';
import '../../domain/entities/audit_entry.dart';

sealed class AuditLogState extends Equatable {
  const AuditLogState();

  @override
  List<Object?> get props => [];
}

final class AuditLogInitial extends AuditLogState {
  const AuditLogInitial();
}

final class AuditLogLoading extends AuditLogState {
  const AuditLogLoading();
}

final class AuditLogEmpty extends AuditLogState {
  final String message;
  const AuditLogEmpty({required this.message});

  @override
  List<Object?> get props => [message];
}

final class AuditLogError extends AuditLogState {
  final String message;
  const AuditLogError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class AuditLogLoaded extends AuditLogState {
  final List<AuditEntry> entries;
  final String selectedEntityType;
  final String selectedAction;
  final DateTime? fromDate;
  final DateTime? toDate;

  const AuditLogLoaded({
    required this.entries,
    this.selectedEntityType = 'all',
    this.selectedAction = 'all',
    this.fromDate,
    this.toDate,
  });

  AuditLogLoaded copyWith({
    List<AuditEntry>? entries,
    String? selectedEntityType,
    String? selectedAction,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearDates = false,
  }) {
    return AuditLogLoaded(
      entries: entries ?? this.entries,
      selectedEntityType: selectedEntityType ?? this.selectedEntityType,
      selectedAction: selectedAction ?? this.selectedAction,
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
    );
  }

  @override
  List<Object?> get props => [
        entries,
        selectedEntityType,
        selectedAction,
        fromDate,
        toDate,
      ];
}
