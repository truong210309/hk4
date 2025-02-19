
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:fe/services/UrlAPI.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiBiddingService {

  final String apiUrl = "http://192.168.1.30:8080/api/bidding";
  late WebSocketChannel channel;

  final String apiUrl = "${UrlAPI.url}/bidding";


  late StompClient stompClient;

  Function(double)? onNewBidReceived; // 🔥 Callback để cập nhật UI

  ApiBiddingService() {
    _connectWebSocket();
  }
  // Kết nối WebSocket
  void _connectWebSocket() {

    channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.30:8080/ws'), // Kiểm tra URL
    );

    channel.stream.listen(
          (message) {
        if (message != null) {
          try {
            var response = jsonDecode(message);
            print("📩 Dữ liệu nhận được từ WebSocket: $response");

            // Kiểm tra nếu dữ liệu có chứa 'price'
            if (response is Map<String, dynamic> && response.containsKey('price')) {
              var priceValue = response['price'];

              // Kiểm tra nếu giá trị không null
              if (priceValue != null) {
                double price = priceValue is double ? priceValue : double.tryParse(priceValue.toString()) ?? 0.0;
                print("🔔 Giá mới nhận được: \$$price");


    

                if (onNewBidReceived != null) {
                  onNewBidReceived!(price);
                }
              } else {
                print("🚨 Giá trị 'price' là null: $response");
              }
            } else {
              print("🚨 Dữ liệu phản hồi từ WebSocket không có 'price': $response");
            }

          } catch (e) {
            print("🚨 Lỗi giải mã WebSocket message: $e");
          }
        }
      },
      onError: (error) {
        print('🚨 Lỗi WebSocket: $error');
        _reconnectWebSocket();
      },
      onDone: () {
        print("❌ WebSocket đóng kết nối.");
        _reconnectWebSocket();
      },
    );
  }

  // Cố gắng kết nối lại WebSocket nếu không thành công
  int reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  void _reconnectWebSocket() async {
    if (reconnectAttempts >= maxReconnectAttempts) {
      print("❌ Đã thử quá số lần, không thể kết nối lại WebSocket.");
      return;
    }

    print("🔄 Đang thử kết nối lại WebSocket... (Lần $reconnectAttempts)");

    await Future.delayed(const Duration(seconds: 3));
    reconnectAttempts++;

    if (channel.closeCode != null) {
      print("🔄 Kết nối lại WebSocket...");
      _connectWebSocket();
    }
  }

  // Kiểm tra WebSocket kết nối trước khi gửi yêu cầu đặt giá
  Future<bool> placeBid(int productId, String? sellerId, double bidAmount) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("userId");

      if (userId == null) {
        print("🚨 Người dùng chưa đăng nhập!");
        return false;
      }
      var bidRequest = jsonEncode({
        "productId": productId,
        "userId": userId,
        "price": bidAmount,
        "seller": sellerId,
      });
      print("🔹 Gửi yêu cầu đặt giá: $bidRequest");
      // Gửi thông điệp WebSocket
      channel.sink.add(bidRequest);
      print("✅ Đã gửi yêu cầu đặt giá: \$${bidAmount}");
      return true;
    } catch (e) {
      print("🚨 Lỗi đặt giá: $e");
      return false;
    }
  }
}
