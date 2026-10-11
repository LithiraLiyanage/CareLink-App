/// Whether an elder has granted family sharing.
///
/// [notRecorded] is the safe default: no consent is assumed unless a source
/// explicitly records it.
enum ConsentSharingStatus {
  approved('Approved'),
  notRecorded('Not recorded'),
  withdrawn('Withdrawn');

  const ConsentSharingStatus(this.label);

  final String label;
}

/// Where a consent context came from, so mock data is never mistaken for real.
enum ConsentContextSource { mock, firestore }

/// A person the elder approved to be contacted during follow-up.
class ApprovedContact {
  final String id;
  final String name;
  final String relationship;

  const ApprovedContact({
    required this.id,
    required this.name,
    required this.relationship,
  });

  /// e.g. "Jane Silva (Daughter)".
  String get displayLabel => '$name ($relationship)';
}

/// Consent and sharing context a coordinator reviews before contacting anyone.
class ElderConsentContext {
  final String elderId;
  final ConsentSharingStatus familySharing;
  final ApprovedContact? approvedContact;
  final DateTime? validFrom;
  final DateTime? lastUpdatedAt;
  final List<String> allowedInformation;
  final List<String> restrictedInformation;
  final ConsentContextSource source;

  const ElderConsentContext({
    required this.elderId,
    required this.familySharing,
    this.approvedContact,
    this.validFrom,
    this.lastUpdatedAt,
    this.allowedInformation = const [],
    this.restrictedInformation = const [],
    required this.source,
  });

  /// A context with nothing granted, for elders with no recorded consent.
  const ElderConsentContext.notRecorded({
    required this.elderId,
    required this.source,
  }) : familySharing = ConsentSharingStatus.notRecorded,
       approvedContact = null,
       validFrom = null,
       lastUpdatedAt = null,
       allowedInformation = const [],
       restrictedInformation = const [];

  bool get isMock => source == ConsentContextSource.mock;

  bool get canContactApprovedPerson =>
      familySharing == ConsentSharingStatus.approved && approvedContact != null;
}
