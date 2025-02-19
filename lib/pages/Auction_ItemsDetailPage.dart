import 'dart:convert';

import 'package:fe/models/BiddingRequest.dart';
import 'package:fe/models/ChatRoomResponse.dart';
import 'package:fe/pages/ChatRoom.dart';
import 'package:fe/services/ApiChatService.dart';
import 'package:flutter/material.dart';
import 'package:fe/services/ApiAuction_ItemsService.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../models/Auction.dart';
import '../services/ApiPaymentService.dart';
import 'HomePage.dart';
import 'PaymentWebView.dart';
import 'package:intl/date_symbol_data_local.dart';

class Auction_ItemsDetailPage extends StatefulWidget {
  final Auction? item;

  const Auction_ItemsDetailPage({super.key, required this.item});
  @override
  _Auction_ItemsDetailPageState createState() =>
      _Auction_ItemsDetailPageState();
}

class _Auction_ItemsDetailPageState extends State<Auction_ItemsDetailPage> {
  late ApiAuction_ItemsService apiService;
  ApiChatService apiChatService = ApiChatService();
  StompClient? stompClient;
  List<Auction> similarItems = [];
  bool isLoadingSimilarItems = true;
  late TextEditingController _bidController; // ✅ Ô nhập giá đấu
  bool isPlacingBid = false; // Trạng thái loading khi đặt giá
  Auction? updatedItem; // 🔥 Biến giữ dữ liệu mới
  double? price; // 🔥 Biến lưu trữ giá đã yêu cầu gửi
  late String? sellerid;
  String? userId;
  late double? currentPrice = 0;
  late DateTime? endDate = widget.item?.endDate;

  @override
  void initState() {
    super.initState();
    sellerid = widget.item?.user!.id;
    currentPrice = widget.item?.bidding?.price;

    apiService = ApiAuction_ItemsService();
    _bidController = TextEditingController();

    fetchSimilarItems();
    fetchUpcomingItems();
    connectWebSocket();
    getUserId();
    initializeDateFormatting('en', null).then((_) {
      formatDate(endDate);
    });
  }

  List<Auction> upcomingItems = [];
  bool isLoadingUpcomingItems = true;

  void formatDate(endDate) {
    if (endDate != null) {
      String formattedDate =
          DateFormat('EEEE, dd/MM/yyyy HH:mm:ss', 'en').format(endDate);
      setState(() {
        endDate = formattedDate;
      });
      print(formattedDate);
    } else {
      print("Ngày kết thúc không hợp lệ");
    }
  }

