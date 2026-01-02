import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Dapatkan User ID dengan selamat
  String? get userId => _auth.currentUser?.uid;

  // 2. Stream Bajet - Untuk paparan senarai bajet yang sentiasa dikemaskini
  Stream<QuerySnapshot> getBudgetsStream() {
    if (userId == null) {
      return const Stream.empty();
    }
    
    return _db
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // 3. Tambah kategori bajet baru
  Future<void> addBudget(String category, double amount) async {
    if (userId == null) throw Exception("User not logged in");

    await _db.collection('budgets').add({
      'userId': userId,
      'category': category,
      'amount': amount, // Menggunakan nama field 'amount' supaya selari dengan screen lain
      'spent': 0.0,      // Perbelanjaan bermula dengan sifar
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 4. Kemaskini perbelanjaan apabila transaksi baru ditambah
  Future<void> updateBudgetSpend(String category, double newExpenseAmount) async {
    if (userId == null) return;

    final query = await _db
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .get();

    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      final currentSpent = (query.docs.first['spent'] as num? ?? 0.0).toDouble();
      
      await _db.collection('budgets').doc(docId).update({
        'spent': currentSpent + newExpenseAmount,
      });
    }
  }
}