import 'package:fe/pages/Auction_ItemsDetailPage.dart';
import 'package:fe/models/Category.dart';
import 'package:fe/models/Auction_Items.dart';
import 'package:fe/services/ApiCategoryService.dart';
import 'package:fe/services/ApiAuction_ItemsService.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/Auction.dart';
import 'HomePage.dart';

class CategoryItemSearchPage extends StatefulWidget {
  const CategoryItemSearchPage({super.key});

  @override
  State<StatefulWidget> createState() => _CategoryItemSearchPageState();
}

class _CategoryItemSearchPageState extends State<CategoryItemSearchPage> {
  final ApiCategoryService apiService = ApiCategoryService();
  final ApiAuction_ItemsService auctionService = ApiAuction_ItemsService();
  late Future<List<Category>> futureCategories;
  late Future<List<Auction>> futureAuctionItems;
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();
  List<String> _recentSearches = [];
  List<Auction> _filteredItems = [];
  List<Auction> _allItems = [];
  bool _showRecentSearches = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    futureCategories = apiService.getAllCategory();
    futureAuctionItems = auctionService.getAllAuction();
    _loadRecentSearches();

    futureAuctionItems.then((items) {
      setState(() {
        _allItems = items;
      });
    });

    _searchController.addListener(() {
      String query = _searchController.text.trim();
      setState(() {
        if (query.isEmpty) {
          _showRecentSearches = true;  // Show recent searches again
          _showSuggestions = false;    // Hide item suggestions
          _filteredItems.clear();      // Clear search results
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
      await prefs.setStringList('recent_searches', _recentSearches);
    }
  }

  void _removeRecentSearch(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.remove(query);
    });
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  void _performSearch() {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;
    _saveRecentSearch(query);

    setState(() {
      _filteredItems = _allItems
          .where((item) => item.itemName != null &&
          item.itemName!.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _showRecentSearches = false;
      _showSuggestions = false;
    });
  }

  void _updateSuggestions(String query) {
    setState(() {
      if (query.isEmpty) {
        _showRecentSearches = true;
        _showSuggestions = false;
        _filteredItems.clear();
      } else {
        _filteredItems = _allItems
            .where((item) => item.itemName != null &&
            item.itemName!.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _showRecentSearches = false;
        _showSuggestions = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,  // Set the background color of the Scaffold to white
      appBar: AppBar(
        backgroundColor: Colors.white,  // Set the AppBar background to white
        title: Padding(
          padding: const EdgeInsets.all(8.0), // Add padding to match CategoryItemPage
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showRecentSearches = true; // Show recent searches when tapped
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              height: 45.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search items...',
                        border: InputBorder.none,
                        isDense: true, // Makes the search field more compact
                      ),
                      onChanged: _updateSuggestions,
                      onTap: () => setState(() => _showRecentSearches = _searchController.text.isEmpty),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey), // Clear button on the right
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _filteredItems.clear();
                        _showRecentSearches = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_showRecentSearches && _recentSearches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _recentSearches.map((search) {
                  return ListTile(
                    title: Text(search),
                    leading: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => _removeRecentSearch(search),
                    ),
                    onTap: () {
                      _searchController.text = search;
                      _performSearch();
                    },
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text('No items found.'))
                : ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  leading: Image.network(
                    item.imagesList?.isNotEmpty ?? false
                        ? item.imagesList!.first
                        : 'https://via.placeholder.com/150',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(item.itemName ?? 'No Name'),
                  subtitle: Text(item.description ?? ''),
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => Homepage(initialIndex: 0, selectedItem: item), // 🔥 Mở trong HomePage
                    //   ),
                    // );
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
