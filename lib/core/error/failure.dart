/// Абстрактный класс для представления ошибок в приложении.
///
/// Используется в Either<Failure, T> для обработки ошибок на уровне Domain.
/// Все конкретные типы ошибок должны наследоваться от этого класса.
abstract class Failure {
  /// Сообщение об ошибке, понятное пользователю
  final String message;

  /// Конструктор
  const Failure(this.message);
}

/// Ошибки, связанные с сетевыми запросами
/// (отсутствие интернета, таймауты, ошибки DNS и т.д.)
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Ошибки, связанные с сервером
/// (HTTP 5xx, ошибки валидации на сервере, внутренние ошибки и т.д.)
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Ошибки, связанные с валидацией данных
/// (некорректные входные данные, нарушение бизнес-правил и т.д.)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Ошибки, связанные с отсутствием запрашиваемого ресурса
/// (не найден объект, запись, файл и т.д.)
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
