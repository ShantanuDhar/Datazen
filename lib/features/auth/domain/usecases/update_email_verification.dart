
import 'package:datazen/core/error/failure.dart';
import 'package:datazen/core/usecase/usecase.dart';
import 'package:datazen/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';


class UpdateEmailVerification implements Usecase<void, NoParams> {
  final AuthRepository repository;
  UpdateEmailVerification(this.repository);
  @override
  Future<Either<Failure,void>> call(NoParams params) {
    return repository.updateEmailVerification();
  }
}


