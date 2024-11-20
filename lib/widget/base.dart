import 'package:flutter/material.dart';
import 'package:foroshgahman_application/page/home.dart';
import 'package:foroshgahman_application/page/search.dart';
import 'package:foroshgahman_application/page/profile.dart';

class BaseWidget extends StatefulWidget {
  final Widget child; // Content of the specific page
  final int currentIndex; // Index of the selected tab

  const BaseWidget(
      {super.key, required this.child, required this.currentIndex});

  @override
  // ignore: library_private_types_in_public_api
  _BaseWidgetState createState() => _BaseWidgetState();
}

class _BaseWidgetState extends State<BaseWidget> {
  void _onTabTapped(int index) {
    // Navigate to the selected page
    if (index != widget.currentIndex) {
      switch (index) {
        case 0: // Open home page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
          break;

        case 1: // Open search page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchPage()),
          );
          break;

        case 2: // Open profile page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'خانه',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'جستجو',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'پروفایل',
          ),
        ],
      ),
    );
  }
}
