import 'dart:async';
import 'package:dartz/dartz.dart';
import '../entities/property.dart';
import '../../../../core/error/failure.dart';

/// Абстрактный интерфейс репозитория для работы с Property
///
/// Определяет контракты для операций с недвижимостью.
/// Реализации находятся в слое Data.
abstract class PropertyRepository {
  /// Получает список свойств (properties) с пагинацией и фильтрацией
  ///
  /// [page] - номер страницы (начиная с 1)
  /// [limit] - количество элементов на странице
  /// [query] - опциональный поисковый запрос (по заголовку)
  /// [city] - опциональный фильтр по городу
  ///
  /// Возвращает Either<Failure, List<Property>>:
  /// - Left(Failure) в случае ошибки
  /// - Right(List<Property>) в случае успеха
  Future<Either<Failure, List<Property>>> getProperties({
    required int page,
    required int limit,
    String? query,
    String? city,
  });

  /// Получает свойство по идентификатору
  ///
  /// [id] уникальный идентификатор недвижимости
  ///
  /// Возвращает Either<Failure, Property>:
  /// - Left(Failure) в случае ошибки или если свойство не найдено
  /// - Right(Property) в случае успеха
  Future<Either<Failure, Property>> getPropertyById(String id);
}
