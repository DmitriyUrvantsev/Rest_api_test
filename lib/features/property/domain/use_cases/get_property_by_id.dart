import 'package:dartz/dartz.dart';
import '../entities/property.dart';
import '../repositories/property_repository.dart';
import '../../../../core/error/failure.dart';

/// Use Case для получения свойства (property) по идентификатору
///
/// Инкапсулирует бизнес-логику получения одной недвижимости по ID.
/// Не зависит от конкретной реализации репозитория.
class GetPropertyById {
  final PropertyRepository repository;

  const GetPropertyById(this.repository);

  /// Выполняет получение свойства по ID
  ///
  /// [id] уникальный идентификатор недвижимости
  ///
  /// Возвращает Either<Failure, Property>:
  /// - Left(Failure) в случае ошибки или если свойство не найдено
  /// - Right(Property) в случае успеха
  Future<Either<Failure, Property>> call(String id) {
    return repository.getPropertyById(id);
  }
}
