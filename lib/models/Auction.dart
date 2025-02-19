import 'package:fe/models/BiddingResponse.dart';

import 'Category.dart';
import 'User.dart';

class Auction {
  int? itemId;
  String? itemName;
  String? description;
  List<String>? imagesList;
  double? startingPrice;
  double? currentPrice;
  DateTime? startDate;
  DateTime? endDate;
  String? bidStep;
  bool? status;
  bool? issell;
  bool? issoldout;
  bool? ispaid;
  Category? category;
  User? user;
  User? buyer;
  BiddingResponse? bidding;

  Auction(
      {this.itemId,
      this.itemName,
      this.description,
      this.imagesList,
      this.startingPrice,
      this.currentPrice,
      this.startDate,
      this.endDate,
      this.bidStep,
      this.status,
      this.issell,
      this.issoldout,
      this.ispaid,
      this.category,
      this.user,
      this.buyer,
      this.bidding});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["item_id"] = itemId;
    map["item_name"] = itemName;
    map["description"] = description;
    map["images"] = imagesList;
    map["starting_price"] = startingPrice;
    map["current_price"] = currentPrice;
    map["start_date"] = startDate;
    map["end_date"] = endDate;
    map["bid_step"] = bidStep;
    map["status"] = status;
    map["isSell"] = issell;
    map["isSoldout"] = issoldout;
    map["isPaid"] = ispaid;

    if (bidding != null) {
      map["bidding"] = bidding?.toJson();
    }

    if (category != null) {
      map["category"] = category?.toJson();
    }
    if (user != null) {
      map["user"] = user?.toJson();
    }
    if (buyer != null) {
      map["buyer"] = buyer?.toJson();
    }
    return map;
  }

  Auction.fromJson(dynamic json) {
    itemId = json["item_id"];
    itemName = json["item_name"];
    description = json["description"];
    startingPrice = json["starting_price"];
    currentPrice = json["current_price"];
    ispaid = json["paid"] ?? false;

    if (json["start_date"] is List && json["start_date"].length == 3) {
      startDate = DateTime(
          json["start_date"][0], json["start_date"][1], json["start_date"][2]);
    } else {
      startDate = null;
    }

    if (json["end_date"] is List && json["end_date"].length == 3) {
      endDate = DateTime(
          json["end_date"][0], json["end_date"][1], json["end_date"][2]);
    } else {
      endDate = null;
    }

    bidStep = json["bid_step"];
    issell = json["sell"];
    status = json["status"];
    issoldout = json["soldout"];

    imagesList = (json["images"] != null && json["images"] is List)
        ? (json["images"] as List).whereType<String>().toList()
        : [];

    category =
        json["category"] != null ? Category.fromJson(json["category"]) : null;
    user = json["user"] != null ? User.fromJson(json["user"]) : null;
    bidding = json["bidding"] != null
        ? BiddingResponse.fromJson(json["bidding"])
        : null;

    buyer = (json["buyer"] != null && json["buyer"] is Map)
        ? User.fromJson(json["buyer"])
        : null;
  }
}
