import 'dart:io';

import 'package:fe/models/ChatMessageRequest.dart';
import 'package:fe/models/ChatMessageResponse.dart';
import 'package:fe/models/ChatRoomResponse.dart';
import 'package:fe/services/UrlAPI.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ApiChatService {
  static const String urlChat = "${UrlAPI.url}/chatroom";

  Future<List<ChatRoomResponse>> getAllRoomByUser(String userId) async {
    final String url = "$urlChat/room/$userId";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => ChatRoomResponse.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load chat rooms. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category data: $e');
    }
  }

  Future<ChatRoomResponse> createRoom(int? itemId, String userId) async {
    final String url = "$urlChat/room/$itemId";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(Uri.parse(url),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({"buyerId": userId}));
      print(response);
      if (response.body.isNotEmpty && response.statusCode == 200) {
        return ChatRoomResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to load chat rooms. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category data: $e');
    }
  }

  Future<List<ChatMessageResponse>> getAllMessageByRoomId(int roomId) async {
    final String url = "$urlChat/room/message/$roomId";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((item) => ChatMessageResponse.fromJson(item))
            .toList();
      } else {
        throw Exception(
            'Failed to load chat rooms. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category data: $e');
    }
  }

  Future<ChatMessageResponse> sendMessages(ChatMessageRequest request) async {
    const String url = "$urlChat/send-message";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    Map<String, dynamic> requestBody = {
      "roomId": request.roomId,
      "content": request.content,
      "sender": request.sender,
      "imagess": request.images,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return ChatMessageResponse.fromJson(jsonDecode(response.body));
    } else {
      print("Lỗi ${response.statusCode}: ${response.body}");
      throw Exception(
          'Failed to send message. Status Code: ${response.statusCode}');
    }
  }

  Future<ChatMessageResponse> sendMessage(ChatMessageRequest request) async {
    const String url = "$urlChat/send-message";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    var requestMultipart = http.MultipartRequest("POST", Uri.parse(url))
      ..headers["Authorization"] = "Bearer $token"
      ..fields["roomId"] = request.roomId.toString()
      ..fields["content"] = request.content ?? ""
      ..fields["sender"] = request.sender ?? "";

    // Kiểm tra nếu có ảnh thì thêm vào request
    if (request.images != null && request.images!.isNotEmpty) {
      for (var imagePath in request.images!) {
        var multipartFile =
        await http.MultipartFile.fromPath('images', imagePath);
        requestMultipart.files.add(multipartFile);
      }
    }

    var streamedResponse = await requestMultipart.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return ChatMessageResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to send message. Status Code: ${response.statusCode}');
    }
  }
}
