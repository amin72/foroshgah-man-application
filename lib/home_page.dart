import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foroshgahman_application/shop_details.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'base_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _shopsFuture = _checkTokenAndFetchShops();
  }

  Future<List<Map<String, dynamic>>> _checkTokenAndFetchShops() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    // Redirect to login if no token is found
    if (token == '') {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('User not logged in');
      }
    }

    // Token exists, fetch shops
    return fetchShops(token);
  }

  Future<List<Map<String, dynamic>>> fetchShops(String token) async {
    final url = Uri.parse('http://localhost:8101/v1/shop/home');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));

        final List<dynamic> newestShops = data['newest'] ?? [];

        return newestShops
            .map((shop) => {
                  "id": shop["id"],
                  "name": shop["name"] ?? "نامشخص",
                  "address": shop["address"] ?? "آدرس موجود نیست",
                  "rating": shop["rating"]?.toDouble() ?? 0.0,
                })
            .toList();
      } else if (response.statusCode == 401) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          throw Exception('Unauthorized');
        }
      } else {
        throw Exception('Failed to load shops');
      }
    } catch (error) {
      throw Exception('Error fetching shops: $error');
    }

    throw Exception('Token is null. Cannot fetch shops.');
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 0, // Index for "Home" in BottomNavigationBar
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "جدیدترین ها",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 5.0,
                    color: Colors.grey,
                    offset: Offset(1.5, 1.5),
                  ),
                ],
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _shopsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No shops available.'));
                  } else {
                    final shops = snapshot.data!;
                    return ListView.builder(
                      itemCount: shops.length,
                      itemBuilder: (context, index) {
                        final shop = shops[index];

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ShopDetailsPage(shopId: shop["id"]),
                              ),
                            );
                          },
                          child: ShopCard(
                            name: shop["name"]!,
                            address: shop["address"]!,
                            rating: shop["rating"]!,
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopCard extends StatelessWidget {
  final String name;
  final String address;
  final double rating;

  const ShopCard(
      {super.key,
      required this.name,
      required this.address,
      required this.rating});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      address,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
