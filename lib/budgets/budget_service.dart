<<<<<<< HEAD
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Get the current user ID safely
  String? get userId => _auth.currentUser?.uid;

  // 2. Stream of Budgets - This powers your "Budget List"
  Stream<QuerySnapshot> getBudgetsStream() {
    if (userId == null) {
      // Returns an empty stream if not logged in to avoid permission errors
      return const Stream.empty();
    }
    
    return _db
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // 3. Add a new budget category
  Future<void> addBudget(String category, double amount) async {
    if (userId == null) throw Exception("User not logged in");

    await _db.collection('budgets').add({
      'userId': userId,
      'category': category,
      'budgetAmount': amount,
      'spentAmount': 0.0, // Initial spend is zero
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 4. Update spending when an expense is added
  // This ensures your "Budget List" bars move!
  Future<void> updateBudgetSpend(String category, double newExpenseAmount) async {
    final query = await _db
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .get();

    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      final currentSpent = query.docs.first['spentAmount'] ?? 0.0;
      
      await _db.collection('budgets').doc(docId).update({
        'spentAmount': currentSpent + newExpenseAmount,
      });
    }
  }
=======
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Get the current user ID safely
  String? get userId => _auth.currentUser?.uid;

  // 2. Stream of Budgets - This powers your "Budget List"
  Stream<QuerySnapshot> getBudgetsStream() {
    if (userId == null) {
      // Returns an empty stream if not logged in to avoid permission errors
      return const Stream.empty();
    }
    
    return _db
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // 3. Add a new budget category
  Future<void> addBudget(String category, double amount) async {
    if (userId == null) throw Exception("User not logged in");

    await _db.collection('budgets').add({
      'userId': userId,
      'category': category,
      'budgetAmount': amount,
      'spentAmount': 0.0, // Initial spend is zero
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 4. Update spending when an expense is added
  // This ensures your "Budget List" bars move!
  Future<void> updateBudgetSpend(String category, double newExpenseAmount) async {
    final query = await _db
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .get();

    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      final currentSpent = query.docs.first['spentAmount'] ?? 0.0;
      
      await _db.collection('budgets').doc(docId).update({
        'spentAmount': currentSpent + newExpenseAmount,
      });
    }
  }
>>>>>>> ca32774 (	new file:   lib/account_dashboard/account_dashboard.dart)
}