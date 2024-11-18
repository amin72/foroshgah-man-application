import 'package:flutter/material.dart';

class BasePage extends StatefulWidget {
  final Widget child; // Content of the specific page
  final int currentIndex; // Index of the selected tab

  const BasePage({super.key, required this.child, required this.currentIndex});

  @override
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  void _onTabTapped(int index) {
    // Navigate to the selected page
    if (index != widget.currentIndex) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/home');
          break;
        // case 1:
        //   Navigator.pushReplacementNamed(context, '/search');
        //   break;
        // case 2:
        //   Navigator.pushReplacementNamed(context, '/profile');
        //   break;
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
