import 'package:cloud_firestore/cloud_firestore.dart';

class AlertService {
  static Stream<QuerySnapshot> getAlerts(String userId) {
    // Mengambil data budget untuk diproses sebagai alert
    return FirebaseFirestore.instance
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }
}