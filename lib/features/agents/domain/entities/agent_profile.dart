import '../../../properties/domain/entities/property.dart';

/// An individual professional or a (single-account) agency. Team support is a
/// future feature (spec §1.3), so an agency is just a profile with
/// [kind] == [AgentProfileKind.agency] and an [agencyName].
enum AgentProfileKind {
  agent,
  agency;

  String get wire => name;

  static AgentProfileKind parse(String? v) =>
      v == 'agency' ? AgentProfileKind.agency : AgentProfileKind.agent;
}

/// Public professional profile: `agent_profiles/{userId}` (spec §6.1).
/// Holds ONLY public data. No documents, no private account fields.
class AgentProfile {
  const AgentProfile({
    required this.userId,
    required this.professionalName,
    required this.description,
    required this.phone,
    required this.publicEmail,
    required this.city,
    this.kind = AgentProfileKind.agent,
    this.agencyName,
    this.agencyId,
    this.profileImageUrl,
    this.address,
    this.website,
    this.yearsOfExperience,
    this.languages = const [],
    this.serviceAreas = const [],
    this.verificationStatus = VerificationStatus.notSubmitted,
    this.showPhone = true,
    this.showEmail = true,
    this.isPublic = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Firebase Auth uid; also the Firestore document id.
  final String userId;
  final String professionalName;
  final String description;
  final String phone;
  final String publicEmail;

  /// Governorate / business location (one of `tunisiaGovernorates`).
  final String city;
  final AgentProfileKind kind;

  /// Required when [kind] is [AgentProfileKind.agency].
  final String? agencyName;

  /// Reserved for the future agency collection; never grants access by itself.
  final String? agencyId;
  final String? profileImageUrl;
  final String? address;
  final String? website;
  final int? yearsOfExperience;
  final List<String> languages;
  final List<String> serviceAreas;

  /// Written by trusted backend code only (spec §12 requirement 5).
  final VerificationStatus verificationStatus;

  /// Privacy settings for the public page (spec FR-03).
  final bool showPhone;
  final bool showEmail;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAgency => kind == AgentProfileKind.agency;
  bool get isVerified => verificationStatus == VerificationStatus.approved;

  /// Name shown to the public: the agency name for agency profiles.
  String get displayName =>
      isAgency && (agencyName?.trim().isNotEmpty ?? false) ? agencyName!.trim() : professionalName;

  /// Value Module 08 must copy onto `properties.ownerRole`.
  String get ownerRole => isAgency ? 'agency' : 'agent';

  AgentProfile copyWith({
    String? professionalName,
    String? description,
    String? phone,
    String? publicEmail,
    String? city,
    AgentProfileKind? kind,
    String? agencyName,
    bool clearAgencyName = false,
    String? profileImageUrl,
    String? address,
    bool clearAddress = false,
    String? website,
    bool clearWebsite = false,
    int? yearsOfExperience,
    bool clearYears = false,
    List<String>? languages,
    List<String>? serviceAreas,
    bool? showPhone,
    bool? showEmail,
    bool? isPublic,
  }) =>
      AgentProfile(
        userId: userId,
        professionalName: professionalName ?? this.professionalName,
        description: description ?? this.description,
        phone: phone ?? this.phone,
        publicEmail: publicEmail ?? this.publicEmail,
        city: city ?? this.city,
        kind: kind ?? this.kind,
        agencyName: clearAgencyName ? null : (agencyName ?? this.agencyName),
        agencyId: agencyId,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        address: clearAddress ? null : (address ?? this.address),
        website: clearWebsite ? null : (website ?? this.website),
        yearsOfExperience: clearYears ? null : (yearsOfExperience ?? this.yearsOfExperience),
        languages: languages ?? this.languages,
        serviceAreas: serviceAreas ?? this.serviceAreas,
        verificationStatus: verificationStatus,
        showPhone: showPhone ?? this.showPhone,
        showEmail: showEmail ?? this.showEmail,
        isPublic: isPublic ?? this.isPublic,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
