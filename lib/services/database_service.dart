import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/child_model.dart';
import '../models/user_model.dart';
import '../models/adoption_request_model.dart';
import 'image_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> addChild({
    required ChildModel child,
    required File? imageFile,
  }) async {
    try {
      String imageUrl;

      if (imageFile != null) {
        print('Uploading real image...');
        final uploadedUrl = await ImageService.uploadImage(imageFile);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
          print('Using uploaded image: $imageUrl');
        } else {
          print('Upload failed, using placeholder');
          imageUrl = ImageService.generateAvatar(child.name, gender: child.gender);
        }
      } else {
        print('No image selected, using placeholder');
        imageUrl = ImageService.generateAvatar(child.name, gender: child.gender);
      }

      ChildModel childWithImage = child.copyWith(photoUrl: imageUrl);

      await _firestore.collection('children').doc(child.id).set(childWithImage.toMap());

      return null;
    } catch (e) {
      print('Error adding child: $e');
      return 'Failed to add child: $e';
    }
  }

  Future<String?> updateChild({
    required ChildModel child,
    File? imageFile,
  }) async {
    try {
      String imageUrl = child.photoUrl;

      if (imageFile != null) {
        print('Uploading new image...');
        final uploadedUrl = await ImageService.uploadImage(imageFile);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
          print('Using new uploaded image: $imageUrl');
        } else {
          print('Upload failed, keeping old image');
        }
      }

      ChildModel updatedChild = child.copyWith(photoUrl: imageUrl);

      await _firestore.collection('children').doc(child.id).update(updatedChild.toMap());

      return null;
    } catch (e) {
      print('Error updating child: $e');
      return 'Failed to update child: $e';
    }
  }

  Future<String?> deleteChild(String childId) async {
    try {
      await _firestore.collection('children').doc(childId).delete();
      return null;
    } catch (e) {
      print('Error deleting child: $e');
      return 'Failed to delete child: $e';
    }
  }

  Stream<List<ChildModel>> getAllChildren() {
    print('🔍 FETCHING ALL CHILDREN...');

    return _firestore
        .collection('children')
        .snapshots()
        .map((snapshot) {
      print('📊 Found ${snapshot.docs.length} total children documents');

      final List<ChildModel> allChildren = [];

      for (var doc in snapshot.docs) {
        try {
          final child = ChildModel.fromMap(doc.data());
          allChildren.add(child);
          print('✅ Parsed child: ${child.name} (Available: ${child.availableForAdoption}, Adopted: ${child.isAdopted})');
        } catch (e) {
          print('❌ Error parsing child doc ${doc.id}: $e');
          print('Doc data: ${doc.data()}');
        }
      }

      // Filter in Dart instead of Firestore to avoid index requirement
      final filteredChildren = allChildren.where((child) {
        return child.availableForAdoption == true && child.isAdopted == false;
      }).toList();

      // Sort by createdAt in Dart
      filteredChildren.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ After filtering: ${filteredChildren.length} available children');
      return filteredChildren;
    }).handleError((error) {
      print('❌ ERROR IN getAllChildren stream: $error');
      return <ChildModel>[];
    });
  }

  Stream<List<ChildModel>> getChildrenByOrphanage(String orphanageId) {
    return _firestore
        .collection('children')
        .where('orphanageId', isEqualTo: orphanageId)
        .snapshots()
        .map((snapshot) {
      final children = snapshot.docs.map((doc) {
        return ChildModel.fromMap(doc.data());
      }).toList();

      // Sort in Dart to avoid index requirement
      children.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return children;
    });
  }

  Future<List<ChildModel>> searchChildren({
    String? searchQuery,
    int? minAge,
    int? maxAge,
    String? gender,
    String? location,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('children')
          .get();

      List<ChildModel> children = snapshot.docs.map((doc) {
        return ChildModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      // Filter for available children only
      children = children.where((child) =>
      child.availableForAdoption == true && child.isAdopted == false
      ).toList();

      if (gender != null && gender != 'All') {
        children = children.where((child) => child.gender == gender).toList();
      }

      if (location != null && location.isNotEmpty && location != 'All') {
        children = children.where((child) => child.location == location).toList();
      }

      if (minAge != null || maxAge != null) {
        children = children.where((child) {
          if (minAge != null && child.age < minAge) return false;
          if (maxAge != null && child.age > maxAge) return false;
          return true;
        }).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        children = children.where((child) {
          return child.name.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      return children;
    } catch (e) {
      print('Error searching children: $e');
      return [];
    }
  }

  Future<String?> expressInterest({
    required String childId,
    required String familyId,
  }) async {
    try {
      DocumentReference childRef = _firestore.collection('children').doc(childId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot childDoc = await transaction.get(childRef);

        if (!childDoc.exists) {
          throw Exception('Child not found');
        }

        ChildModel child = ChildModel.fromMap(childDoc.data() as Map<String, dynamic>);

        if (child.interestedFamilies.contains(familyId)) {
          throw Exception('You have already expressed interest in this child');
        }

        List<String> updatedList = [...child.interestedFamilies, familyId];
        transaction.update(childRef, {'interestedFamilies': updatedList});
      });

      return null;
    } catch (e) {
      print('Error expressing interest: $e');
      return e.toString();
    }
  }

  Future<String?> removeInterest({
    required String childId,
    required String familyId,
  }) async {
    try {
      DocumentReference childRef = _firestore.collection('children').doc(childId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot childDoc = await transaction.get(childRef);

        if (!childDoc.exists) {
          throw Exception('Child not found');
        }

        ChildModel child = ChildModel.fromMap(childDoc.data() as Map<String, dynamic>);

        List<String> updatedList = child.interestedFamilies.where((id) => id != familyId).toList();
        transaction.update(childRef, {'interestedFamilies': updatedList});
      });

      return null;
    } catch (e) {
      print('Error removing interest: $e');
      return 'Failed to remove interest: $e';
    }
  }

  Future<List<UserModel>> getInterestedFamilies(List<String> familyIds) async {
    if (familyIds.isEmpty) return [];

    try {
      List<UserModel> families = [];

      for (String familyId in familyIds) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(familyId).get();
        if (doc.exists) {
          families.add(UserModel.fromMap(doc.data() as Map<String, dynamic>));
        }
      }

      return families;
    } catch (e) {
      print('Error getting interested families: $e');
      return [];
    }
  }

  Future<List<ChildModel>> getMyInterests(String familyId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('children')
          .where('interestedFamilies', arrayContains: familyId)
          .get();

      return snapshot.docs.map((doc) {
        return ChildModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting interests: $e');
      return [];
    }
  }

  Future<List<String>> getAllLocations() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('children').get();
      Set<String> locations = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['location'] != null) {
          locations.add(data['location'] as String);
        }
      }

      return locations.toList()..sort();
    } catch (e) {
      print('Error getting locations: $e');
      return [];
    }
  }

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
    required String backgroundCheckStatus,
  }) async {
    try {
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();

      final adoptionRequest = AdoptionRequest(
        id: requestId,
        childId: childId,
        childName: childName,
        familyId: familyId,
        familyName: familyName,
        familyEmail: familyEmail,
        familyPhone: familyPhone,
        orphanageId: orphanageId,
        orphanageName: orphanageName,
        reasonForAdoption: reasonForAdoption,
        backgroundCheckStatus: backgroundCheckStatus,
        requestStatus: 'pending_orphanage_approval',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('adoption_requests')
          .doc(requestId)
          .set(adoptionRequest.toMap());

      return null;
    } catch (e) {
      print('Error creating adoption request: $e');
      return 'Failed to create adoption request: $e';
    }
  }

  Stream<List<AdoptionRequest>> getAdoptionRequestsByOrphanage(String orphanageId) {
    return _firestore
        .collection('adoption_requests')
        .where('orphanageId', isEqualTo: orphanageId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return AdoptionRequest.fromMap(doc.data());
      }).toList();

      // Sort in Dart to avoid index requirement
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Stream<List<AdoptionRequest>> getAdoptionRequestsByFamily(String familyId) {
    return _firestore
        .collection('adoption_requests')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return AdoptionRequest.fromMap(doc.data());
      }).toList();

      // Sort in Dart to avoid index requirement
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Stream<List<AdoptionRequest>> getPendingAdminApprovalRequests() {
    return _firestore
        .collection('adoption_requests')
        .where('requestStatus', isEqualTo: 'pending_admin_approval')
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return AdoptionRequest.fromMap(doc.data());
      }).toList();

      // Sort in Dart to avoid index requirement
      requests.sort((a, b) {
        final aTime = (a as dynamic).orphanageRespondedAt ?? a.createdAt;
        final bTime = (b as dynamic).orphanageRespondedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      return requests;
    });
  }

  Future<String?> acceptAdoptionRequest({
    required String requestId,
    required AdoptionRequest request,
  }) async {
    try {
      await _firestore.collection('adoption_requests').doc(requestId).update({
        'requestStatus': 'pending_admin_approval',
        'orphanageRespondedAt': DateTime.now().toIso8601String(),
      });

      return null;
    } catch (e) {
      print('Error accepting adoption request: $e');
      return 'Failed to accept adoption request: $e';
    }
  }

  Future<String?> rejectAdoptionRequest({
    required String requestId,
    required String rejectionReason,
  }) async {
    try {
      await _firestore.collection('adoption_requests').doc(requestId).update({
        'requestStatus': 'rejected_by_orphanage',
        'orphanageRejectionReason': rejectionReason,
        'orphanageRespondedAt': DateTime.now().toIso8601String(),
      });

      return null;
    } catch (e) {
      print('Error rejecting adoption request: $e');
      return 'Failed to reject adoption request: $e';
    }
  }

  Future<String?> approveAdoptionByAdmin({
    required String requestId,
    required String childId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore.collection('adoption_requests').doc(requestId);
        final childRef = _firestore.collection('children').doc(childId);

        final requestDoc = await transaction.get(requestRef);
        final childDoc = await transaction.get(childRef);

        if (!requestDoc.exists || !childDoc.exists) {
          throw Exception('Request or child not found');
        }

        transaction.update(requestRef, {
          'requestStatus': 'completed',
          'adminReviewedAt': DateTime.now().toIso8601String(),
        });

        transaction.update(childRef, {
          'isAdopted': true,
          'availableForAdoption': false,
        });
      });

      return null;
    } catch (e) {
      print('Error approving adoption: $e');
      return 'Failed to approve adoption: $e';
    }
  }

  Future<String?> rejectAdoptionByAdmin({
    required String requestId,
  }) async {
    try {
      await _firestore.collection('adoption_requests').doc(requestId).update({
        'requestStatus': 'rejected_by_admin',
        'adminReviewedAt': DateTime.now().toIso8601String(),
      });

      return null;
    } catch (e) {
      print('Error rejecting adoption: $e');
      return 'Failed to reject adoption: $e';
    }
  }

  Future<bool> hasExistingAdoptionRequest({
    required String childId,
    required String familyId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('adoption_requests')
          .where('childId', isEqualTo: childId)
          .where('familyId', isEqualTo: familyId)
          .get();

      // Filter in Dart to check status
      final activeRequests = snapshot.docs.where((doc) {
        final status = doc.data()['requestStatus'] as String?;
        return status != 'rejected_by_orphanage' && status != 'rejected_by_admin';
      });

      return activeRequests.isNotEmpty;
    } catch (e) {
      print('Error checking adoption request: $e');
      return false;
    }
  }

  // ── Payment Methods ────────────────────────────────────────────────────────

  Future<String?> savePaymentMethod({
    required String orphanageId,
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      final methodId = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore
          .collection('users')
          .doc(orphanageId)
          .collection('payment_methods')
          .doc(methodId)
          .set({
        ...paymentData,
        'id': methodId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return null;
    } catch (e) {
      print('Error saving payment method: $e');
      return 'Failed to save payment method: $e';
    }
  }

  Stream<List<Map<String, dynamic>>> getPaymentMethods(String orphanageId) {
    return _firestore
        .collection('users')
        .doc(orphanageId)
        .collection('payment_methods')
        .snapshots()
        .map((snapshot) {
      final methods = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      methods.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
      return methods;
    });
  }

  Future<String?> deletePaymentMethod({
    required String orphanageId,
    required String methodId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(orphanageId)
          .collection('payment_methods')
          .doc(methodId)
          .delete();
      return null;
    } catch (e) {
      print('Error deleting payment method: $e');
      return 'Failed to delete payment method: $e';
    }
  }
}