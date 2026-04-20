import '../../../../core/models/app_role.dart';
import '../../domain/repositories/auth_repository.dart';

class GetCurrentUserRoleUseCase {
  GetCurrentUserRoleUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppRole> call() {
    return _repository.getCurrentUserRole();
  }
}
