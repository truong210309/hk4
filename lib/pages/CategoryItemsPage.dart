import 'package:flutter/material.dart';
import 'package:fe/pages/Auction_ItemsDetailPage.dart';
import 'package:fe/models/Category.dart';
import 'package:fe/models/Auction_Items.dart';
import 'package:fe/services/ApiCategoryService.dart';
import 'package:fe/services/ApiAuction_ItemsService.dart';
import 'package:fe/pages/Auction_ItemsPage.dart';
import 'package:fe/pages/CategoryItemSearchPage.dart';

import '../models/Auction.dart';
import 'HomePage.dart';

class CategoryItemPage extends StatefulWidget {
  const CategoryItemPage({super.key});

  @override
  State<StatefulWidget> createState() => _CategoryItemPageState();
}

class _CategoryItemPageState extends State<CategoryItemPage> {
  final ApiCategoryService apiService = ApiCategoryService();
  final ApiAuction_ItemsService auctionService = ApiAuction_ItemsService();
  late Future<List<Category>> futureCategories;
  late Future<List<Auction>> futureAuctionItems;
  late Future<List<Auction>> futureAuction;
  @override
  void initState() {
    super.initState();
    futureCategories = apiService.getAllCategory();

    futureAuctionItems = auctionService.getAllAuctionItems();

    futureAuction = auctionService.getAllAuction();
    // futureAuction.then((items) {
    //   print("📡 Fetched Auction Items: ${items.length} items"); // 🔥 Log số lượng item
    //   for (var item in items) {
    //     print("🔍 Item ID:  $item");
    //   }
    // }).catchError((error) {
    //   print("🚨 Error fetching auction items: $error");
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,  // Set background color of the whole page to white
      appBar: AppBar(
        title: const Text('LIVEACCTIONEERS'),
        backgroundColor: Colors.white,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryItemSearchPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                height: 45.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 10),
                    Text(
                      'Search items',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Line under search bar
          const Divider(thickness: 1.0, color: Colors.grey),  // This adds a line under the search bar
          Expanded(
            child: FutureBuilder<List<Category>>(
              future: futureCategories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No categories found.'));
                }

                List<Category> categories = snapshot.data!;

                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<List<Auction>>(
                      future: futureAuction,

                      builder: (context, itemSnapshot) {
                        if (itemSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (itemSnapshot.hasError) {
                          return Center(child: Text('Error: ${itemSnapshot.error}'));
                        }

                        // List<AuctionItems> auctionItems = itemSnapshot.data!
                        //     .where((item) => item.category?.category_id == categories[index].category_id)
                        //     .toList();
                        List<Auction> auctionItems = itemSnapshot.data!
                            .where((item) => item.category?.category_id == categories[index].category_id)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    categories[index].category_name ?? '',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Auction_ItemsPage(
                                            category: categories[index],
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('See All'),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 250,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: auctionItems.length,
                                itemBuilder: (context, itemIndex) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Homepage(initialIndex: 0, selectedItem: auctionItems[itemIndex]), // 🔥 Mở trong HomePage

                                        ),
                                      );
                                    },

                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(15),
                                            child: Image.network(
                                              // auctionItems[itemIndex].images?.isNotEmpty ?? false
                                              //     ? auctionItems[itemIndex].images!.first
                                              auctionItems[itemIndex].imagesList?.isNotEmpty ?? false
                                                  ? auctionItems[itemIndex].imagesList!.first
                                                  : 'https://via.placeholder.com/150',
                                              width: 150,
                                              height: 150,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              auctionItems[itemIndex].itemName ?? 'No Name',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
