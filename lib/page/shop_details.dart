import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:foroshgahman_application/page/product_details.dart';
import 'package:foroshgahman_application/widget/base.dart';

class ShopDetailsPage extends StatefulWidget {
  final String shopId;

  const ShopDetailsPage({super.key, required this.shopId});

  @override
  // ignore: library_private_types_in_public_api
  _ShopDetailsPageState createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? shopDetails;
  late TabController _tabController;
  late ScrollController _scrollController;
  List<dynamic> products = [];
  bool isLoadingProducts = false;
  bool allProductsLoaded = false;
  int productPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchShopDetails();
    _fetchProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoadingProducts &&
        !allProductsLoaded) {
      _fetchProducts();
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('بارگیری اطلاعات فروشگاه با شکست مواجه شد.')),
        );
      }
    }
  }

  Future<void> _fetchProducts() async {
    if (isLoadingProducts || allProductsLoaded) return;

    setState(() {
      isLoadingProducts = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = Uri.parse(
        'http://localhost:8101/v1/shop/${widget.shopId}/products?page=$productPage&size=20');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      List<dynamic> newProducts =
          json.decode(utf8.decode(response.bodyBytes))['items'];

      setState(() {
        if (newProducts.isEmpty) {
          allProductsLoaded = true;
        } else {
          products.addAll(newProducts);
          productPage++;
        }
        isLoadingProducts = false;
      });
    } else {
      setState(() {
        isLoadingProducts = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بارگیری محصولات با شکست مواجه شد.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseWidget(
      currentIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("جزئیات فروشگاه"),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "جزئیات"),
              Tab(text: "محصولات"),
            ],
          ),
        ),
        body: shopDetails == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildShopDetailsTab(),
                  _buildProductsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildShopDetailsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Text('تصویر فروشگاه')),
          ),
          const SizedBox(height: 16),
          Text(
            shopDetails!['name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildDetailRow(
              Icons.location_on, Colors.green, "آدرس", shopDetails!['address']),
          const SizedBox(height: 10),
          _buildDetailRow(
              Icons.star, Colors.orange, "امتیاز", shopDetails!['rating']),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.phone_android, Colors.blue, "شماره تماس",
              shopDetails!['mobile']),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.storefront, Colors.purple, "فروشگاه حضوری",
              shopDetails!['is_physical'] ? 'بله' : 'خیر'),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.category, Colors.teal, "دسته‌بندی",
              shopDetails!['category']),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.calendar_today, Colors.deepOrange,
              "تاریخ پیوستن", _formatDate(shopDetails!['created_at'])),
          const SizedBox(height: 10),
          const Divider(thickness: 1),
          const SizedBox(height: 16),
          const Text(
            "توضیحات",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline),
          ),
          const SizedBox(height: 8),
          Text(shopDetails!['description'] ?? 'نامشخص',
              style: const TextStyle(fontSize: 16, height: 1.8),
              textAlign: TextAlign.justify),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, Color color, String label, dynamic value) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 4),
        Text("$label: ${value ?? 'نامشخص'}",
            style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildProductsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: products.length + (allProductsLoaded ? 0 : 1),
        itemBuilder: (context, index) {
          if (index == products.length) {
            return isLoadingProducts
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink();
          }

          final product = products[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(
                    productId: product['id'],
                  ),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey, size: 40),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'نامشخص',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "قیمت: ${product['price'] != null ? _formatPrice(product['price']) : 'نامشخص'}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "دسته‌بندی: ${product['category'] ?? 'نامشخص'}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatPrice(num price) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(price);
  }

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
