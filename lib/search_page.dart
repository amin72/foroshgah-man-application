import 'dart:async';
import 'dart:convert';
import 'package:foroshgahman_application/base_page.dart';
import 'package:intl/intl.dart';
import 'package:foroshgahman_application/product_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  ScrollController _scrollController = ScrollController();

  List<dynamic> products = [];
  bool isSearching = false;
  bool isLoadingMore = false;
  bool isLoadingProducts = false;
  bool hasMore = true;
  int currentPage = 1;
  bool allProductsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Attach a listener to detect scrolling near the bottom
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMore) {
        _loadMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Debounced Search Function
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length >= 2) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      isSearching = true;
      currentPage = 1; // Reset pagination
      hasMore = true; // Reset the "has more" flag
      products.clear(); // Clear previous results
    });

    await _fetchProducts(query, page: currentPage);

    setState(() {
      isSearching = false;
    });
  }

  Future<void> _fetchProducts(String query, {int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final productUrl = Uri.parse(
          'http://localhost:8101/v1/product/search?page=$page&q=$query');

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(productUrl, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes))['items'];

        setState(() {
          if (data.isEmpty) {
            hasMore = false; // No more data to load
          } else {
            products.addAll(data);
            // productResults.addAll(data.map((item) => item['name'].toString()));
          }
        });
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  void _loadMoreProducts() async {
    if (_searchController.text.length < 2) return;

    setState(() {
      isLoadingMore = true;
    });

    await _fetchProducts(_searchController.text, page: currentPage + 1);

    setState(() {
      currentPage += 1;
      isLoadingMore = false;
    });
  }

  void _handleError() {
    setState(() {
      isSearching = false;
      isLoadingMore = false;
      hasMore = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('خطا در برقراری ارتباط با سرور')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 1, // Search
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جستجو'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.shopping_bag), text: 'محصولات'),
              Tab(icon: Icon(Icons.store), text: 'فروشگاه‌ها'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  labelText: 'جستجو کنید...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Products Tab
                  _buildProductsTab(),
                  // Shops Tab (Placeholder for now)
                  const Center(
                    child: Text(
                      'در اینجا فروشگاه‌ها نمایش داده می‌شوند.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
}
