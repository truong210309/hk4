class BiddingRequest {
  double? price;
  int? productId;
  String? userId;
  String? seller;

  BiddingRequest({this.price, this.productId, this.userId, this.seller});

  BiddingRequest copyWith(
      {double? price, int? productId, String? userId, String? seller}) =>
      BiddingRequest(
          price: price ?? this.price,
          productId: productId ?? this.productId,
          userId: userId ?? this.userId,
          seller: seller ?? this.seller);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["price"] = price;
    map["productId"] = productId;
    map["userId"] = userId;
    map["seller"] = seller;
    return map;
  }

  BiddingRequest.fromJson(dynamic json) {
    price = json["price"];
    productId = json["productId"];
    userId = json["userId"];
    seller = json["seller"];
  }
}