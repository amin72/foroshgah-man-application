import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foroshgahman_application/widget/base.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = Uri.parse('http://localhost:8100/v1/user/info/');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      } else {
        _showError();
      }
    } catch (e) {
      _showError();
    }
  }

  void _showError() {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('خطا در دریافت اطلاعات کاربر')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseWidget(
      currentIndex: 2, // Set the active tab for the navigation bar
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پروفایل کاربری'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : userData != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileCard(
                            'نام', _getValue(userData!['first_name'])),
                        _buildProfileCard(
                            'نام خانوادگی', _getValue(userData!['last_name'])),
                        _buildProfileCard(
                            'شماره موبایل', _getValue(userData!['mobile'])),
                        _buildProfileCard(
                            'وضعیت پروفایل',
                            userData!['profile_status'] == "shop_owner"
                                ? 'صاحب فروشگاه'
                                : 'کاربر عادی'),
                        _buildProfileCard(
                            'استان', _getValue(userData!['province'])),
                        _buildProfileCard('شهر', _getValue(userData!['city'])),
                        _buildProfileCard(
                            'آدرس', _getValue(userData!['address'])),
                      ],
                    ),
                  )
                : const Center(
                    child: Text(
                      'اطلاعات کاربر در دسترس نیست',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getValue(String? value) {
    return (value == null || value.trim().isEmpty) ? '---' : value;
  }
}
