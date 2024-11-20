import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foroshgahman_application/widget/base.dart';
import 'package:foroshgahman_application/page/shop_details.dart';
import 'package:foroshgahman_application/page/product_details.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  List<dynamic> products = [];
  List<dynamic> shops = [];
  bool isSearching = false;
  bool isLoadingMore = false;
  bool isLoadingProducts = false;
  bool isLoadingShops = false;
  bool hasMoreProducts = true;
  bool hasMoreShops = true;
  int currentPageProducts = 1;
  int currentPageShops = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Attach a listener to detect scrolling near the bottom
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore) {
        if (_tabController.index == 0 && hasMoreProducts) {
          _loadMoreProducts();
        } else if (_tabController.index == 1 && hasMoreShops) {
          _loadMoreShops();
        }
      }
    });

    // Add listener to detect tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final query = _searchController.text;
        if (query.isNotEmpty) {
          setState(() {
            isSearching = true; // Show loading icon
          });

          // Trigger the relevant API based on the active tab
          if (_tabController.index == 0) {
            _fetchProducts(query, page: currentPageProducts).then((_) {
              setState(() {
                isSearching = false; // Hide loading icon after data fetch
              });
            });
          } else if (_tabController.index == 1) {
            _fetchShops(query, page: currentPageShops).then((_) {
              setState(() {
                isSearching = false; // Hide loading icon after data fetch
              });
            });
          }
        }
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
      currentPageProducts = 1;
      currentPageShops = 1;
      hasMoreProducts = true;
      hasMoreShops = true;
      products.clear();
      shops.clear();
    });

    if (_tabController.index == 0) {
      await _fetchProducts(query, page: currentPageProducts);
    } else {
      await _fetchShops(query, page: currentPageShops);
    }

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
            hasMoreProducts = false;
          } else {
            products.addAll(data);
          }
        });
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  Future<void> _fetchShops(String query, {int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final shopUrl =
          Uri.parse('http://localhost:8101/v1/shop/search?page=$page&q=$query');

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(shopUrl, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes))['items'];

        setState(() {
          if (data.isEmpty) {
            hasMoreShops = false;
          } else {
            shops.addAll(data);
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

    await _fetchProducts(_searchController.text, page: currentPageProducts + 1);

    setState(() {
      currentPageProducts += 1;
      isLoadingMore = false;
    });
  }

  void _loadMoreShops() async {
    if (_searchController.text.length < 2) return;

    setState(() {
      isLoadingMore = true;
    });

    await _fetchShops(_searchController.text, page: currentPageShops + 1);

    setState(() {
      currentPageShops += 1;
      isLoadingMore = false;
    });
  }

  void _handleError() {
    setState(() {
      isSearching = false;
      isLoadingMore = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('خطا در برقراری ارتباط با سرور')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseWidget(
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
                  _buildProductsTab(),
                  _buildShopsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    if (isSearching) {
      // Show loading icon during data fetch
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: products.length,
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return const SizedBox.shrink();
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

  Widget _buildShopsTab() {
    if (isSearching) {
      // Show loading icon during data fetch
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: shops.length,
        itemBuilder: (context, index) {
          if (index >= shops.length) {
            return const SizedBox.shrink();
          }

          final shop = shops[index];
          return GestureDetector(
            onTap: () {
              // Navigate to the ShopDetailsPage when a shop is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShopDetailsPage(
                    shopId: shop['id'], // Pass shop ID or other identifier
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
                        child: Icon(Icons.store, color: Colors.grey, size: 40),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop['name'] ?? 'نامشخص',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "آدرس: ${shop['address'] ?? 'نامشخص'}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "دسته‌بندی: ${shop['category'] ?? 'نامشخص'}",
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
