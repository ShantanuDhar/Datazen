
import 'package:datazen/core/entities/user_entity.dart';
import 'package:datazen/core/error/failure.dart';
import 'package:datazen/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

import 'usecase.dart';

class CurrentUser implements Usecase<User,NoParams>{
  final AuthRepository repository;

  CurrentUser(this.repository);

  @override
  Future<Either<Failure,User>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}