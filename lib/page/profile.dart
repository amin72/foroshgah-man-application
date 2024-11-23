import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/city.dart'; // Ensure this file contains the cities list
import '../data/province.dart'; // Ensure this file contains the provinces list
import '../widget/base.dart'; // Ensure BaseWidget is properly defined

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditing = false;
  int? selectedProvinceCode;
  int? selectedCityCode;
  List<Map<String, dynamic>> filteredCities = [];

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  void _populateControllers() {
    _firstNameController.text = userData?['first_name'] ?? '';
    _lastNameController.text = userData?['last_name'] ?? '';
    _addressController.text = userData?['address'] ?? '';
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('خطا در برقراری ارتباط با سرور')),
    );
  }

  String _getValue(dynamic value) {
    return value != null && value.toString().isNotEmpty
        ? value.toString()
        : '---';
  }

  @override
  Widget build(BuildContext context) {
    return BaseWidget(
      currentIndex: 2,
      child: isLoading
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
                        if (!isEditing)
                          _buildProfileCard(
                              'شماره موبایل', _getValue(userData!['mobile'])),
                        if (!isEditing)
                          _buildProfileCard(
                              'وضعیت پروفایل',
                              userData!['profile_status'] == "shop_owner"
                                  ? 'صاحب فروشگاه'
                                  : 'کاربر عادی'),
                        _buildProvinceField(),
                        _buildCityField(),
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
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEditableField(
      String label, TextEditingController controller, bool isEditable) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isEditable
            ? TextField(
                controller: controller,
                decoration: InputDecoration(labelText: label),
              )
            : Row(
                children: [
                  Text('$label:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        controller.text.isNotEmpty ? controller.text : '---'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Text('$label:'),
            const SizedBox(width: 8),
            Expanded(child: Text(value)),
          ],
        ),
      ),
    );
  }

  Widget _buildProvinceField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isEditing
            ? DropdownButtonFormField<int>(
                value: selectedProvinceCode,
                decoration: const InputDecoration(labelText: 'استان'),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedProvinceCode = newValue;
                    _filterCities(selectedProvinceCode);
                    selectedCityCode = null;
                  });
                },
                items: provinces.map((province) {
                  return DropdownMenuItem<int>(
                    value: province['code'],
                    child: Text(province['name']),
                  );
                }).toList(),
              )
            : Row(
                children: [
                  const Text('استان:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provinces
                          .firstWhere(
                            (province) =>
                                province['code'] == selectedProvinceCode,
                            orElse: () => {'name': 'نامشخص'},
                          )['name']
                          .toString(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCityField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isEditing
            ? DropdownButtonFormField<int>(
                value: selectedCityCode,
                decoration: const InputDecoration(labelText: 'شهر'),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedCityCode = newValue;
                  });
                },
                items: filteredCities.map((city) {
                  return DropdownMenuItem<int>(
                    value: city['city_code'],
                    child: Text(city['name']),
                  );
                }).toList(),
              )
            : Row(
                children: [
                  const Text('شهر:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filteredCities
                          .firstWhere(
                            (city) => city['city_code'] == selectedCityCode,
                            orElse: () => {'name': 'نامشخص'},
                          )['name']
                          .toString(),
                    ),
                  ),
                ],
              ),
      ),
    );
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

          // Set the selected province and city codes
          selectedProvinceCode = data['province_code'];
          selectedCityCode = data['city_code'];

          // Populate the controllers with user data
          _populateControllers();
          isLoading = false;
          _filterCities(selectedProvinceCode);
        });
      } else {
        _showError();
      }
    } catch (e) {
      _showError();
    }
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

      final Map<String, dynamic> updatedFields = {};

      updatedFields['first_name'] = _firstNameController.text.trim().isEmpty
          ? userData!['first_name']
          : _firstNameController.text.trim();
      updatedFields['last_name'] = _lastNameController.text.trim().isEmpty
          ? userData!['last_name']
          : _lastNameController.text.trim();

      // Send province_code directly
      updatedFields['province_code'] =
          selectedProvinceCode ?? userData!['province_code'];

      // Send city_code directly from selectedCityCode
      updatedFields['city_code'] = selectedCityCode ?? userData!['city_code'];

      updatedFields['address'] = _addressController.text.trim().isEmpty
          ? userData!['address']
          : _addressController.text.trim();

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

  void _filterCities(int? provinceCode) {
    setState(() {
      filteredCities = cities
          .where((city) => city['province_code'] == provinceCode)
          .toList();

      if (!filteredCities
          .any((city) => city['city_code'] == selectedCityCode)) {
        selectedCityCode = null;
      }
    });
  }
}
