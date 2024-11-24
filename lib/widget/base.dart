import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foroshgahman_application/page/home.dart';
import 'package:foroshgahman_application/page/search.dart';
import 'package:foroshgahman_application/page/profile.dart';
import 'package:foroshgahman_application/page/login.dart';

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

  Future<void> _confirmSignOut() async {
    final bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأیید خروج'),
          content: const Text('آیا مطمئن هستید که می‌خواهید خارج شوید؟'),
          actions: [
            TextButton(
              child: const Text('لغو'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('خروج'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed) {
      _signOut();
    }
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    final url = Uri.parse('http://localhost:8100/v1/otp/revoke-refresh-token');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Logout successful
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        // Handle server error
        final errorMessage =
            json.decode(response.body)['message'] ?? 'خطایی رخ داد';
        _showErrorSnackbar(errorMessage);
      }
    } catch (error) {
      // Handle network error
      _showErrorSnackbar('مشکلی در ارتباط با سرور وجود دارد.');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateTo(String route) {
    Navigator.pop(context); // Close the drawer
    if (route == 'خروج') {
      _confirmSignOut();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigating to $route')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فروشگاه من'),
      ),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'منوی اصلی',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('پروفایل'),
              onTap: () => _navigateTo('پروفایل'),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('چت‌ها'),
              onTap: () => _navigateTo('چت‌ها'),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('موارد دلخواه'),
              onTap: () => _navigateTo('موارد دلخواه'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('خروج'),
              onTap: () => _navigateTo('خروج'),
            ),
          ],
        ),
      ),
    );
  }
}
