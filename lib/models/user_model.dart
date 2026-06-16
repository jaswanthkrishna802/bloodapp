class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String bloodGroup;
  final String location;
  final String city;
  final String state;
  final String role; // donor, patient, hospital, admin
  final int totalDonations;
  final double rating;
  final DateTime? lastDonation;
  final DateTime? nextEligible;
  final bool isAvailable;
  final double? latitude;
  final double? longitude;
  final Map<String, int>? bloodStock;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.bloodGroup,
    required this.location,
    required this.city,
    required this.state,
    required this.role,
    this.totalDonations = 0,
    this.rating = 0.0,
    this.lastDonation,
    this.nextEligible,
    this.isAvailable = true,
    this.latitude,
    this.longitude,
    this.bloodStock,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        bloodGroup: json['bloodGroup'] ?? '',
        location: json['location'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        role: json['role'] ?? 'donor',
        totalDonations: json['totalDonations'] ?? 0,
        rating: (json['rating'] ?? 0.0).toDouble(),
        isAvailable: json['isAvailable'] ?? true,
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        bloodStock: json['bloodStock'] != null
            ? Map<String, int>.from(json['bloodStock'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'bloodGroup': bloodGroup,
        'location': location,
        'city': city,
        'state': state,
        'role': role,
        'totalDonations': totalDonations,
        'rating': rating,
        'isAvailable': isAvailable,
        'latitude': latitude,
        'longitude': longitude,
        'bloodStock': bloodStock,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? bloodGroup,
    String? location,
    String? city,
    String? state,
    String? role,
    int? totalDonations,
    double? rating,
    DateTime? lastDonation,
    DateTime? nextEligible,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    Map<String, int>? bloodStock,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      location: location ?? this.location,
      city: city ?? this.city,
      state: state ?? this.state,
      role: role ?? this.role,
      totalDonations: totalDonations ?? this.totalDonations,
      rating: rating ?? this.rating,
      lastDonation: lastDonation ?? this.lastDonation,
      nextEligible: nextEligible ?? this.nextEligible,
      isAvailable: isAvailable ?? this.isAvailable,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bloodStock: bloodStock ?? this.bloodStock,
    );
  }
}
