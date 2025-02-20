import 'dart:convert';
import 'dart:io';

import 'package:fe/models/ChatMessageRequest.dart';
import 'package:fe/models/ChatMessageResponse.dart';
import 'package:fe/pages/OtherImageChat.dart';
import 'package:fe/pages/OtherMsgWidget.dart';
import 'package:fe/pages/OwnImageChat.dart';
import 'package:fe/pages/OwnMsgWidget.dart';
import 'package:fe/services/ApiChatService.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:http/http.dart' as http;

class ChatRoom extends StatefulWidget {
  final String userName;
  final int roomId;
  final String userId;
  const ChatRoom(
      {super.key,
      required this.userName,
      required this.roomId,
      required this.userId});

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final ApiChatService apiChatService = ApiChatService();
  List<ChatMessageResponse> chatMessageLists = [];
  StompClient? stompClient;

  final ScrollController _scrollController = ScrollController();

  TextEditingController msgController = TextEditingController();
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  List<File>? _images;

  @override
  void initState() {
    super.initState();
    fetchChatRooms();
    connectWebSocket();
    _images = [];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void connectWebSocket() {
    print("Đã kết nối WebSocket ----------------");

    stompClient = StompClient(

      config: StompConfig.SockJS(
        url: 'http://172.16.2.0:8080/ws',
        onConnect: onConnect,
        onWebSocketError: (dynamic error) => print('Lỗi WebSocket: $error'),

      ),
    );
    stompClient?.activate();
  }

  void onConnect(StompFrame frame) {
    print("Đã kết nối WebSocket");

    stompClient?.subscribe(
      destination: '/topic/room/${widget.roomId}',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          var response = jsonDecode(frame.body!);

          setState(() {
            chatMessageLists.add(ChatMessageResponse.fromJson(response));
          });

          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToBottom();
          });
        }
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void sendMessage() async {
    if (msgController.text.isEmpty && (_images == null || _images!.isEmpty))
      return;

    List<String> imagePaths = [];

    // Chỉ khi có ảnh, thì mới lấy đường dẫn ảnh
    if (_images != null && _images!.isNotEmpty) {
      imagePaths = _images!.map((image) => image.path).toList();
    }

    ChatMessageRequest newChatMessageRequest = ChatMessageRequest(
      roomId: widget.roomId,
      content: msgController.text,
      sender: widget.userId,
      images: imagePaths,
      timestamp: DateTime.now().toIso8601String(),
    );

    try {
      ChatMessageResponse response =
          await apiChatService.sendMessage(newChatMessageRequest);

      ChatMessageRequest request = ChatMessageRequest(
          content: response.content,
          roomId: response.roomId,
          sender: response.senderId,
          imagess: response.imagesList,
          timestamp: response.timestamp?.toIso8601String());

      if (stompClient != null && stompClient!.connected) {
        String messageJson = jsonEncode(request);
        stompClient!.send(destination: "/app/sendMessage", body: messageJson);
      } else {
        print("🚨 WebSocket vẫn chưa kết nối, tin nhắn không được gửi!");
      }

      setState(() {
        _images?.clear();
        msgController.clear();
      });
    } catch (e) {
      print("❌ Lỗi khi gửi tin nhắn: $e");
    }
  }

  Future<void> fetchChatRooms() async {
    try {
      List<ChatMessageResponse> messages =
          await apiChatService.getAllMessageByRoomId(widget.roomId);
      setState(() {
        chatMessageLists = messages;
        isLoading = false;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error loading chat rooms: $e");
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images ??= []; // Khởi tạo nếu _images null
        _images!.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: chatMessageLists.length,
              itemBuilder: (context, index) {
                bool isSender =
                    chatMessageLists[index].senderId == widget.userId;

                if (isSender) {
                  if (chatMessageLists[index].imagesList != null &&
                      chatMessageLists[index].imagesList!.isNotEmpty) {
                    return Align(
                      alignment: Alignment.bottomRight,
                      child: OwnMsgWithImagesWidget(
                        msg: chatMessageLists[index].content ?? '',
                        images: chatMessageLists[index].imagesList!,
                      ),
                    );
                  } else {
                    return Align(
                      alignment: Alignment.bottomRight,
                      child: OwnMsgWidget(
                        msg: chatMessageLists[index].content ?? '',
                        sender: chatMessageLists[index].senderId ?? '',
                      ),
                    );
                  }
                } else {
                  if (chatMessageLists[index].imagesList != null &&
                      chatMessageLists[index].imagesList!.isNotEmpty) {
                    return Align(
                      alignment: Alignment.bottomLeft,
                      child: OtherMsgWithImagesWidget(
                        msg: chatMessageLists[index].content ?? '',
                        images: chatMessageLists[index].imagesList!,
                      ),
                    );
                  } else {
                    return Align(
                      alignment: Alignment.bottomLeft,
                      child: OtherMsgWidget(
                        msg: chatMessageLists[index].content ?? '',
                        sender: chatMessageLists[index].senderId ?? '',
                      ),
                    );
                  }
                }
              },
            ),
          ),
          if (_images != null && _images!.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images!.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: FileImage(_images![index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _images!.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(
                    Icons.image,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: msgController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          String msg = msgController.text;
                          if (msg.isNotEmpty) {
                            sendMessage();
                            // msgController.clear();
                          }
                        },
                        icon: const Icon(
                          Icons.send,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
