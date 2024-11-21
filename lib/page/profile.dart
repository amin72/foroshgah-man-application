import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:foroshgahman_application/widget/base.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foroshgahman_application/data/province.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditing = false;
  int? selectedProvinceCode; // Tracks the selected province's code

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

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
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          userData = data;
          selectedProvinceCode = data['province_code'];
          _populateControllers();
          isLoading = false;
        });
      } else {
        _showError();
      }
    } catch (e) {
      _showError();
    }
  }

  void _populateControllers() {
    _firstNameController.text = userData?['first_name'] ?? '';
    _lastNameController.text = userData?['last_name'] ?? '';
    _cityController.text = userData?['city'] ?? '';
    _addressController.text = userData?['address'] ?? '';
  }

  Future<void> _updateUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = Uri.parse('http://localhost:8100/v1/user/info/');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // Prepare the fields for updating, keeping unchanged fields the same as before
      final Map<String, dynamic> updatedFields = {};

      updatedFields['first_name'] = _firstNameController.text.trim().isEmpty
          ? userData!['first_name']
          : _firstNameController.text.trim();
      updatedFields['last_name'] = _lastNameController.text.trim().isEmpty
          ? userData!['last_name']
          : _lastNameController.text.trim();
      updatedFields['province_code'] =
          selectedProvinceCode ?? userData!['province_code'];
      updatedFields['city'] = _cityController.text.trim().isEmpty
          ? userData!['city']
          : _cityController.text.trim();
      updatedFields['address'] = _addressController.text.trim().isEmpty
          ? userData!['address']
          : _addressController.text.trim();

      // Send only updated fields to avoid erasing unchanged ones
      final response = await http.patch(
        url,
        headers: headers,
        body: json.encode(updatedFields),
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = {...userData!, ...updatedFields};
          isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اطلاعات با موفقیت بروزرسانی شد')),
        );
      } else {
        _showError();
      }
    } catch (e) {
      _showError();
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('خطا در برقراری ارتباط با سرور')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseWidget(
      currentIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پروفایل کاربری'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildEditableField(
                              'نام', _firstNameController, isEditing),
                          _buildEditableField(
                              'نام خانوادگی', _lastNameController, isEditing),
                          _buildProfileCard(
                              'شماره موبایل', _getValue(userData!['mobile'])),
                          _buildProfileCard(
                              'وضعیت پروفایل',
                              userData!['profile_status'] == "shop_owner"
                                  ? 'صاحب فروشگاه'
                                  : 'کاربر عادی'),
                          _buildProvinceDropdown(),
                          _buildEditableField(
                              'شهر', _cityController, isEditing),
                          _buildEditableField(
                              'آدرس', _addressController, isEditing),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (isEditing) {
                            _updateUserInfo();
                          } else {
                            setState(() {
                              isEditing = true;
                            });
                          }
                        },
                        child: Text(
                          isEditing ? 'ارسال' : 'ویرایش',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEditableField(
      String label, TextEditingController controller, bool isEditable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isEditable
            ? TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(10.0),
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
              )
            : Row(
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
                      controller.text.isNotEmpty ? controller.text : '---',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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

  Widget _buildProvinceDropdown() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isEditing
            ? DropdownButton<int>(
                value: selectedProvinceCode,
                isExpanded: true,
                hint: const Text('انتخاب استان'),
                items: provinces.map((province) {
                  return DropdownMenuItem<int>(
                    value: province['code'],
                    child: Text(province['name']),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    selectedProvinceCode = value;
                  });
                },
              )
            : Row(
                children: [
                  const Text(
                    'استان:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getProvinceName(selectedProvinceCode) ?? '---',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String? _getProvinceName(int? code) {
    if (code == null) return null;

    final province = provinces.firstWhere(
      (p) => p['code'] == code,
      orElse: () => {'name': null}, // Return a dummy Map
    );

    return province['name'];
  }

  String _getValue(String? value) {
    return (value == null || value.trim().isEmpty) ? '---' : value;
  }
}
