import 'package:flutter/material.dart';
import 'add_expense.dart'; 

class SharedNavigation extends StatelessWidget {
  const SharedNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(15),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The main pink navigation bar
          Container(
            height: 60,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.pinkAccent,
              borderRadius: BorderRadius.circular(35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_outlined, () {
                  // TODO: Add home navigation
                }),
                _navItem(Icons.bar_chart_outlined, () {
                  // TODO: Add list navigation
                }),
                // Space for the floating button
                const SizedBox(width: 50),
                _navItem(Icons.analytics_outlined, () {
                  // TODO: Add analytics navigation
                }),
                _navItem(Icons.person_outline, () {
                  // TODO: Add profile navigation
                }),
              ],
            ),
          ),
          
          // The floating central "Add" button
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                // NAVIGATION LOGIC
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddExpenseScreen(),
                  ),
                );
              },
              child: Container(
                height: 60,
                width: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD1DC), // Soft pink
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.add, 
                  color: Colors.white, 
                  size: 40
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to make icons interactive
  Widget _navItem(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}