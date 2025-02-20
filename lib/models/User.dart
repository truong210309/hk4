import 'dart:convert';

class User {
  String? id;
  String? name;
  String? password;
  String? confirmpassword;
  String? email;
 String? phone;
DateTime? dob;
String? address;
  User({this.id,this.address,this.phone,this.name, this.password, this.email,this.confirmpassword});



  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["name"] = name;
    map["id"] = id;
    map["address"] = address;
    map["password"] = password;
    map["confirmpassword"] = confirmpassword;
    map["email"] = email;
    map["id"] = id;
    map["phone"] = id;
    map["dob"] = dob;
    return map;
  }

  User.fromJson(dynamic json){
    name = json["name"] != null ? utf8.decode(json["name"].toString().codeUnits) : null; // ✅ Fix lỗi encoding UTF-8
    id = json["id"];
    password = json["password"];
    confirmpassword = json["confirmpassword"];
    email = json["email"];
    phone = json["phone"];
    dob = json["dob"];
    address = json["address"];
    id = json["id"];
    print("📌 User parsed: ID = $id, Name = $name, Email = $email");
    print("📌 User JSON: $json"); // ✅ Kiểm tra dữ liệu user từ API


  }
}