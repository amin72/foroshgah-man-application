import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

class ShopDetailsPage extends StatefulWidget {
  final String shopId;

  const ShopDetailsPage({super.key, required this.shopId});

  @override
  _ShopDetailsPageState createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  Map<String, dynamic>? shopDetails;

  @override
  void initState() {
    super.initState();
    _fetchShopDetails();
  }

  Future<void> _fetchShopDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url =
        Uri.parse('http://localhost:8101/v1/shop/${widget.shopId}/details');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      setState(() {
        shopDetails = json.decode(utf8.decode(response.bodyBytes));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('بارگیری اطلاعات فروشگاه با شکست مواجه شد.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("جزئیات فروشگاه")),
      body: shopDetails == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Placeholder for shop image
                  Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: Text('تصویر فروشگاه')),
                  ),

                  const SizedBox(height: 16),

                  // Shop name
                  Text(
                    shopDetails!['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Shop address
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            "آدرس: ${shopDetails!['address'] ?? 'نامشخص'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            "امتیاز: ${shopDetails!['rating'] ?? 'نامشخص'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Mobile number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_android, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            "شماره تماس: ${shopDetails!['mobile'] ?? 'نامشخص'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Is Physical
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            "فروشگاه حضوری: ${shopDetails!['is_physical'] ? 'بله' : 'خیر'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.category, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(
                            "دسته‌بندی: ${shopDetails!['category'] ?? 'نامشخص'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Joined date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.deepOrange),
                          const SizedBox(width: 4),
                          Text(
                            "تاریخ پیوستن: ${_formatDate(shopDetails!['created_at'])}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10), // Add more spacing

                  // Description Section
                  const Divider(thickness: 1), // Divider for clarity
                  const SizedBox(height: 16),
                  const Text(
                    "توضیحات",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shopDetails!['description'] ?? 'نامشخص',
                    style: const TextStyle(fontSize: 16, height: 1.8),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30), // Add more spacing at the bottom
                ],
              ),
            ),
    );
  }

  // Function to format the DateTime as year/month/day
  String _formatDate(String? date) {
    if (date == null) return 'نامشخص';

    try {
      final DateTime parsedDate = DateTime.parse(date);

      Jalali j = Jalali.fromDateTime(parsedDate);

      return '${j.day}-${j.month}-${j.year}';
    } catch (e) {
      return 'نامشخص';
    }
  }
}
