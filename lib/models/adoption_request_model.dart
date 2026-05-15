import 'package:cloud_firestore/cloud_firestore.dart';

class AdoptionRequest {
  final String id;
  final String childId;
  final String childName;
  final String familyId;
  final String familyName;
  final String familyEmail;
  final String familyPhone;
  final String orphanageId;
  final String orphanageName;
  final String reasonForAdoption;
  final String backgroundCheckStatus; // 'not_started', 'in_progress', 'completed', 'failed'
  final String requestStatus; // 'pending_orphanage_approval', 'pending_admin_approval', 'completed', 'rejected_by_orphanage', 'rejected_by_admin'
  final DateTime createdAt;
  final DateTime? orphanageRespondedAt;
  final DateTime? adminReviewedAt;
  final String? orphanageRejectionReason;

  AdoptionRequest({
    required this.id,
    required this.childId,
    required this.childName,
    required this.familyId,
    required this.familyName,
    required this.familyEmail,
    required this.familyPhone,
    required this.orphanageId,
    required this.orphanageName,
    required this.reasonForAdoption,
    this.backgroundCheckStatus = 'not_started',
    this.requestStatus = 'pending_orphanage_approval',
    required this.createdAt,
    this.orphanageRespondedAt,
    this.adminReviewedAt,
    this.orphanageRejectionReason,
  });

  // Create AdoptionRequest from Firestore document
  factory AdoptionRequest.fromMap(Map<String, dynamic> map) {
    return AdoptionRequest(
      id: map['id'] ?? '',
      childId: map['childId'] ?? '',
      childName: map['childName'] ?? '',
      familyId: map['familyId'] ?? '',
      familyName: map['familyName'] ?? '',
      familyEmail: map['familyEmail'] ?? '',
      familyPhone: map['familyPhone'] ?? '',
      orphanageId: map['orphanageId'] ?? '',
      orphanageName: map['orphanageName'] ?? '',
      reasonForAdoption: map['reasonForAdoption'] ?? '',
      backgroundCheckStatus: map['backgroundCheckStatus'] ?? 'not_started',
      requestStatus: map['requestStatus'] ?? 'pending_orphanage_approval',
      createdAt: _parseDateTime(map['createdAt']),
      orphanageRespondedAt: map['orphanageRespondedAt'] != null
          ? _parseDateTime(map['orphanageRespondedAt'])
          : null,
      adminReviewedAt: map['adminReviewedAt'] != null
          ? _parseDateTime(map['adminReviewedAt'])
          : null,
      orphanageRejectionReason: map['orphanageRejectionReason'],
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Convert AdoptionRequest to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'childName': childName,
      'familyId': familyId,
      'familyName': familyName,
      'familyEmail': familyEmail,
      'familyPhone': familyPhone,
      'orphanageId': orphanageId,
      'orphanageName': orphanageName,
      'reasonForAdoption': reasonForAdoption,
      'backgroundCheckStatus': backgroundCheckStatus,
      'requestStatus': requestStatus,
      'createdAt': createdAt.toIso8601String(),
      'orphanageRespondedAt': orphanageRespondedAt?.toIso8601String(),
      'adminReviewedAt': adminReviewedAt?.toIso8601String(),
      'orphanageRejectionReason': orphanageRejectionReason,
    };
  }

  // Copy with method for updating specific fields
  AdoptionRequest copyWith({
    String? id,
    String? childId,
    String? childName,
    String? familyId,
    String? familyName,
    String? familyEmail,
    String? familyPhone,
    String? orphanageId,
    String? orphanageName,
    String? reasonForAdoption,
    String? backgroundCheckStatus,
    String? requestStatus,
    DateTime? createdAt,
    DateTime? orphanageRespondedAt,
    DateTime? adminReviewedAt,
    String? orphanageRejectionReason,
  }) {
    return AdoptionRequest(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      familyEmail: familyEmail ?? this.familyEmail,
      familyPhone: familyPhone ?? this.familyPhone,
      orphanageId: orphanageId ?? this.orphanageId,
      orphanageName: orphanageName ?? this.orphanageName,
      reasonForAdoption: reasonForAdoption ?? this.reasonForAdoption,
      backgroundCheckStatus: backgroundCheckStatus ?? this.backgroundCheckStatus,
      requestStatus: requestStatus ?? this.requestStatus,
      createdAt: createdAt ?? this.createdAt,
      orphanageRespondedAt: orphanageRespondedAt ?? this.orphanageRespondedAt,
      adminReviewedAt: adminReviewedAt ?? this.adminReviewedAt,
      orphanageRejectionReason: orphanageRejectionReason ?? this.orphanageRejectionReason,
    );
  }

  // Check if request is pending orphanage approval
  bool get isPendingOrphanageApproval => requestStatus == 'pending_orphanage_approval';

  // Check if request is pending admin approval
  bool get isPendingAdminApproval => requestStatus == 'pending_admin_approval';

  // Check if request is completed
  bool get isCompleted => requestStatus == 'completed';

  // Check if request is rejected
  bool get isRejected => requestStatus == 'rejected_by_orphanage' || requestStatus == 'rejected_by_admin';

  // Get status color
  String get statusColor {
    switch (requestStatus) {
      case 'completed':
        return '#4CAF50'; // Green
      case 'rejected_by_orphanage':
      case 'rejected_by_admin':
        return '#F44336'; // Red
      case 'pending_orphanage_approval':
      case 'pending_admin_approval':
      default:
        return '#FF9800'; // Orange
    }
  }

  // Get status display text
  String get statusDisplay {
    switch (requestStatus) {
      case 'completed':
        return 'Completed';
      case 'rejected_by_orphanage':
        return 'Rejected by Orphanage';
      case 'rejected_by_admin':
        return 'Rejected by Admin';
      case 'pending_orphanage_approval':
        return 'Pending Orphanage Review';
      case 'pending_admin_approval':
        return 'Pending Admin Approval';
      default:
        return 'Unknown';
    }
  }

  // Get background check status display text
  String get backgroundCheckDisplay {
    switch (backgroundCheckStatus) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'failed':
        return 'Failed';
      case 'not_started':
      default:
        return 'Not Started';
    }
  }
}