import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/expenses/domain/entities/expense.dart';
import 'package:sales_manager/features/expenses/domain/repositories/expense_repository.dart';
import 'package:sales_manager/features/expenses/domain/usecases/record_expense_usecase.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late MockExpenseRepository mockRepository;
  late RecordExpenseUseCase useCase;

  setUpAll(() {
    registerFallbackValue(Money.zero);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = RecordExpenseUseCase(mockRepository);
  });

  final testDate = DateTime(2026, 3, 10);
  final expectedExpense = Expense(
    id: 1,
    category: 'إيجار',
    amount: Money.fromPounds(500),
    expenseDate: testDate,
    note: 'إيجار شهر مارس',
    createdAt: DateTime(2026, 3, 10, 10, 0),
  );

  test('successfully records expense when valid category and positive amount are provided', () async {
    when(() => mockRepository.recordExpense(
          category: 'إيجار',
          amount: Money.fromPounds(500),
          expenseDate: testDate,
          note: 'إيجار شهر مارس',
          createdBy: 'admin',
        )).thenAnswer((_) async => Success(expectedExpense));

    final result = await useCase(
      category: '  إيجار  ',
      amount: Money.fromPounds(500),
      expenseDate: testDate,
      note: '  إيجار شهر مارس  ',
    );

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull, equals(expectedExpense));
    verify(() => mockRepository.recordExpense(
          category: 'إيجار',
          amount: Money.fromPounds(500),
          expenseDate: testDate,
          note: 'إيجار شهر مارس',
          createdBy: 'admin',
        )).called(1);
  });

  test('returns ValidationFailure when category is empty', () async {
    final result = await useCase(
      category: '   ',
      amount: Money.fromPounds(100),
      expenseDate: testDate,
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect((result.failureOrNull as ValidationFailure).field, equals('category'));
    verifyNever(() => mockRepository.recordExpense(
          category: any(named: 'category'),
          amount: any(named: 'amount'),
          expenseDate: any(named: 'expenseDate'),
        ));
  });

  test('returns ValidationFailure when amount is zero or negative', () async {
    final resultZero = await useCase(
      category: 'كهرباء',
      amount: Money.zero,
      expenseDate: testDate,
    );

    expect(resultZero.isFailure, isTrue);
    expect(resultZero.failureOrNull, isA<ValidationFailure>());
    expect((resultZero.failureOrNull as ValidationFailure).field, equals('amount'));

    final resultNegative = await useCase(
      category: 'كهرباء',
      amount: const Money.fromPiastres(-500),
      expenseDate: testDate,
    );

    expect(resultNegative.isFailure, isTrue);
    expect(resultNegative.failureOrNull, isA<ValidationFailure>());
    expect((resultNegative.failureOrNull as ValidationFailure).field, equals('amount'));

    verifyNever(() => mockRepository.recordExpense(
          category: any(named: 'category'),
          amount: any(named: 'amount'),
          expenseDate: any(named: 'expenseDate'),
        ));
  });
}
