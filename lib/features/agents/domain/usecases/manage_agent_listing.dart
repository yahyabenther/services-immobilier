import '../../../properties/domain/entities/property.dart';
import '../repositories/agent_repository.dart';

/// Submit (draft/rejected -> pending_review) and withdraw (-> removed) reuse the
/// shared listing lifecycle. Creation and editing stay in Module 08.
class SubmitAgentListing {
  const SubmitAgentListing(this._repo);
  final AgentRepository _repo;

  Future<void> call(Property listing) => _repo.submitListing(listing);
}

class WithdrawAgentListing {
  const WithdrawAgentListing(this._repo);
  final AgentRepository _repo;

  Future<void> call(Property listing) => _repo.withdrawListing(listing);
}
