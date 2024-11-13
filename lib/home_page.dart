import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> newest_shops = [
      {"name": "فروشگاه اول", "address": "تهران، خیابان ولیعصر", "rating": 4.5},
      {
        "name": "فروشگاه دوم",
        "address": "اصفهان، میدان نقش جهان",
        "rating": 4.0
      },
      {"name": "فروشگاه سوم", "address": "شیراز، خیابان زند", "rating": 5.0},
      {
        "name": "فروشگاه چهارم",
        "address": "مشهد، خیابان امام رضا",
        "rating": 3.5
      },
      {"name": "فروشگاه پنجم", "address": "تبریز، خیابان امام", "rating": 4.2},
      {
        "name": "فروشگاه ششم",
        "address": "کرج، بلوار شهید بهشتی",
        "rating": 3.8
      },
      {"name": "فروشگاه هفتم", "address": "قم، خیابان صفاییه", "rating": 4.7},
      {"name": "فروشگاه هشتم", "address": "رشت، خیابان مطهری", "rating": 4.3},
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        // title: const Text('خانه'),
        // centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "جدیدترین ها",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: newest_shops.length,
                itemBuilder: (context, index) {
                  final shop = newest_shops[index];
                  return ShopCard(
                    name: shop["name"]!,
                    address: shop["address"]!,
                    rating: shop["rating"]!,
                  );
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
            // Gray Box to replace the image with increased height
            Container(
              height: 180, // Increased height for the gray box
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),

            // Shop Name centered
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Row with Rating on the right and Address on the left
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Address on the right side
                Text(
                  address,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.right,
                ),

                // Rating with Star Icon on the left side
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
