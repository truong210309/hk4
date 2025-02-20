import 'dart:io';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/Auction.dart';
import 'package:fe/models/User.dart';
import 'package:fe/pages/ChatRoom.dart';
import 'package:flutter/material.dart';
import 'package:fe/models/Auction_Items.dart';
import 'package:fe/services/ApiAuction_ItemsService.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';

import '../models/Auction.dart';
import '../services/ApiBiddingService.dart';
import '../services/ApiPaymentService.dart';
import '../services/generateAuctionCertificate.dart';
import 'HomePage.dart';
import 'PaymentWebView.dart';

class WonItemDetailPage extends StatefulWidget {
  final Auction? item;

  const WonItemDetailPage({super.key, required this.item});
  @override
  _WonItemDetailPageState createState() =>
      _WonItemDetailPageState();
}

class _WonItemDetailPageState extends State<WonItemDetailPage> {
  late ApiAuction_ItemsService apiService;
//  late ApiBiddingService biddingService = ApiBiddingService();

  List<Auction> similarItems = [];
  bool isLoadingSimilarItems = true;
  late TextEditingController _bidController; // ✅ Ô nhập giá đấu
  bool isPlacingBid = false; // Trạng thái loading khi đặt giá
  Auction? updatedItem; // 🔥 Biến giữ dữ liệu mới
  double? price; // 🔥 Biến lưu trữ giá đã yêu cầu gửi
  late String? sellerid;
  @override
  void initState() {
    super.initState();
    sellerid = widget.item?.user?.id; // ✅ An toàn: Kiểm tra null trước

    // print("user: ${widget.item.seller != null ? widget.item.seller!.id : "No Seller"}");
    apiService = ApiAuction_ItemsService();
    _bidController = TextEditingController();
fetchItemDetails();
    fetchSimilarItems();
    fetchUpcomingItems();
  }

  List<Auction> upcomingItems = [];
  bool isLoadingUpcomingItems = true;

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  // 🔥 Gọi API để lấy giá hiện tại
  Future<void> fetchItemDetails() async {
    try {
      var newItem = await apiService.getItemById(widget.item!.itemId);
      //   print("✅ API returned item details: ${newItem.toJson()}");

      setState(() {
        updatedItem = newItem; // ✅ Cập nhật dữ liệu mới từ API
      });
    } catch (e) {
      print("🚨 Lỗi khi tải sản phẩm mới: $e");

    }
  }

  /// Gọi API để lấy danh sách sản phẩm sắp tới
  Future<void> fetchUpcomingItems() async {
    try {
      print("🔍 Fetching upcoming auction items...");
      var fetchedItems = await apiService.fetchUpcomingAuctions();
      print("✅ Fetched ${fetchedItems.length} upcoming items.");

      setState(() {
        upcomingItems = fetchedItems;
        isLoadingUpcomingItems = false;
      });
    } catch (e) {
      print("🚨 Lỗi khi tải sản phẩm sắp tới: $e");
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
      print("⚠️ Category name is null or empty.");
      setState(() => isLoadingSimilarItems = false);
      return;
    }

    int? categoryId = await apiService.getCategoryIdByName(categoryName);
    print("🔍 Category ID found: $categoryId"); // In ID ra console để debug

    if (categoryId == null) {
      print("⚠️ Không tìm thấy ID danh mục cho: $categoryName");
      setState(() => isLoadingSimilarItems = false);
      return;
    }

    try {
      print("🔍 Fetching items for category ID: $categoryId");
      var fetchedItems =
      await apiService.getItemsByCategory(categoryId.toString());
      print("✅ API Response: ${fetchedItems.length} items");

      setState(() {
        similarItems = fetchedItems;
        isLoadingSimilarItems = false;
      });
    } catch (e) {
      print("🚨 Lỗi khi tải sản phẩm cùng danh mục: $e");
      setState(() => isLoadingSimilarItems = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = updatedItem ?? widget.item; // 🔥 Sử dụng giá mới nếu có
    // print("🔥 Hiển thị giá: Current Price = ${item.currentPrice}, Starting Price = ${item.startingPrice}");

    String? imageUrl =
    (widget.item?.imagesList != null)
        ? widget.item?.imagesList!.first
        : 'https://via.placeholder.com/150';

    String timeLeft = getTimeLeft(widget.item?.endDate as DateTime?);
    print("📌 Hiển thị trên UI - Tên người bán: ${widget.item?.user?.name ?? "Không xác định"}");

    return Scaffold(
      appBar: AppBar(
        title: Text(item?.category?.category_name ?? 'Item Details'),
        //title: Text(widget.item?.user?.id ?? 'Item Details'),

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ✅ Hiển thị tên sản phẩm
                      Text(
                        item?.itemName ??  'No Name',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      /// ✅ Hiển thị trạng thái đấu giá thành công
                      const Text(
                        "🎉 Đã đấu giá thành công!",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),

                      const SizedBox(height: 4),

                      /// ✅ Hiển thị người bán
                      Text(
                        "👤 Người bán: ${item?.user?.name ?? "Không xác định"}",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.download, color: Colors.white),
                        label: Text("Tải Giấy Chứng Nhận"),
                        onPressed: () async {
                          await generateAuctionCertificate(widget.item!);
                        },
                      ),


                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        'Price: \$${item?.startingPrice ?? 0}',
                        style: const TextStyle(fontSize: 18)),
                    Text('Time Left: $timeLeft',
                        style:
                        const TextStyle(fontSize: 16, color: Colors.red)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            /// Mô tả sản phẩm
            const Text("Description",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),
            Text(widget.item?.description ?? 'No Description Available.'),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const ChatRoom(),
                  //   ),
                  // );
                },
                child: isPlacingBid
                    ? const CircularProgressIndicator()
                    : const Text("ASK A QUESTION"),
              ),
            ),
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
                  String itemImageUrl =
                  (item.imagesList != null && item.imagesList!.isNotEmpty)
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
                  String itemImageUrl =
                  (item.imagesList != null && item.imagesList!.isNotEmpty)
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


  Future<void> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      print("📂 Quyền truy cập bộ nhớ được cấp!");
    } else {
      print("🚨 Quyền truy cập bộ nhớ bị từ chối!");
    }
  }

