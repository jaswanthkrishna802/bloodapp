class DonorModel {
  final String id;
  final String name;
  final String bloodGroup;
  final String location;
  final double distanceKm;
  final bool isAvailable;
  final int totalDonations;
  final double rating;
  final String phone;
  final String lastDonated;
  final int age;
  final String gender;
  final double? latitude;
  final double? longitude;
  final int? availableUnits;
  final Map<String, int>? bloodStock;

  final String type; // 🔥 ADD THIS (VERY IMPORTANT)

  DonorModel({
    required this.id,
    required this.name,
    required this.bloodGroup,
    required this.location,
    required this.distanceKm,
    required this.isAvailable,
    required this.totalDonations,
    required this.rating,
    required this.phone,
    required this.lastDonated,
    required this.age,
    required this.gender,
    this.latitude,
    this.longitude,
    this.availableUnits,
    this.bloodStock,
    this.type = 'donor', // ✅ DEFAULT VALUE (NO ERRORS)
  });

  /// ✅ INITIALS (SAFE)
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return parts[0][0] + parts[1][0];
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1);
  }
}
