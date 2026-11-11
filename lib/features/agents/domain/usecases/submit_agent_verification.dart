import '../entities/agent_profile.dart';
import '../entities/verification_upload.dart';
import '../repositories/agent_repository.dart';

/// Uploads the documents to PRIVATE storage and opens a `pending` request.
/// The decision belongs to administrators (trusted backend), never to this call.
class SubmitAgentVerification {
  const SubmitAgentVerification(this._repo);
  final AgentRepository _repo;

  Future<void> call({required AgentProfile profile, required List<VerificationUpload> documents}) =>
      _repo.submitVerification(profile: profile, documents: documents);
}