  Future<void> generateAuctionCertificate(Auction item) async {
    try {
      final pdf = pw.Document();

      // 📌 Nội dung PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM",
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  "Độc lập - Tự do - Hạnh phúc",
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: pw.EdgeInsets.all(5),
                  color: PdfColors.grey300,
                  child: pw.Text(
                    "GIẤY CHỨNG NHẬN SẢN PHẨM ĐẤU GIÁ THÀNH CÔNG",
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Số: ${item.itemId}", style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Căn cứ theo hợp đồng đấu giá số: [Số hợp đồng] ngày ${item.startDate?.toLocal().toString().split(' ')[0]} giữa [LIVEAuction] và ${item.user?.name ?? "Không xác định"};",
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Chúng tôi, [LIVEAuction], xin xác nhận:",
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 10),

                // **MỤC 1: NGƯỜI TRÚNG ĐẤU GIÁ**
                pw.Text("1. Người trúng đấu giá:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Bullet(text: "Họ và tên: ${item.user?.name ?? "Không xác định"}"),
                pw.Bullet(text: "CMND/CCCD số: ${item.user?.id ?? "Không xác định"}"),
                pw.Bullet(text: "Ngày cấp: ${item.user?.dob ?? "Không xác định"}"),
                pw.Bullet(text: "Địa chỉ: [Địa chỉ người trúng đấu giá]"),
                pw.Bullet(text: "Số điện thoại: ${item.user?.phone ?? "Không xác định"}"),
                pw.SizedBox(height: 10),

                // **MỤC 2: SẢN PHẨM ĐẤU GIÁ THÀNH CÔNG**
                pw.Text("2. Sản phẩm đấu giá thành công:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Bullet(text: "Tên sản phẩm: ${item.itemName ?? "Không xác định"}"),
                pw.Bullet(text: "Mô tả sản phẩm: ${item.description ?? "Không có mô tả"}"),
                pw.Bullet(text: "Giá trúng đấu giá: ${item.startingPrice?.toStringAsFixed(0)} VND"),
                pw.Bullet(text: "Phương thức thanh toán: [Tiền mặt/Chuyển khoản]"),
                pw.Bullet(text: "Thời gian và địa điểm nhận sản phẩm: [Sau 3 ngày đấu gi]"),
                pw.SizedBox(height: 10),

                // **MỤC 3: XÁC NHẬN THANH TOÁN**
                pw.Text("3. Xác nhận thanh toán:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                item.ispaid == true
                    ? pw.Text("✅ Đã thanh toán đầy đủ", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green))
                    : pw.Text("❌ Chưa thanh toán (Còn lại: [Số tiền còn lại] VND, hạn thanh toán: [Ngày])",
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                pw.SizedBox(height: 10),

                // **PHẦN KÝ XÁC NHẬN**
                pw.Text("Xác nhận của đơn vị tổ chức đấu giá",
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text("Ngày ${DateTime.now().toLocal().toString().split(' ')[0]}, tại [Địa điểm]"),
                pw.SizedBox(height: 40),
                pw.Text("Đại diện đơn vị tổ chức đấu giá", style: pw.TextStyle(fontSize: 12)),
                pw.Text("(Ký, đóng dấu)", style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
              ],
            );
          },
        ),
      );
      Directory directory;
      await requestStoragePermission();  // Yêu cầu quyền lưu trữ

      if (Platform.isAndroid) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationSupportDirectory();
      }

      final filePath = "${directory.path}/GiayChungNhanDauGia.pdf";

      final file = File(filePath);
      print("📌 File đã lưu tại: $filePath");

      // ✍️ Ghi file PDF
      await file.writeAsBytes(await pdf.save());

      // 📥 Hiển thị thông báo tải thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("📥 File đã tải thành công! Kiểm tra trong thư mục Documents.")),
      );

      // 📂 Mở file sau khi lưu
      OpenFile.open(filePath);
    } catch (e) {
      print("🚨 Lỗi khi tạo file PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Không thể tạo Giấy chứng nhận.")),
      );
    }

  }


}
