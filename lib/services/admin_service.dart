import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/child_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ================= USERS =================

  Future<List<UserModel>> getAllUsers() async {
    try {
      print('📥 Fetching all users...');
      final snapshot = await _firestore.collection('users').get();
      print('✅ Found ${snapshot.docs.length} users');

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      print('📥 Fetching users with role: $role');
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      print('✅ Found ${snapshot.docs.length} users with role: $role');
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting users by role: $e');
      return [];
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      print('📥 Fetching ${userIds.length} users by IDs');
      final List<UserModel> users = [];

      for (final id in userIds) {
        final doc = await _firestore.collection('users').doc(id).get();
        if (doc.exists) {
          users.add(UserModel.fromMap(doc.data()!));
        }
      }

      print('✅ Found ${users.length} users');
      return users;
    } catch (e) {
      print('❌ Error getting users by IDs: $e');
      return [];
    }
  }

  /// ================= CHILDREN =================

  Future<List<ChildModel>> getAllChildren() async {
    try {
      print('📥 Fetching all children...');
      final snapshot = await _firestore.collection('children').get();
      print('✅ Found ${snapshot.docs.length} children');

      return snapshot.docs
          .map((doc) => ChildModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting all children: $e');
      return [];
    }
  }

  /// ================= DELETE =================

  Future<String?> deleteUser(String userId) async {
    try {
      print('🗑️ Deleting user: $userId');
      await _firestore.collection('users').doc(userId).delete();
      print('✅ User deleted successfully');
      return null;
    } catch (e) {
      print('❌ Error deleting user: $e');
      return 'Failed to delete user';
    }
  }

  Future<String?> deleteChild(String childId) async {
    try {
      print('🗑️ Deleting child: $childId');
      await _firestore.collection('children').doc(childId).delete();
      print('✅ Child deleted successfully');
      return null;
    } catch (e) {
      print('❌ Error deleting child: $e');
      return 'Failed to delete child';
    }
  }

  /// ================= STATISTICS =================

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      print('📊 FETCHING STATISTICS...');

      // Fetch all collections
      final usersSnapshot = await _firestore.collection('users').get();
      final childrenSnapshot = await _firestore.collection('children').get();

      print('📊 Users found: ${usersSnapshot.docs.length}');
      print('📊 Children found: ${childrenSnapshot.docs.length}');

      // Count families and orphanages
      int families = 0;
      int orphanages = 0;
      int totalInterests = 0;

      for (var doc in usersSnapshot.docs) {
        try {
          final data = doc.data();
          final role = data['role'] as String?;

          if (role == 'family') {
            families++;
          } else if (role == 'orphanage') {
            orphanages++;
          }
        } catch (e) {
          print('⚠️ Error parsing user doc ${doc.id}: $e');
        }
      }

      // Count total interests from children
      for (var doc in childrenSnapshot.docs) {
        try {
          final data = doc.data();
          final interestedFamilies = data['interestedFamilies'] as List?;
          if (interestedFamilies != null) {
            totalInterests += interestedFamilies.length;
          }
        } catch (e) {
          print('⚠️ Error parsing child doc ${doc.id}: $e');
        }
      }

      print('📊 Families: $families');
      print('📊 Orphanages: $orphanages');
      print('📊 Total Interests: $totalInterests');

      final stats = {
        'totalUsers': usersSnapshot.docs.length,
        'totalChildren': childrenSnapshot.docs.length,
        'totalFamilies': families,
        'totalOrphanages': orphanages,
        'totalInterests': totalInterests,
      };

      print('✅ STATISTICS COMPLETE: $stats');
      return stats;

    } catch (e) {
      print('❌ ERROR GETTING STATISTICS: $e');
      print('Stack trace: ${StackTrace.current}');
      return {
        'totalUsers': 0,
        'totalChildren': 0,
        'totalFamilies': 0,
        'totalOrphanages': 0,
        'totalInterests': 0,
      };
    }
  }

  /// ================= SEARCH =================

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      print('🔍 Searching users: $query');
      final snapshot = await _firestore.collection('users').get();
      final users = snapshot.docs.map((e) => UserModel.fromMap(e.data())).toList();

      final results = users.where((u) {
        final q = query.toLowerCase();
        return u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phone.contains(query) ||
            u.location.toLowerCase().contains(q);
      }).toList();

      print('✅ Found ${results.length} matching users');
      return results;
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }

  Future<List<ChildModel>> searchChildren(String query) async {
    try {
      print('🔍 Searching children: $query');
      final snapshot = await _firestore.collection('children').get();
      final children = snapshot.docs.map((e) => ChildModel.fromMap(e.data())).toList();

      final results = children.where((c) {
        final q = query.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.orphanageName.toLowerCase().contains(q) ||
            c.location.toLowerCase().contains(q);
      }).toList();

      print('✅ Found ${results.length} matching children');
      return results;
    } catch (e) {
      print('❌ Error searching children: $e');
      return [];
    }
  }
}