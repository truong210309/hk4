import 'package:fe/models/ChatMessageResponse.dart';

class ChatRoomResponse {
  num? roomId;
  String? userId;
  String? buyerName;
  String? sellerName;
  num? itemId;
  String? itemName;
  num? startingPrice;
  num? currentPrice;
  List<String>? imagesList;
  ChatMessageResponse? message;

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
      this.message});

  ChatRoomResponse copyWith(
          {num? roomId,
          String? userId,
          String? buyerName,
          String? sellerName,
          num? itemId,
          String? itemName,
          num? startingPrice,
          num? currentPrice,
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
    imagesList = json["images"] != null ? json["images"].cast<String>() : [];

    imagesList =
        json["images"] != null ? List<String>.from(json["images"]) : [];
  }
}
