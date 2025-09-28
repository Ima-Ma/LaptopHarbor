import 'package:flutter/material.dart';

class MyBottomBar extends StatelessWidget {
  final int currentIndex;

  const MyBottomBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/MainHome');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/TrackingOrder');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/Replacement');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/SupportRequests');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/exploreproduct');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
      child: PhysicalModel(
        color: Colors.white,
        elevation: 12,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => _onItemTapped(context, index),
            selectedItemColor: const Color(0xFF539b69),
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            showSelectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF539b69),
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.grey,
            ),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Track'),
              BottomNavigationBarItem(icon: Icon(Icons.policy), label: 'Replace'),
              BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Support'),
              BottomNavigationBarItem(icon: Icon(Icons.laptop), label: 'Explore'),
            ],
          ),
        ),
      ),
    );
  }
}
