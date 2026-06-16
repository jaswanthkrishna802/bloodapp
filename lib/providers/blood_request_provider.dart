import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/blood_request_model.dart';
import '../models/notification_model.dart';
import '../models/donor_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class BloodRequestProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  final LocationService _loc = LocationService();

  List<BloodRequestModel> _nearbyRequests = [];
  List<BloodRequestModel> _myRequests = [];
  List<BloodRequestModel> _myDonations = [];
  List<DonorModel> _nearbyDonors = [];
  List<UserModel> _stateUsers = [];
  List<UserModel> _cityUsers = [];
  List<Map<String, dynamic>> _bloodStock = [];


  bool _loading = false;
  String? _error;
  Position? _currentPosition;
  String _currentCity = '';

  List<BloodRequestModel> get nearbyRequests => _nearbyRequests;
  List<BloodRequestModel> get myRequests => _myRequests;
  List<BloodRequestModel> get myDonations => _myDonations;
  List<DonorModel> get nearbyDonors => _nearbyDonors;
  List<UserModel> get stateUsers => _stateUsers;
  List<UserModel> get cityUsers => _cityUsers;
  List<Map<String, dynamic>> get bloodStock => _bloodStock;

  bool get loading => _loading;
  String? get error => _error;
  String get currentCity => _currentCity;

  StreamSubscription? _nearbySubscription;
  StreamSubscription? _myRequestsSubscription;
  StreamSubscription? _myDonationsSubscription;
  String? _listenedUserId;


  // ─── INIT LOCATION ────────────────────────────────────────────
  Future<void> init([String? userId]) async {
    _currentPosition = await _loc.getCurrentPosition();
    listenToNearbyRequests(); 
    if (userId != null) {
      listenToMyRequests(userId);
      listenToMyDonations(userId);
    }
  }


  // ─── STREAM REQUESTS ──────────────────────────────────────────
  void listenToNearbyRequests() {
    _nearbySubscription?.cancel();
    final lat = _currentPosition?.latitude ?? 12.9165;
    final lng = _currentPosition?.longitude ?? 79.1325;

    _nearbySubscription = _db.getNearbyRequests(lat: lat, lng: lng).listen((requests) {
      _nearbyRequests = requests;
      notifyListeners();
    });
  }

  void listenToMyRequests(String userId) {
    if (_listenedUserId == userId && _myRequestsSubscription != null) return;
    
    _listenedUserId = userId;
    _myRequestsSubscription?.cancel();
    _myRequestsSubscription = _db.getMyRequests(userId).listen((requests) {
      _myRequests = requests;
      notifyListeners();
    });
  }

  void listenToMyDonations(String userId) {
    _myDonationsSubscription?.cancel();
    _myDonationsSubscription = _db.getMyDonations(userId).listen((donations) {
      _myDonations = donations;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _nearbySubscription?.cancel();
    _myRequestsSubscription?.cancel();
    _myDonationsSubscription?.cancel();
    super.dispose();
  }


  Future<void> notifyRequesterOfInteraction(BloodRequestModel request, String donorName, String interactionType, String donorId) async {
    await _db.createNotification(
      userId: request.requestedBy,
      title: 'Donor Interaction',
      message: '$donorName tried to $interactionType you regarding your ${request.bloodGroup} request.',
      type: NotificationType.info,
      metadata: {
        'donorId': donorId,
        'donorName': donorName,
        'requestId': request.id,
        'bloodGroup': request.bloodGroup,
        'type': interactionType,
      },
    );
  }

  Future<void> notifyDonorOfInteraction(DonorModel donor, String requesterName, String interactionType, String requesterId) async {
    await _db.createNotification(
      userId: donor.id,
      title: 'Donor Interaction', // Reuse title for popup logic
      message: '$requesterName contacted you regarding a blood request in ${donor.location}.',
      type: NotificationType.info,
      metadata: {
        'donorId': donor.id,
        'donorName': donor.name,
        'requestId': 'search_interaction',
        'bloodGroup': donor.bloodGroup,
        'type': interactionType,
        'requesterId': requesterId,
      },
    );
  }


  Future<void> respondToInteraction({
    required NotificationModel originalNotif,
    required bool accepted,
    required String requesterName,
  }) async {
    final metadata = originalNotif.metadata;
    if (metadata == null) return;

    final donorId = metadata['donorId'];
    final requestId = metadata['requestId'];
    final bloodGroup = metadata['bloodGroup'];

    // 1. Notify Donor
    await _db.createNotification(
      userId: donorId,
      title: 'Response Update',
      message: 'Requester $requesterName has ${accepted ? 'ACCEPTED' : 'REJECTED'} your offer for $bloodGroup.',
      type: accepted ? NotificationType.success : NotificationType.warning,
      metadata: {
        'requestId': requestId,
        'accepted': accepted,
      },
    );

    // 2. Mark original notif as read
    await _db.markNotificationRead(originalNotif.id);

    // 3. Update request status if accepted
    if (accepted) {
      await _db.updateRequestStatus(requestId, RequestStatus.accepted, acceptedDonorId: donorId);
      await _db.incrementTotalDonations(donorId);
    }
  }


  // ─── CREATE REQUEST ───────────────────────────────────────────
  Future<bool> createRequest(BloodRequestModel request) async {
    _setLoading(true);
    try {
      await _db.createBloodRequest(request);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── SEARCH DONORS BY CITY + BLOOD GROUP ─────────────────────
  Future<void> searchDonors(String? bloodGroup, String city) async {
    _setLoading(true);
    try {
      _currentCity = city;

      // Fetch all donors matching bloodGroup (optional) + city from Firestore
      _nearbyDonors = await _db.getNearbyDonors(
        bloodGroup: bloodGroup,
        city: city,
        userLat: _currentPosition?.latitude,
        userLng: _currentPosition?.longitude,
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
      _nearbyDonors = [];
    } finally {
      _setLoading(false);
    }
  }

  // ─── FETCH ALL USERS BY CITY (FOR STATS) ─────────────────────
  Future<void> fetchCityUsers(String city) async {
    _setLoading(true);
    try {
      _currentCity = city;
      _cityUsers = await _db.getUsersByCity(city);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _cityUsers = [];
    } finally {
      _setLoading(false);
    }
  }

  // ─── SEARCH USERS BY STATE ────────────────────────────────────
  Future<void> searchByState(String state) async {
    _setLoading(true);
    try {
      _stateUsers = await _db.getUsersByState(state);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _stateUsers = [];
    } finally {
      _setLoading(false);
    }
  }

  // ─── LOAD BLOOD STOCK ─────────────────────────────────────────
  void loadBloodStock(String city) {
    _db.getBloodStock(city).listen((stock) {
      _bloodStock = stock;
      notifyListeners();
    });
  }

  // ─── SORT BY NAME ─────────────────────────────────────────────
  void sortDonorsByName() {
    _nearbyDonors.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  // ─── SORT BY AVAILABILITY ─────────────────────────────────────
  void sortDonorsByAvailability() {
    _nearbyDonors.sort((a, b) {
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      return 0;
    });
    notifyListeners();
  }

  // ─── SORT BY DISTANCE ─────────────────────────────────────────
  void sortDonorsByDistance() {
    _nearbyDonors.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    notifyListeners();
  }

  // ─── SORT BY RATING ───────────────────────────────────────────
  void sortDonorsByRating() {
    _nearbyDonors.sort((a, b) => b.rating.compareTo(a.rating));
    notifyListeners();
  }

  // ─── FILTER AVAILABLE ONLY ────────────────────────────────────
  void filterAvailableOnly() {
    _nearbyDonors = _nearbyDonors
        .where((d) => d.isAvailable)
        .toList();
    notifyListeners();
  }

  // ─── CLEAR DONORS ─────────────────────────────────────────────
  void clearDonors() {
    _nearbyDonors = [];
    _currentCity = '';
    notifyListeners();
  }

  // ─── UPDATE REQUEST STATUS ────────────────────────────────────
  Future<void> updateStatus(
      String requestId, RequestStatus status) async {
    await _db.updateRequestStatus(requestId, status);
  }

  // ─── CLEAR ERROR ──────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }
}
