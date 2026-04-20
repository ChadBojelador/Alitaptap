import '../../domain/repositories/auth_repository.dart';

class SetRoleUseCase {
  SetRoleUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String role) {
    return _repository.setRole(role);
  }
}