  void getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currentUserId = prefs.getString("userId");
    if (currentUserId != null) {
      setState(() {
        userId = currentUserId;
      });
    }
  }

  // 🔥 Gọi API để lấy giá hiện tại
  Future<void> fetchItemDetails() async {
    try {
      var newItem = await apiService.getItemById(widget.item!.itemId);
      setState(() {
        updatedItem = newItem;
      });
    } catch (e) {
      print("🚨 Lỗi khi tải sản phẩm mới: $e");
    }
  }

  void connectWebSocket() {
    print("Đã kết nối WebSocket dau gia ----------------");

    stompClient = StompClient(
      config: StompConfig.SockJS(
        url: 'http://192.168.1.134:8080/ws',
        onConnect: onConnect,
        onWebSocketError: (dynamic error) => print('Lỗi WebSocket: $error'),
      ),
    );
    stompClient?.activate();
  }

  void onConnect(StompFrame frame) {
    print("Đã kết nối WebSocket");

    stompClient?.subscribe(
      destination: '/topic/newbidding',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          var response = jsonDecode(frame.body!);
          setState(() {
            currentPrice = response['price'];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("🎉 Đã đặt giá thành công: \$$currentPrice")),
            );
          });
        }
      },
    );
  }

  // 🔥 Đặt giá đấu giá mới
  Future<void> placeBid() async {
    double? bidAmount = double.tryParse(_bidController.text);
    if (bidAmount == null || bidAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🚨 Vui lòng nhập giá hợp lệ!")),
      );
      return;
    }
    BiddingRequest request = BiddingRequest(
        price: bidAmount,
        productId: widget.item!.itemId,
        seller: widget.item!.user!.id,
        userId: userId);
    if (stompClient != null && stompClient!.connected) {
      String messageJson = jsonEncode(request);
      stompClient!.send(destination: "/app/create", body: messageJson);
      _bidController.clear();
    } else {
      print(" WebSocket vẫn chưa kết nối, tin nhắn không được gửi!");
    }
  }

  /// Gọi API để lấy danh sách sản phẩm sắp tới
  Future<void> fetchUpcomingItems() async {
    try {
      var fetchedItems = await apiService.fetchUpcomingAuctions();

      setState(() {
        upcomingItems = fetchedItems;
        isLoadingUpcomingItems = false;
      });
    } catch (e) {
      setState(() => isLoadingUpcomingItems = false);
    }
  }

  /// Tính thời gian còn lại của phiên đấu giá
  String getTimeLeft(DateTime? endDate) {
    if (endDate == null) return "No End Date";
    final now = DateTime.now();
    final difference = endDate.difference(now);
    if (difference.isNegative) return "Auction has ended";
    if (difference.inDays > 0) return '${difference.inDays} day(s) left';
    if (difference.inHours > 0) return '${difference.inHours} hour(s) left';
    return '${difference.inMinutes} minute(s) left';
  }

  /// Gọi API để lấy danh sách sản phẩm liên quan
  Future<void> fetchSimilarItems() async {
    String? categoryName = widget.item?.category?.category_name;
    if (categoryName == null || categoryName.isEmpty) {
      setState(() => isLoadingSimilarItems = false);
      return;
    }

    int? categoryId = await apiService.getCategoryIdByName(categoryName);

    if (categoryId == null) {
      setState(() => isLoadingSimilarItems = false);
      return;
    }

    try {
      var fetchedItems =
          await apiService.getItemsByCategory(categoryId.toString());

      setState(() {
        similarItems = fetchedItems;
        isLoadingSimilarItems = false;
      });
    } catch (e) {
      print("🚨 Lỗi khi tải sản phẩm cùng danh mục: $e");
      setState(() => isLoadingSimilarItems = false);
    }
  }

  Future<void> addRoom() async {
    ChatRoomResponse response =
        await apiChatService.createRoom(widget.item?.itemId, userId!);
    print("Room response: $response");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoom(
            userName: userId != response.userId
                ? (response.sellerName ?? '')
                : (response.buyerName ?? ''),
            roomId: response.roomId as int,
            userId: userId ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = updatedItem ?? widget.item;

    String? imageUrl = (widget.item?.imagesList != null)
        ? widget.item?.imagesList!.first
        : 'https://via.placeholder.com/150';

    String timeLeft = getTimeLeft(widget.item?.endDate);
    String startDate = getTimeLeft(widget.item?.startDate);
    String? sellerId = widget.item?.user?.id;
    String? buyerId = userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item?.itemName ?? 'Item Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const Homepage(initialIndex: 0), // 🔥 Quay về trang chính
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Hình ảnh sản phẩm
            Image.network(
              imageUrl!,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.network('https://via.placeholder.com/150',
                    width: double.infinity, height: 300, fit: BoxFit.cover);
              },
            ),
            const SizedBox(height: 16),

            /// Tiêu đề và giá sản phẩm
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.item?.itemName ?? 'No Name',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Start Price: \$${item?.startingPrice ?? 0}',
                        style: const TextStyle(fontSize: 18)),
                    Text('Current Price: \$${currentPrice ?? 0}',
                        style: const TextStyle(fontSize: 18)),
                    Text(
                      'Start Date: $startDate',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    Text(
                      'Time Left: $timeLeft',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// Ô nhập giá đấu giá
            TextField(
              controller: _bidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter your bid",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            /// Nút đặt giá
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPlacingBid ? null : placeBid,
                child: isPlacingBid
                    ? const CircularProgressIndicator()
                    : const Text("PLACE BID"),
              ),
            ),

            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final apiPaymentService = ApiPaymentService();

                String orderId = DateTime.now()
                    .millisecondsSinceEpoch
                    .toString(); // ✅ Tạo orderId duy nhất
                String? productId = widget.item?.itemId
                    .toString(); // 🔥 Chuyển `int?` thành `String`

                String? paymentUrl = await apiPaymentService.createPayment(
                  productId!, // ✅ Đảm bảo `productId` là `String`
                  widget.item?.startingPrice ??
                      0, // Vẫn giữ `startingPrice` là `double`
                  orderId,
                );

                if (paymentUrl != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PaymentWebView(
                              paymentUrl: paymentUrl,
                              productId: '',
                            )),
                  );
                } else {
                  print("🚨 Lỗi tạo thanh toán VNPay!");
                }
              },
              child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text("Payment")),
              ),
            ),

            const Divider(),

            /// Mô tả sản phẩm
            const Text("Description",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (userId != null && widget.item!.user!.id != userId)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: addRoom,
                  child: isPlacingBid
                      ? const CircularProgressIndicator()
                      : const Text("ASK A QUESTION"),
                ),
              ),

            const SizedBox(height: 8),
            Text(widget.item?.description ?? 'No Description Available.'),
            const Divider(),
            const Text('Upcomming Items Available Now',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            SizedBox(
              height: 250, // 🔥 Tăng chiều cao nếu cần
              child: isLoadingUpcomingItems
                  ? const Center(
                      child:
                          CircularProgressIndicator()) // Hiển thị vòng xoay nếu đang tải
                  : upcomingItems.isEmpty
                      ? const Center(child: Text("No upcoming items found"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: upcomingItems.length,
                          itemBuilder: (context, index) {
                            var item = upcomingItems[index];
                            String itemImageUrl = (item.imagesList != null &&
                                    item.imagesList!.isNotEmpty)
                                ? item.imagesList!.first
                                : 'https://via.placeholder.com/150';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Homepage(
                                        initialIndex: 0,
                                        selectedItem:
                                            item), // 🔥 Mở trong HomePage
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        itemImageUrl,
                                        width: 150, // 🔥 Kích thước ảnh
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.asset(
                                              'assets/placeholder.jpg',
                                              width: 150,
                                              height: 120,
                                              fit: BoxFit.cover);
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(item.itemName ?? 'No Name',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Text("\$${item.startingPrice ?? 0}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text("${item.bidStep ?? 0} Bids",
                                        style:
                                            TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const Divider(),

            const Divider(),

            /// Danh sách sản phẩm liên quan
            const Text('Similar Items Available Now',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            SizedBox(
              height: 250, // 🔥 Tăng chiều cao nếu cần
              child: isLoadingSimilarItems
                  ? const Center(child: CircularProgressIndicator())
                  : similarItems.isEmpty
                      ? const Center(child: Text("No similar items found"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: similarItems
                              .length, // 🔥 Hiển thị tất cả sản phẩm
                          itemBuilder: (context, index) {
                            var item = similarItems[index];
                            String itemImageUrl = (item.imagesList != null &&
                                    item.imagesList!.isNotEmpty)
                                ? item.imagesList!.first
                                : 'https://via.placeholder.com/150';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Homepage(
                                        initialIndex: 0,
                                        selectedItem:
                                            item), // 🔥 Mở trong HomePage
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        itemImageUrl,
                                        width:
                                            150, // 🔥 Tăng kích thước ảnh nếu cần
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.asset(
                                              'assets/placeholder.jpg',
                                              width: 150,
                                              height: 120,
                                              fit: BoxFit.cover);
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(item.itemName ?? 'No Name',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Text("\$${item.startingPrice ?? 0}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text("${item.bidStep ?? 0} Bids",
                                        style:
                                            TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
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
