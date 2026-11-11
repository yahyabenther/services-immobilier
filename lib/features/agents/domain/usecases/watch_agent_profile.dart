import '../entities/agent_profile.dart';
import '../repositories/agent_repository.dart';

class WatchAgentProfile {
  const WatchAgentProfile(this._repo);
  final AgentRepository _repo;

  Stream<AgentProfile?> call(String userId) => _repo.watchProfile(userId);
}
