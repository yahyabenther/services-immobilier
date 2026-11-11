import '../entities/agent_profile.dart';
import '../repositories/agent_repository.dart';

class UpdateAgentProfile {
  const UpdateAgentProfile(this._repo);
  final AgentRepository _repo;

  Future<void> call(AgentProfile profile) => _repo.updateProfile(profile);
}
