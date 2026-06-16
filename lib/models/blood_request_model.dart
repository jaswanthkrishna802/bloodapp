import 'package:cloud_firestore/cloud_firestore.dart';

enum UrgencyLevel { critical, urgent, normal }
enum RequestStatus { pending, accepted, fulfilled, cancelled }

class BloodRequestModel {
  final String id;
  final String patientName;
  final String bloodGroup;
  final String hospitalName;
  final String hospitalLocation;
  final int unitsRequired;
  final UrgencyLevel urgency;
  final RequestStatus status;
  final String requestedBy;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final String? acceptedDonorId;

  BloodRequestModel({

    required this.id,
    required this.patientName,
    required this.bloodGroup,
    required this.hospitalName,
    required this.hospitalLocation,
    required this.unitsRequired,
    required this.urgency,
    this.status = RequestStatus.pending,
    required this.requestedBy,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.acceptedDonorId,
  });


  String get urgencyLabel {
    switch (urgency) {
      case UrgencyLevel.critical: return 'CRITICAL';
      case UrgencyLevel.urgent: return 'URGENT';
      case UrgencyLevel.normal: return 'NORMAL';
    }
  }

  Map<String, dynamic> toJson() => {
    'patientName': patientName,
    'bloodGroup': bloodGroup,
    'hospitalName': hospitalName,
    'hospitalLocation': hospitalLocation,
    'unitsRequired': unitsRequired,
    'urgency': urgency.index,
    'status': status.index,
    'requestedBy': requestedBy,
    'createdAt': FieldValue.serverTimestamp(),
    'latitude': latitude,
    'longitude': longitude,
    if (acceptedDonorId != null) 'acceptedDonorId': acceptedDonorId,
  };


  factory BloodRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime dt;
    final raw = json['createdAt'];
    if (raw is Timestamp) {
      dt = raw.toDate();
    } else if (raw is String) {
      dt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      dt = DateTime.now();
    }
    return BloodRequestModel(
      id: json['id'] ?? '',
      patientName: json['patientName'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      hospitalName: json['hospitalName'] ?? '',
      hospitalLocation: json['hospitalLocation'] ?? '',
      unitsRequired: json['unitsRequired'] ?? 1,
      urgency: UrgencyLevel.values[json['urgency'] ?? 0],
      status: RequestStatus.values[json['status'] ?? 0],
      requestedBy: json['requestedBy'] ?? '',
      createdAt: dt,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      acceptedDonorId: json['acceptedDonorId'],
    );
  }

}
