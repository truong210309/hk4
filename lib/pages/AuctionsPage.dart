import 'package:flutter/material.dart';

import '../models/Auction.dart';
import '../models/Auction_Items.dart';
import '../services/ApiAuction_ItemsService.dart';
import 'Auction_ItemsDetailPage.dart';

class AuctionsPage extends StatefulWidget {
  const AuctionsPage({super.key});

  @override
  State<AuctionsPage> createState() => _AuctionsPageState();
}

class _AuctionsPageState extends State<AuctionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<List<Auction>> _featuredItems = Future.value([]);
  Future<List<Auction>> _upcomingItems = Future.value([]);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length:2 , vsync: this);
    _featuredItems = ApiAuction_ItemsService().fetchFeaturedAuctions();
    _upcomingItems = ApiAuction_ItemsService().fetchUpcomingAuctions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Auctions', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Featured'),
            Tab(text: 'Upcoming'),

          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAuctionList(_featuredItems),
          _buildAuctionList(_upcomingItems),

        ],
      ),
    );
  }

  Widget _buildAuctionList(Future<List<Auction>> futureItems) {
    return FutureBuilder<List<Auction>>(
      future: futureItems,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No auctions available"));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return _buildAuctionCard(item);
            },
          );
        }
      },
    );
  }

  Widget _buildAuctionCard(Auction item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Auction_ItemsDetailPage(item: item),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imagesList != null && item.imagesList!.isNotEmpty)
              Image.network(
                item.imagesList![0],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(item.itemName ?? "No Title",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.description ?? "No Description", style: const TextStyle(color: Colors.black)),

                    Text("Start: ${item.startDate}", style: const TextStyle(color: Colors.black)),
                    Text("End: ${item.endDate}", style: const TextStyle(color: Colors.black)),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Auction_ItemsDetailPage(item: item),
                      ),
                    );
                  },
                  child: const Text('Bid Now', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
