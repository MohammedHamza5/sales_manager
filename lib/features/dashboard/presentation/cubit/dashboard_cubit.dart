import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/usecases/get_dashboard_data_usecase.dart';
import '../../domain/usecases/watch_dashboard_data_usecase.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final WatchDashboardDataUseCase _watchDashboardData;
  final GetDashboardDataUseCase _getDashboardData;
  StreamSubscription<DashboardData>? _subscription;

  DashboardCubit({
    required WatchDashboardDataUseCase watchDashboardData,
    required GetDashboardDataUseCase getDashboardData,
  })  : _watchDashboardData = watchDashboardData,
        _getDashboardData = getDashboardData,
        super(const DashboardInitial());

  void init() {
    emit(const DashboardLoading());
    _subscription?.cancel();
    _subscription = _watchDashboardData().listen(
      (data) {
        emit(DashboardLoaded(data));
      },
      onError: (Object error) {
        emit(DashboardError('فشل في جلب التحديثات الحية: $error'));
      },
    );
  }

  Future<void> refresh() async {
    emit(const DashboardLoading());
    final result = await _getDashboardData();
    switch (result) {
      case Success(:final data):
        emit(DashboardLoaded(data));
      case FailureResult(:final failure):
        emit(DashboardError(failure.message));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
