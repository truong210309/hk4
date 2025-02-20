class BiddingResponse {
  int? id;
  double? price;
  int? productId;
  String? productName;
  String? user;

  BiddingResponse(
      {this.id, this.price, this.productId, this.productName, this.user});

  BiddingResponse copyWith(
      {int? id,
        double? price,
        int? productId,
        String? productName,
        String? user}) =>
      BiddingResponse(
          id: id ?? this.id,
          price: price ?? this.price,
          productId: productId ?? this.productId,
          productName: productName ?? this.productName,
          user: user ?? this.user);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["id"] = id;
    map["price"] = price;
    map["productId"] = productId;
    map["productName"] = productName;
    map["user"] = user;
    return map;
  }

  BiddingResponse.fromJson(dynamic json) {
    id = json["id"];
    price = json["price"];
    productId = json["productId"];
    productName = json["productName"];
    user = json["user"];
  }
}