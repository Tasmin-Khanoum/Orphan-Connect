import 'package:cloud_firestore/cloud_firestore.dart';

class AdoptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates an adoption request in Firestore
  Future<String?> createAdoptionRequest({
    required String childId,
    required String childName,
    required String familyId,
    required String familyName,
    required String familyEmail,
    required String familyPhone,
    required String orphanageId,
    required String orphanageName,
    required String reasonForAdoption,
    String backgroundCheckStatus = 'not_started',
  }) async {
    try {
      // Generate unique ID
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create adoption request document
      await _firestore.collection('adoption_requests').doc(requestId).set({
        'id': requestId,
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
        'requestStatus': 'pending_orphanage_approval',
        'createdAt': DateTime.now().toIso8601String(),
        'orphanageRespondedAt': null,
        'adminReviewedAt': null,
        'orphanageRejectionReason': null,
      });

      return null; // Success
    } catch (e) {
      print('Error creating adoption request: $e');
      return 'Failed to submit adoption request. Please try again.';
    }
  }

  /// Get all adoption requests for a family
  Stream<List<Map<String, dynamic>>> getFamilyAdoptionRequests(String familyId) {
    return _firestore
        .collection('adoption_requests')
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Get all adoption requests for an orphanage
  Stream<List<Map<String, dynamic>>> getOrphanageAdoptionRequests(String orphanageId) {
    return _firestore
        .collection('adoption_requests')
        .where('orphanageId', isEqualTo: orphanageId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Update adoption request status
  Future<String?> updateAdoptionRequestStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      await _firestore.collection('adoption_requests').doc(requestId).update({
        'requestStatus': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return null; // Success
    } catch (e) {
      print('Error updating adoption request: $e');
      return 'Failed to update request status. Please try again.';
    }
  }

  /// Delete adoption request
  Future<String?> deleteAdoptionRequest(String requestId) async {
    try {
      await _firestore.collection('adoption_requests').doc(requestId).delete();
      return null; // Success
    } catch (e) {
      print('Error deleting adoption request: $e');
      return 'Failed to delete request. Please try again.';
    }
  }

  /// Check if family has existing adoption request for a child
  Future<bool> hasExistingAdoptionRequest({
    required String childId,
    required String familyId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('adoption_requests')
          .where('childId', isEqualTo: childId)
          .where('familyId', isEqualTo: familyId)
          .where('requestStatus', whereNotIn: ['rejected_by_orphanage', 'rejected_by_admin'])
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking adoption request: $e');
      return false;
    }
  }
}