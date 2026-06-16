import "../models/donor_model.dart";
import "../models/blood_request_model.dart";
import "../models/notification_model.dart";
import "../models/user_model.dart";

class MockData {
  static final UserModel currentUser = UserModel(
    id: "u1", name: "Arjun Sharma", phone: "+91 98765 43210",
    email: "arjun@email.com", bloodGroup: "O+", location: "Vellore", city: "Vellore", state: "Tamil Nadu",
    role: "donor", totalDonations: 12, rating: 4.9,
    isAvailable: true, latitude: 12.9165, longitude: 79.1325,
  );

  static List<BloodRequestModel> get nearbyRequests => [
    BloodRequestModel(id: "r1", patientName: "Meena Ravi", bloodGroup: "AB-",
      hospitalName: "CMC Hospital", hospitalLocation: "Vellore",
      unitsRequired: 3, urgency: UrgencyLevel.critical,
      requestedBy: "u2", createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      distanceKm: 1.2, latitude: 12.9265, longitude: 79.1425),
    BloodRequestModel(id: "r2", patientName: "Suresh K", bloodGroup: "B+",
      hospitalName: "BLDEA Hospital", hospitalLocation: "Vellore",
      unitsRequired: 2, urgency: UrgencyLevel.urgent,
      requestedBy: "u3", createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      distanceKm: 3.5, latitude: 12.9065, longitude: 79.1225),
    BloodRequestModel(id: "r3", patientName: "Lakshmi D", bloodGroup: "A+",
      hospitalName: "District Hospital", hospitalLocation: "Katpadi",
      unitsRequired: 1, urgency: UrgencyLevel.normal,
      requestedBy: "u4", createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      distanceKm: 6.1, latitude: 12.8965, longitude: 79.1525),
  ];

  static List<DonorModel> nearbyDonors(String bloodGroup) => [
    DonorModel(id: "d1", name: "Rajesh Kumar", bloodGroup: bloodGroup,
      location: "Katpadi, Vellore", distanceKm: 1.2, isAvailable: true,
      totalDonations: 12, rating: 4.9, phone: "+91 99887 76655",
      lastDonated: "15 Jan 2025", age: 29, gender: "Male",
      latitude: 12.9265, longitude: 79.1425),
    DonorModel(id: "d2", name: "Sunita Venkatesh", bloodGroup: bloodGroup,
      location: "VIT Campus area", distanceKm: 2.1, isAvailable: true,
      totalDonations: 8, rating: 4.7, phone: "+91 88776 65544",
      lastDonated: "20 Nov 2024", age: 34, gender: "Female",
      latitude: 12.9365, longitude: 79.1325),
    DonorModel(id: "d3", name: "Arif Mohammed", bloodGroup: bloodGroup,
      location: "Sathuvachari", distanceKm: 3.4, isAvailable: false,
      totalDonations: 5, rating: 4.5, phone: "+91 77665 54433",
      lastDonated: "10 Dec 2024", age: 27, gender: "Male",
      latitude: 12.9065, longitude: 79.1525),
    DonorModel(id: "d4", name: "Priya Krishnamurthy", bloodGroup: bloodGroup,
      location: "Gandhi Nagar", distanceKm: 4.1, isAvailable: true,
      totalDonations: 7, rating: 4.8, phone: "+91 66554 43322",
      lastDonated: "05 Oct 2024", age: 31, gender: "Female",
      latitude: 12.8965, longitude: 79.1225),
    DonorModel(id: "d5", name: "Vijay Rajan", bloodGroup: bloodGroup,
      location: "Bagayam", distanceKm: 5.2, isAvailable: false,
      totalDonations: 3, rating: 4.3, phone: "+91 55443 32211",
      lastDonated: "22 Sep 2024", age: 24, gender: "Male",
      latitude: 12.9465, longitude: 79.1625),
    DonorModel(id: "d6", name: "Lakshmi Murugan", bloodGroup: bloodGroup,
      location: "Pillayarkuppam", distanceKm: 6.0, isAvailable: true,
      totalDonations: 15, rating: 5.0, phone: "+91 44332 21100",
      lastDonated: "01 Jan 2025", age: 38, gender: "Female",
      latitude: 12.8865, longitude: 79.1125),
  ];

  static List<Map<String, Object>> get bloodStockData => [
    {'group': 'A+',  'units': 320, 'status': 'high'},
    {'group': 'A-',  'units': 45,  'status': 'critical'},
    {'group': 'B+',  'units': 280, 'status': 'high'},
    {'group': 'B-',  'units': 30,  'status': 'critical'},
    {'group': 'O+',  'units': 450, 'status': 'high'},
    {'group': 'O-',  'units': 60,  'status': 'medium'},
    {'group': 'AB+', 'units': 180, 'status': 'medium'},
    {'group': 'AB-', 'units': 20,  'status': 'critical'},
  ];

  static List<NotificationModel> get notifications => [
    NotificationModel(id: "n1", title: "CRITICAL: AB- Blood Needed",
      message: "CMC Hospital urgently needs AB- blood. 3 units required. Patient is in ICU.",
      type: NotificationType.urgent,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2))),
    NotificationModel(id: "n2", title: "Donor Accepted Your Request",
      message: "Ravi Kumar (O+) has accepted your blood request. He will arrive at 11:30 AM.",
      type: NotificationType.success,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15))),
    NotificationModel(id: "n3", title: "Donation Reminder",
      message: "You are eligible to donate again from April 18. Schedule your next donation!",
      type: NotificationType.info,
      createdAt: DateTime.now().subtract(const Duration(hours: 2))),
    NotificationModel(id: "n4", title: "Donation Confirmed",
      message: "Thank you! Your donation at CMC Hospital has been confirmed. You saved a life!",
      type: NotificationType.success,
      createdAt: DateTime.now().subtract(const Duration(hours: 20))),
  ];

  static List<Map<String, Object>> get hospitalStocks => [
    {'name': 'CMC Hospital',       'units': 850, 'max': 1000, 'level': 0.85},
    {'name': 'BLDEA Hospital',     'units': 420, 'max': 1000, 'level': 0.42},
    {'name': 'District Hospital',  'units': 180, 'max': 1000, 'level': 0.18},
    {'name': 'Red Cross Blood Bank','units': 620, 'max': 1000, 'level': 0.62},
  ];
}
