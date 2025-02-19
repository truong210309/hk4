import 'package:flutter/material.dart';
import 'package:fe/models/Auction_Items.dart';
import 'package:fe/services/ApiAuction_ItemsService.dart';
import 'package:fe/models/Category.dart';
import 'package:fe/pages/Auction_ItemsDetailPage.dart';

import '../models/Auction.dart';
import 'HomePage.dart'; // Import the detail page

class Auction_ItemsPage extends StatefulWidget {
  final Category category;

  const Auction_ItemsPage({super.key, required this.category});

  @override
  State<StatefulWidget> createState() => _Auction_ItemsPageState();
}

class _Auction_ItemsPageState extends State<Auction_ItemsPage> {
  final ApiAuction_ItemsService apiService = ApiAuction_ItemsService();
  late Future<List<Auction>> futureAuctionItems;

  @override
  void initState() {
    super.initState();
    futureAuctionItems = apiService.getAllAuction();

  }

  Widget buildAuctionItemCard(Auction item) {
    String imageUrl = item.imagesList?.isNotEmpty ?? false ? item.imagesList!.first : 'https://via.placeholder.com/150';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Auction_ItemsDetailPage(item: item), // Mở trang chi tiết đúng
          ),
        );

      },


      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // Set card background color to white
        ),
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 150,  // Adjust height to fit in the grid
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network('https://via.placeholder.com/150', width: double.infinity, height: 150, fit: BoxFit.cover);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item.itemName ?? 'No Name',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Price: \$${item.startingPrice ?? 0}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('End Date: ${item.endDate ?? 'No End Date'}'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Items in ${widget.category.category_name}'),
        backgroundColor: Colors.white,
        elevation: 0,  // Optional, removes shadow under the app bar
      ),
      backgroundColor: Colors.white,  // Set the background color of the entire screen
      body: FutureBuilder<List<Auction>>(
        future: futureAuctionItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Loading auction items...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items found.'));
          }

          List<Auction> auctionItems = snapshot.data!;
          List<Auction> filteredItems = auctionItems
              .where((item) => item.category?.category_id == widget.category.category_id)
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                futureAuctionItems = apiService.getAllAuction();
              });
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,  // This makes two items per row
                crossAxisSpacing: 8,  // Space between columns
                mainAxisSpacing: 8,   // Space between rows
                childAspectRatio: 0.7,  // Adjust to get proper size for each item
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return buildAuctionItemCard(filteredItems[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
