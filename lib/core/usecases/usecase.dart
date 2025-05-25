import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/failures.dart';

// Type: The return type of the use case (e.g., an Entity or void)
// Params: The parameters required by the use case (can be a custom class or void)
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Use this if the use case does not require any parameters
class NoParams {}
