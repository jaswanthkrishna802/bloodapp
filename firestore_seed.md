# Firestore Collection Structure & Seed Data

## Collections

### users/
```
{
  id: "auto",
  name: "Arjun Sharma",
  phone: "+91 98765 43210",
  email: "arjun@email.com",
  bloodGroup: "O+",
  location: "Vellore, Tamil Nadu",
  role: "donor",            // donor | patient | hospital | admin
  isAvailable: true,
  totalDonations: 12,
  rating: 4.9,
  lastDonated: "15 Jan 2025",
  age: 28,
  gender: "Male",
  latitude: 12.9165,
  longitude: 79.1325,
  fcmToken: "device_token_here",
  createdAt: timestamp
}
```

### blood_requests/
```
{
  id: "auto",
  patientName: "Meena Ravi",
  bloodGroup: "AB-",
  hospitalName: "CMC Hospital",
  hospitalLocation: "Vellore",
  unitsRequired: 3,
  urgency: 0,               // 0=critical 1=urgent 2=normal
  status: 0,                // 0=pending 1=accepted 2=fulfilled 3=cancelled
  requestedBy: "userId",
  latitude: 12.9265,
  longitude: 79.1425,
  createdAt: timestamp
}
```

### blood_stock/
```
{
  id: "auto",
  city: "Vellore",
  bloodGroup: "O+",
  units: 450,
  status: "high",           // high | medium | critical
  updatedAt: timestamp
}
```

### hospitals/
```
{
  id: "auto",
  name: "CMC Hospital",
  city: "Vellore",
  units: 850,
  level: 0.85,
  latitude: 12.9265,
  longitude: 79.1425
}
```

### notifications/
```
{
  id: "auto",
  userId: "targetUserId",
  title: "CRITICAL: AB- Blood Needed",
  message: "CMC Hospital urgently needs AB- blood.",
  type: 0,                  // 0=urgent 1=success 2=info 3=warning
  isRead: false,
  createdAt: timestamp
}
```

## Firestore Indexes needed
Create composite indexes in Firebase Console:
1. blood_requests: status ASC + createdAt DESC
2. blood_requests: bloodGroup ASC + status ASC + createdAt DESC
3. blood_requests: requestedBy ASC + createdAt DESC
4. users: bloodGroup ASC + role ASC + isAvailable ASC + latitude ASC
5. notifications: userId ASC + createdAt DESC