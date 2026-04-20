import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';

class SignInAnonymouslyUseCase {
  SignInAnonymouslyUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserCredential> call() {
    return _repository.signInAnonymously();
  }
}
