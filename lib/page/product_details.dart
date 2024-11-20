import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:foroshgahman_application/widget/base.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  // ignore: library_private_types_in_public_api
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  List<String> productImages = [];
  String productName = 'بارگذاری...';
  String productPrice = 'بارگذاری...';
  String productDescription = 'لطفاً منتظر بمانید...';
  String productCategory = 'بارگذاری...';

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url =
        Uri.parse('http://localhost:8101/v1/product/${widget.productId}');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          productImages = List<String>.from(data['images'] ?? []);
          productName = data['name'] ?? 'نام محصول';
          productPrice =
              data['price'] != null ? '${data['price']} تومان' : 'نامشخص';
          productDescription =
              data['description'] ?? 'توضیحات محصول موجود نیست.';
          productCategory = data['category'] ?? 'بدون دسته بندی';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطا در بارگذاری اطلاعات محصول')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در برقراری ارتباط با سرور')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> carouselItems = productImages.isEmpty
        ? [_buildBlankImage(), _buildBlankImage(), _buildBlankImage()]
        : productImages
            .map((imageUrl) => _buildImageSliderItem(imageUrl))
            .toList();

    return BaseWidget(
        currentIndex: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (carouselItems.isNotEmpty)
                CarouselSlider(
                  options: CarouselOptions(
                    height: 250.0,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false,
                  ),
                  items: carouselItems,
                )
              else
                Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(child: Text('تصویری موجود نیست')),
                ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  productName,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "دسته بندی: $productCategory",
                style: const TextStyle(fontSize: 18, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                "قیمت: $productPrice",
                style: const TextStyle(fontSize: 20, color: Colors.green),
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              const SizedBox(height: 16),
              const Text(
                "توضیحات محصول",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                productDescription,
                style: const TextStyle(fontSize: 16, height: 1.8),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ));
  }

  Widget _buildBlankImage() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey, size: 40),
      ),
    );
  }

  Widget _buildImageSliderItem(String imageUrl) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
