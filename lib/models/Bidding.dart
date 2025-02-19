class Bidding {
  int? id;
  double? price;
  int? itemId;
  String? userId;

  Bidding({
    this.id,
    this.price,
    this.itemId,
    this.userId,
  });

  // Chuyển đổi từ JSON sang Object Bidding
  factory Bidding.fromJson(Map<String, dynamic> json) {
    return Bidding(
      id: json['id'],
      price: json['price'],
      itemId: json['auction_Items'] != null
          ? json['auction_Items']['item_id']
          : null,
      userId: json['user'] != null ? json['user']['id'] : null,
    );
  }

  // Chuyển đổi từ Object Bidding sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'auction_Items': itemId != null ? {'item_id': itemId} : null,
      'user': userId != null ? {'id': userId} : null,
    };
  }
}
