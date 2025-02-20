import 'package:fe/models/ChatMessageResponse.dart';

class ChatRoomResponse {
  num? roomId;
  String? userId;
  String? buyerName;
  String? sellerName;
  num? itemId;
  String? itemName;
  num? startingPrice;
  double? currentPrice;
  List<String>? imagesList;
  ChatMessageResponse? message;
  List<ChatMessageResponse>? listMessages;

  ChatRoomResponse(
      {this.roomId,
        this.userId,
        this.buyerName,
        this.sellerName,
        this.itemId,
        this.itemName,
        this.startingPrice,
        this.currentPrice,
        this.imagesList,
        this.message,
        this.listMessages});

  ChatRoomResponse copyWith(
      {num? roomId,
        String? userId,
        String? buyerName,
        String? sellerName,
        num? itemId,
        String? itemName,
        num? startingPrice,
        double? currentPrice,
        List<String>? imagesList,
        ChatMessageResponse? message}) =>
      ChatRoomResponse(
          roomId: roomId ?? this.roomId,
          userId: userId ?? this.userId,
          buyerName: buyerName ?? this.buyerName,
          sellerName: sellerName ?? this.sellerName,
          itemId: itemId ?? this.itemId,
          itemName: itemName ?? this.itemName,
          startingPrice: startingPrice ?? this.startingPrice,
          currentPrice: currentPrice ?? this.currentPrice,
          imagesList: imagesList ?? this.imagesList,
          message: message ?? this.message);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["roomId"] = roomId;
    map["userId"] = userId;
    map["buyerName"] = buyerName;
    map["sellerName"] = sellerName;
    map["item_id"] = itemId;
    map["item_name"] = itemName;
    map["starting_price"] = startingPrice;
    map["current_price"] = currentPrice;
    map["images"] = imagesList;
    if (message != null) {
      map["message"] = message?.toJson();
    }

    if (listMessages != null) {
      map["listMessages"] = listMessages?.map((msg) => msg.toJson()).toList();
    }

    return map;
  }

  ChatRoomResponse.fromJson(dynamic json) {
    roomId = json["roomId"];
    userId = json["userId"];
    buyerName = json["buyerName"];
    sellerName = json["sellerName"];
    itemId = json["item_id"];
    itemName = json["item_name"];
    startingPrice = json["starting_price"];
    currentPrice = json["current_price"];
    message = json["message"] != null
        ? ChatMessageResponse.fromJson(json["message"])
        : null;

    listMessages = json["listMessages"] != null
        ? List<ChatMessageResponse>.from(json["listMessages"]
        .map((msg) => ChatMessageResponse.fromJson(msg)))
        : [];

    imagesList =
    json["images"] != null ? List<String>.from(json["images"]) : [];
  }
}