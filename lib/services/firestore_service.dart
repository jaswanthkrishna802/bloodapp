import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blood_request_model.dart';
import '../models/donor_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── BLOOD REQUESTS ───────────────────────────────────────────

  Future<String> createBloodRequest(BloodRequestModel request) async {
    final ref = await _db.collection('blood_requests').add(request.toJson());
    return ref.id;
  }

  Stream<List<BloodRequestModel>> getNearbyRequests({
    required double lat,
    required double lng,
    double radiusKm = 50,
  }) {
    return _db
        .collection('blood_requests')
        .where('status', isEqualTo: 0)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) {
        final data = d.data();
        final rLat = (data['latitude'] as num?)?.toDouble();
        final rLng = (data['longitude'] as num?)?.toDouble();
        double? dist;
        if (rLat != null && rLng != null) {
          dist = _distanceKm(lat, lng, rLat, rLng);
        }
        return BloodRequestModel.fromJson({
          ...data,
          'id': d.id,
          if (dist != null) 'distanceKm': dist,
        });
      }).toList();

      // Sort locally since index might be missing
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<BloodRequestModel>> getRequestsByBloodGroup(String bloodGroup) {
    return _db
        .collection('blood_requests')
        .where('bloodGroup', isEqualTo: bloodGroup)
        .where('status', isEqualTo: 0)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => BloodRequestModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> updateRequestStatus(
      String requestId, RequestStatus status, {String? acceptedDonorId}) async {
    final Map<String, dynamic> data = {'status': status.index};
    if (acceptedDonorId != null) {
      data['acceptedDonorId'] = acceptedDonorId;
    }
    await _db.collection('blood_requests').doc(requestId).update(data);
  }


  Stream<List<BloodRequestModel>> getMyRequests(String userId) {
    return _db
        .collection('blood_requests')
        .where('requestedBy', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => BloodRequestModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<BloodRequestModel>> getMyDonations(String userId) {
    return _db
        .collection('blood_requests')
        .where('acceptedDonorId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => BloodRequestModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<void> incrementTotalDonations(String userId) async {
    await _db.collection('users').doc(userId).update({
      'totalDonations': FieldValue.increment(1)
    });
  }

  // ─── DONORS (city-based, no radius limit) ─────────────────────

  Future<List<DonorModel>> getNearbyDonors({
    String? bloodGroup,
    required String city,
    double? userLat,
    double? userLng,
  }) async {
    Query donorQuery = _db.collection('users').where('role', isEqualTo: 'donor');

    if (bloodGroup != null && bloodGroup != 'All') {
      donorQuery = donorQuery.where('bloodGroup', isEqualTo: bloodGroup);
    }

    final donorSnap = await donorQuery.get();

    final hospitalSnap = await _db
        .collection('users')
        .where('role', whereIn: ['hospital', 'blood_bank'])
        .get();

    final allDocs = [...donorSnap.docs, ...hospitalSnap.docs];

    final donors = allDocs
        .where((d) {
          final data = d.data() as Map<String, dynamic>?;
          if (data == null) return false;
          
          final role = data['role'] ?? 'donor';
          if (role == 'hospital' || role == 'blood_bank') {
            if (bloodGroup != null && bloodGroup != 'All') {
              final stock = data['bloodStock'] as Map<String, dynamic>?;
              if (stock == null || (stock[bloodGroup] ?? 0) <= 0) {
                return false;
              }
            }
          }

          final loc = (data['location'] as String? ?? '').toLowerCase();
          final dCity = (data['city'] as String? ?? '').toLowerCase();
          final matchesCity = dCity == city.toLowerCase() || loc.contains(city.toLowerCase());

          final dLat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
          final dLng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
          
          bool isNearby = false;
          if (userLat != null && userLng != null && dLat != 0.0 && dLng != 0.0) {
            final dist = _distanceKm(userLat, userLng, dLat, dLng);
            if (dist <= 50.0) {
              isNearby = true;
            }
          }

          return matchesCity || isNearby;
        })
        .map((d) {
          final data = d.data() as Map<String, dynamic>;
          final role = data['role'] ?? 'donor';

          final dLat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
          final dLng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
          
          double distance = 0.0;
          if (userLat != null && userLng != null && dLat != 0.0) {
            distance = _distanceKm(userLat, userLng, dLat, dLng);
          }

          int? units;
          String bGroup = data['bloodGroup'] ?? '';
          Map<String, int>? stockMap;

          if (role == 'hospital' || role == 'blood_bank') {
            final rawStock = data['bloodStock'] as Map<String, dynamic>?;
            if (rawStock != null) {
              stockMap = rawStock.map((k, v) => MapEntry(k, (v as num).toInt()));
            }
            if (bloodGroup != null && bloodGroup != 'All') {
              units = stockMap?[bloodGroup];
              bGroup = bloodGroup;
            } else {
              if (stockMap != null) {
                units = stockMap.values.fold(0, (total, val) => total! + val);
              }
              bGroup = 'Multiple';
            }
          }

          return DonorModel(
            id: d.id,
            name: data['name'] ?? '',
            bloodGroup: bGroup,
            location: data['location'] ?? '',
            distanceKm: distance,
            isAvailable: data['isAvailable'] ?? true,
            totalDonations: data['totalDonations'] ?? 0,
            rating: (data['rating'] ?? 0.0).toDouble(),
            phone: data['phone'] ?? '',
            lastDonated: data['lastDonated'] ?? '',
            age: data['age'] ?? 25,
            gender: data['gender'] ?? 'Unknown',
            latitude: dLat,
            longitude: dLng,
            availableUnits: units,
            bloodStock: stockMap,
            type: role,
          );
        })
        .toList();

    // Sort by distance if available, otherwise by name
    if (userLat != null) {
      donors.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else {
      donors.sort((a, b) => a.name.compareTo(b.name));
    }
    return donors;
  }

  Future<List<UserModel>> getUsersByState(String state) async {
    final snap = await _db
        .collection('users')
        .where('state', isEqualTo: state)
        .get();

    final users = snap.docs
        .map((d) => UserModel.fromJson({...d.data(), 'id': d.id}))
        .toList();

    // Sort by city name in alphabetical order
    users.sort((a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()));
    return users;
  }

  Future<List<UserModel>> getUsersByCity(String query) async {
    final cityLower = query.toLowerCase();
    final isPincode = RegExp(r'^\d{6}$').hasMatch(query);

    // 1. Fetch from 'users' collection
    final userSnap = await _db.collection('users').get();
    final List<UserModel> users = userSnap.docs
        .where((d) {
          final data = d.data();
          final dCity = (data['city'] as String? ?? '').toLowerCase();
          final loc = (data['location'] as String? ?? '').toLowerCase();
          final pincodeField = (data['pincode'] as String? ?? '').toLowerCase();
          
          if (isPincode) {
            return dCity == cityLower || loc.contains(cityLower) || pincodeField == cityLower;
          }
          return dCity == cityLower || loc.contains(cityLower);
        })
        .map((d) => UserModel.fromJson({...d.data(), 'id': d.id}))
        .toList();

    // 2. Fetch from 'hospitals' collection (if they are separate)
    final hospSnap = await _db.collection('hospitals').get();
    final List<UserModel> hospitals = hospSnap.docs
        .where((d) {
          final data = d.data();
          final hCity = (data['city'] as String? ?? '').toLowerCase();
          final hLoc = (data['location'] as String? ?? '').toLowerCase();
          final hPincode = (data['pincode'] as String? ?? '').toLowerCase();

          if (isPincode) {
            return hCity == cityLower || hLoc.contains(cityLower) || hPincode == cityLower;
          }
          return hCity == cityLower || hLoc.contains(cityLower);
        })
        .map((d) {
          final data = d.data();
          return UserModel(
            id: d.id,
            name: data['name'] ?? 'Hospital',
            phone: data['phone'] ?? '',
            email: data['email'] ?? '',
            bloodGroup: 'Multiple',
            location: data['location'] ?? '',
            city: data['city'] ?? '',
            state: data['state'] ?? '',
            role: data['role'] ?? 'hospital',
            bloodStock: data['bloodStock'] != null ? Map<String, int>.from(data['bloodStock']) : null,
          );
        })
        .toList();

    // Combine and return (avoiding duplicates by ID)
    final Map<String, UserModel> combined = {};
    for (var u in users) {
      combined[u.id] = u;
    }
    for (var h in hospitals) {
      combined[h.id] = h;
    }

    return combined.values.toList();
  }

  Future<void> updateDonorLocation(
      String uid, double lat, double lng) async {
    await _db.collection('users').doc(uid).set({
      'latitude': lat,
      'longitude': lng,
    }, SetOptions(merge: true));
  }

  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateBloodStock(String uid, Map<String, int> stock) async {
    await _db.collection('users').doc(uid).set({
      'bloodStock': stock,
    }, SetOptions(merge: true));
  }

  // ─── BLOOD STOCK ──────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getBloodStock(String city) {
    return _db
        .collection('blood_stock')
        .where('city', isEqualTo: city)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Stream<List<Map<String, dynamic>>> getHospitalStocks(String city) {
    return _db
        .collection('hospitals')
        .where('city', isEqualTo: city)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => NotificationModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markNotificationRead(String notifId) async {
    await _db
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? metadata,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.index,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'metadata': metadata,
    });
  }

  // ─── ADMIN ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminStats() async {
    final donors = await _db
        .collection('users')
        .where('role', isEqualTo: 'donor')
        .count()
        .get();

    final requests = await _db
        .collection('blood_requests')
        .where('status', isEqualTo: 0)
        .count()
        .get();

    final hospitals = await _db.collection('hospitals').count().get();

    return {
      'totalDonors': donors.count,
      'activeRequests': requests.count,
      'hospitals': hospitals.count,
    };
  }

  // ─── HELPERS ─────────────────────────────────────────────────

  double _distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;
}
