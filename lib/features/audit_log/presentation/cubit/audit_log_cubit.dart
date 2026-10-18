import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_audit_logs_usecase.dart';
import 'audit_log_state.dart';

class AuditLogCubit extends Cubit<AuditLogState> {
  final GetAuditLogsUseCase _getAuditLogsUseCase;

  String _currentEntityType = 'all';
  String _currentAction = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;

  AuditLogCubit({
    required GetAuditLogsUseCase getAuditLogsUseCase,
  })  : _getAuditLogsUseCase = getAuditLogsUseCase,
        super(const AuditLogInitial());

  Future<void> loadAuditLogs({
    String? entityType,
    String? action,
    DateTime? from,
    DateTime? to,
  }) async {
    _currentEntityType = entityType ?? _currentEntityType;
    _currentAction = action ?? _currentAction;
    _fromDate = from ?? _fromDate;
    _toDate = to ?? _toDate;

    emit(const AuditLogLoading());

    final result = await _getAuditLogsUseCase(
      entityType: _currentEntityType == 'all' ? null : _currentEntityType,
      action: _currentAction == 'all' ? null : _currentAction,
      from: _fromDate,
      to: _toDate,
      limit: 150,
    );

    result.fold(
      onSuccess: (entries) {
        if (entries.isEmpty) {
          emit(const AuditLogEmpty(message: 'لا توجد سجلات مطابقة لمعايير البحث الحالية'));
        } else {
          emit(
            AuditLogLoaded(
              entries: entries,
              selectedEntityType: _currentEntityType,
              selectedAction: _currentAction,
              fromDate: _fromDate,
              toDate: _toDate,
            ),
          );
        }
      },
      onFailure: (failure) {
        emit(AuditLogError(message: failure.message));
      },
    );
  }

  void filterByEntityType(String entityType) {
    loadAuditLogs(entityType: entityType);
  }

  void filterByAction(String action) {
    loadAuditLogs(action: action);
  }

  void filterByDateRange(DateTime? from, DateTime? to) {
    _fromDate = from;
    _toDate = to;
    loadAuditLogs(from: from, to: to);
  }

  void clearFilters() {
    _currentEntityType = 'all';
    _currentAction = 'all';
    _fromDate = null;
    _toDate = null;
    loadAuditLogs(
      entityType: 'all',
      action: 'all',
      from: null,
      to: null,
    );
  }
}
