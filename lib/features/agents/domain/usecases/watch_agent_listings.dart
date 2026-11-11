import '../../../properties/domain/entities/property.dart';
import '../repositories/agent_repository.dart';

class WatchAgentListings {
  const WatchAgentListings(this._repo);
  final AgentRepository _repo;

  Stream<List<Property>> call(String agentId, {int limit = 100}) => _repo.watchAgentListings(agentId, limit: limit);
}
