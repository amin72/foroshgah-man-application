import 'package:flutter/material.dart';
import 'package:foroshgahman_application/home_page.dart';
import 'package:foroshgahman_application/search_page.dart';

class BasePage extends StatefulWidget {
  final Widget child; // Content of the specific page
  final int currentIndex; // Index of the selected tab

  const BasePage({super.key, required this.child, required this.currentIndex});

  @override
  // ignore: library_private_types_in_public_api
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
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
          Navigator.pushReplacementNamed(context, '/profile');
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
