import '../entities/agent_profile.dart';
import '../repositories/agent_repository.dart';

/// Creates the caller's professional profile. It starts `not_submitted`:
/// creating a profile never makes it verified (spec §4.1).
class CreateAgentProfile {
  const CreateAgentProfile(this._repo);
  final AgentRepository _repo;

  Future<void> call(AgentProfile profile) => _repo.createProfile(profile);
}
