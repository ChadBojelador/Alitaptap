import '../../domain/repositories/auth_repository.dart';

class SignInAnonymouslyUseCase {
  SignInAnonymouslyUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({required String email, required String password}) =>
      _repository.signIn(email: email, password: password);
}
