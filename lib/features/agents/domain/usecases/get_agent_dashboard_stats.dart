import '../entities/agent_dashboard_stats.dart';
import '../repositories/agent_repository.dart';

class GetAgentDashboardStats {
  const GetAgentDashboardStats(this._repo);
  final AgentRepository _repo;

  Future<AgentDashboardStats> call(String agentId) => _repo.getDashboardStats(agentId);
}
