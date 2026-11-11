import '../entities/agent_profile.dart';
import '../repositories/agent_repository.dart';

class GetAgentProfile {
  const GetAgentProfile(this._repo);
  final AgentRepository _repo;

  Future<AgentProfile?> call(String userId) => _repo.getProfile(userId);
}
