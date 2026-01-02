import 'package:cloud_firestore/cloud_firestore.dart';

class AlertService {
  static Stream<QuerySnapshot> getAlerts(String userId) {
    // Queries budgets where 'spent' is greater than 'amount'
    return FirebaseFirestore.instance
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }
}