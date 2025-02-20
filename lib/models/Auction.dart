
import 'package:fe/models/Bidding.dart';
import 'package:fe/models/BiddingRequest.dart';
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
 // String? sellerName;
  BiddingResponse? bidding;
  Auction(
      {

     //   this.sellerName,
        this.bidding,
        this.itemId,
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
        this.buyer});
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
  //  map["sellerName"] = sellerName;
    map["item_id"] = itemId;
    map["biddingResponse"] = bidding;
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
    if (category != null) {
      map["category"] = category?.toJson();
    }
    if (user != null) {
      map["user"] = user?.toJson();
    }
    if (buyer != null) {
      map["buyer"] = buyer?.toJson();
    }
    if (bidding != null) {
      map["bidding"] = bidding?.toJson();
    }
    return map;
  }

  // Auction.fromJson(dynamic json){
  //   // itemId = json["item_id"];
  //   // itemName = json["item_name"];
  //   // description = json["description"];
  //   // imagesList = json["images"] != null ? List<String>.from(json["images"]) : [];
  //   // startingPrice = json["starting_price"];
  //   // currentPrice = json["current_price"];
  //   // startDate = json["start_date"];
  //   // endDate = json["end_date"];
  //   // bidStep = json["bid_step"];
  //   // status = json["status"];
  //   // issell = json["isSell"];
  //   // issoldout = json["isSoldout"];
  //   // ispaid = json["isPaid"];
  //   // category = json["category"] != null ? Category.fromJson(json["category"]) : null;
  //   // user = json["user"] != null ? User.fromJson(json["user"]) : null;
  //   // buyer = json["buyer"] != null ? User.fromJson(json["buyer"]) : null;
  //
  //   itemId = json["item_id"];
  //   itemName = json["item_name"];
  //   description = json["description"];
  //   startingPrice = json["starting_price"];
  //   currentPrice = json["current_price"];
  //   ispaid = json["paid"] ?? false;
  //
  //   if (json["start_date"] is List && json["start_date"].length == 3) {
  //     startDate = DateTime(json["start_date"][0], json["start_date"][1], json["start_date"][2]);
  //   } else {
  //     startDate = null;
  //   }
  //
  //   if (json["end_date"] is List && json["end_date"].length == 3) {
  //     endDate = DateTime(json["end_date"][0], json["end_date"][1], json["end_date"][2]);
  //   } else {
  //     endDate = null;
  //   }
  //
  //   bidStep = json["bid_step"];
  //   issell = json["sell"];
  //   status = json["status"];
  //   issoldout = json["soldout"];
  //
  //   imagesList = (json["images"] != null && json["images"] is List)
  //       ? (json["images"] as List).whereType<String>().toList()
  //       : [];
  //
  //   category = json["category"] != null ? Category.fromJson(json["category"]) : null;
  //   // user = json["user"] != null
  //   //     ? User.fromJson(json["user"])
  //   //     : json["seller"] != null
  //   //     ? User.fromJson(json["seller"]) // 🔥 Nếu API dùng key khác
  //   //     : null;
  //
  //   print("📌 Người bán sau khi parse JSON: ${user?.toJson()}");
  //
  //   // 🔥 Fix lỗi buyer: Chỉ gán nếu `json["buyer"]` là `Map`
  //   buyer = (json["buyer"] != null && json["buyer"] is Map)
  //       ? User.fromJson(json["buyer"])
  //       : null;
  //
  //
  //   print("📌 JSON chứa user không? ${json.containsKey("user")}");
  //   print("📌 Dữ liệu user từ API: ${json["user"]}");
  //
  //   user = json["user"] != null
  //       ? User.fromJson(json["user"])
  //       : null;
  //
  //   print("📌 Người bán sau khi parse JSON: ${user?.toJson()}");
  // }

  Auction.fromJson(dynamic json) {
    print("📌 Parsing JSON: $json"); // ✅ Debug dữ liệu API nhận về

    itemId = json["item_id"];
    itemName = json["item_name"];
    description = json["description"];
    startingPrice = json["starting_price"];
    currentPrice = json["current_price"];
    ispaid = json["paid"] ?? false;

    if (json["start_date"] is List && json["start_date"].length == 3) {
      startDate = DateTime(json["start_date"][0], json["start_date"][1], json["start_date"][2]);
    } else {
      startDate = null;
    }

    if (json["end_date"] is List && json["end_date"].length == 3) {
      endDate = DateTime(json["end_date"][0], json["end_date"][1], json["end_date"][2]);
    } else {
      endDate = null;
    }

    bidding = json["bidding"] != null
        ? BiddingResponse.fromJson(json["bidding"])
        : null;

    bidStep = json["bid_step"];
    issell = json["sell"];
    status = json["status"];
    issoldout = json["soldout"];

    imagesList = (json["images"] != null && json["images"] is List)
        ? (json["images"] as List).whereType<String>().toList()
        : [];

    category = json["category"] != null ? Category.fromJson(json["category"]) : null;


    print("📌 JSON chứa user không? ${json.containsKey("user")}");
    print("📌 Dữ liệu user từ API: ${json["user"]}");

    if (json.containsKey("user") && json["user"] != null) {
      user = User.fromJson(json["user"]);
      print("✅ Người bán parse thành công: ${user?.name}");
    } else {
      print("🚨 Không có dữ liệu người bán!");
    }

    // ✅ Parse Buyer nếu tồn tại
    if (json.containsKey("buyer") && json["buyer"] != null) {
      buyer = User.fromJson(json["buyer"]);
      print("✅ Buyer parse thành công: ${buyer?.name}");
    } else {
      print("🚨 Không có dữ liệu buyer!");
    }
    // ✅ Parse dữ liệu Buyer (Người mua)
    // if (json["buyer"] != null && json["buyer"] is Map) {
    //   buyer = User.fromJson(json["buyer"]);
    // }
    print("📌 Người bán sau khi parse JSON: ${user?.name}"); // ✅ Debug người bán


  }

}