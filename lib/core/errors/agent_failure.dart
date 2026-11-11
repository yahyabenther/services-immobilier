enum AgentFailureType {
  notSignedIn,
  profileNotFound,
  profileAlreadyExists,
  validation,
  saveFailed,
  imageUploadFailed,
  permissionDenied,
  listingsFailed,
  listingNotAllowed,
  verificationUploadFailed,
  verificationNotAllowed,
  network,
  unknown,
}

/// Every failure the Agent module can surface. [message] is the only text a
/// user ever sees: raw Firebase exception messages are never exposed (spec §15.1).
class AgentFailure implements Exception {
  const AgentFailure(this.type, {this.fieldErrors = const {}, this.detail});

  final AgentFailureType type;

  /// Field name -> message, only for [AgentFailureType.validation].
  final Map<String, String> fieldErrors;

  /// Developer-facing hint for the listing / verification guards. Safe to show.
  final String? detail;

  String get message => switch (type) {
        AgentFailureType.notSignedIn => 'Please sign in again.',
        AgentFailureType.profileNotFound => 'Your professional profile could not be found.',
        AgentFailureType.profileAlreadyExists => 'You already have a professional profile.',
        AgentFailureType.validation => 'Please correct the highlighted fields.',
        AgentFailureType.saveFailed => 'We could not save your changes. Please try again.',
        AgentFailureType.imageUploadFailed => 'The image could not be uploaded. Check your connection and retry.',
        AgentFailureType.permissionDenied => 'You are not allowed to perform this action.',
        AgentFailureType.listingsFailed => 'We could not load your listings. Please try again.',
        AgentFailureType.listingNotAllowed => detail ?? 'This action is not available for this listing.',
        AgentFailureType.verificationUploadFailed => 'Your documents were not submitted. Please retry.',
        AgentFailureType.verificationNotAllowed =>
          detail ?? 'A verification request cannot be submitted right now.',
        AgentFailureType.network => 'Network problem. Check your connection and try again.',
        AgentFailureType.unknown => 'Something went wrong. Please try again.',
      };

  @override
  String toString() => 'AgentFailure($type${detail == null ? '' : ', $detail'})';
}
