import 'package:fe/models/ChatMessageResponse.dart';
import 'package:fe/models/ChatRoomResponse.dart';
import 'package:fe/pages/ChatRoom.dart';
import 'package:fe/services/ApiChatService.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final ApiChatService apiChatService = ApiChatService();
  List<ChatRoomResponse> chatLists = [];

  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    loadUserIdAndFetchChats();
  }

  Future<void> loadUserIdAndFetchChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('userId');

    if (storedUserId != null) {
      setState(() {
        userId = storedUserId;
      });

      await fetchChatRooms(storedUserId);
    } else {
      setState(() {
        isLoading = false;
      });
      print("🚨 Không tìm thấy userId trong SharedPreferences!");
    }
  }

  Future<void> fetchChatRooms(storedUserId) async {
    try {
      List<ChatRoomResponse> rooms =
      await apiChatService.getAllRoomByUser(storedUserId);
      print(rooms);
      setState(() {
        chatLists = rooms;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error loading chat rooms: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text("Messenger"),
    backgroundColor: Colors.blueAccent,
    ),
    body: ListView.builder(
    itemCount: chatLists.length,
    itemBuilder: (context, index) {
    final chat = chatLists[index];

    return ListTile(
    leading: const CircleAvatar(
    backgroundImage: NetworkImage(
    "https://cdn-icons-png.flaticon.com/512/6596/6596121.png"),
    radius: 25,
    ),
    title: Text(
    userId != chat.userId
    ? (chat.sellerName ?? '')
        : (chat.buyerName ?? ''),
    style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text("item: ${chat.itemName!}",
    maxLines: 1, overflow: TextOverflow.ellipsis),
    // if (chat.message != null)
    //   Text(chat.message?.content ?? "",
    //       maxLines: 1, overflow: TextOverflow.ellipsis),
    if (chat.listMessages!.isNotEmpty)
    Text("${chat.listMessages != null && chat.listMessages!.isNotEmpty ? chat.listMessages!.first.content : ""}",
        maxLines: 1,
        overflow: TextOverflow.ellipsis),
    ],
    ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoom(
                userName: userId != chat.userId
                    ? (chat.sellerName ?? '')
                    : (chat.buyerName ?? ''),
                roomId: chat.roomId as int,
                userId: userId ?? ''),
          ),
        );
      },
    );
    },
    ),
    );
  }
}