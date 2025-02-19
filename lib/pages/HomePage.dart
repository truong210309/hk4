import 'package:fe/pages/ChatList.dart';
import 'package:fe/pages/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Auction.dart';
import '../models/Auction_Items.dart';
import '../models/Category.dart';
import 'Auction_ItemsDetailPage.dart';
import 'Auction_ItemsPage.dart';
import 'AuctionsPage.dart';
import 'CategoryItemsPage.dart';
import 'MyAuctionPage.dart';
import 'MyBidsPage.dart';

class Homepage extends StatefulWidget {
  final int initialIndex;
 // final AuctionItems? selectedItem; // 🔥 Thêm tham số này
  final Auction? selectedItem;
  const Homepage({super.key, this.initialIndex = 0, this.selectedItem});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late int _selectedIndex;
  // AuctionItems? _selectedItem;
  Auction? _selectedItem;
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _selectedItem = widget.selectedItem;
    _checkUserLoginStatus();
  }

  Future<void> _checkUserLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    if (token == null || userId == null) {
      print("🚨 Không tìm thấy token hoặc userId, quay về trang login!");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      print("✅ Đã tìm thấy token và userId, tiếp tục đăng nhập!");
    }
  }

  List<Widget> _getPages() {
    List<Widget> pages = [
      const CategoryItemPage(),
      const AuctionsPage(),
      const MyAuctionPage(
        userId: '',
      ),
      const MyBidsPage(),
      const LoginPage(),
      const ChatList(),
    ];

    // Nếu có sản phẩm, thay thế trang đầu tiên bằng trang chi tiết
    if (_selectedItem != null) {
  pages[0] = Auction_ItemsDetailPage(item: _selectedItem!);

    }

    return pages;
  }

  Future<void> _onItemTapped(int index) async {
    if (index == 2) {
      // Nếu chọn MyAuction
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      print("📢 userId từ SharedPreferences: $userId"); // ✅ Kiểm tra userId

      if (userId != null && userId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MyAuctionPage(userId: userId)),
        );
      } else {
        print("⚠️ User chưa đăng nhập, chuyển đến trang Login!");
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const LoginPage()), // 🟢 Chuyển đến LoginPage
        );
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = _getPages(); // Lấy danh sách trang

    return Scaffold(
      body: (_selectedIndex >= 0 && _selectedIndex < pages.length)
          ? pages[_selectedIndex]
          : const Center(
              child: Text(
                  "Invalid Page Index")), // Tránh lỗi truy cập ngoài phạm vi
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Auctions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_sharp), label: 'MyAuction'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'My Bids'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Chat'),
        ],
      ),
    );
  }
}
