import 'dart:convert';
// import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:fe/services/UrlAPI.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/User.dart';
import '../pages/LoginPage.dart';

class ApiUserService {

  static const String baseUrl = "${UrlAPI.url}/users";
  // static const String baseUrl = "http://192.168.1.134:8080/api/users";
  static const String loginUrl = "${UrlAPI.url}/auth";



  Future<bool> registerUser(User user) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(user.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final response = await http.post(

      Uri.parse("${UrlAPI.url}/auth/login"),


      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    print("📢 API LOGIN STATUS: ${response.statusCode}");
    print("📢 API LOGIN BODY: ${response.body}");
    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      if (responseData.containsKey('result')) {
        var result = responseData['result'];
        if (result.containsKey('userId') && result.containsKey('token')) {
          String userId = result['userId'];
          String token = result['token'];
          String username = result['username'];
          print("✅ Lưu thông tin đăng nhập:");
          print("🆔 User ID: $userId");
          print("🔑 Token: $token");
          print("👤 Username: $username");
          SharedPreferences prefs = await SharedPreferences.getInstance();
          try {
            String? userId = prefs.getString('userId');

            if (userId != null) {
              await prefs.setString("userId", userId);
              print("✅ Saved Seller ID: $userId");
            } else {
              print("❌ Error: userId not found in JWT payload");
            }
          } catch (e) {
            print("❌ JWT Decode Error: $e");
          }
          await prefs.setString('userId', userId);
          await prefs.setString('token', token);
          await prefs.setString('username', username);
          return responseData;
        } else {
          print("🚨 Lỗi: userId hoặc token không có trong response!");
          return null;
        }
      } else {
        print("🚨 Lỗi: Response không chứa key 'result'!");
        return null;
      }
    } else {
      print("🚨 Lỗi đăng nhập: ${response.body}");
      return null;
    }
  }

  // Đăng xuất người dùng
  Future<void> logoutUser() async {
    print("🚨 Đang thực hiện logout!");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('userId');
    await prefs.remove('token');

    print("📢 Đã xóa dữ liệu đăng nhập!");

  }


  Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password?email=${Uri.encodeComponent(email.trim())}'),
        headers: {"Content-Type": "application/json"},
      );

      print("Forgot Password Response: ${response.body}");

      if (response.statusCode == 200) {
        // Since the response is plain text, we cannot extract an OTP.
        print("✅ OTP request successful, sending notification...");

        bool isCreated = await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 11,
            channelKey: 'otp_channel',
            title: 'OTP Sent',
            body: 'Your OTP has been sent to your email. Please check your inbox.',
            notificationLayout: NotificationLayout.Default,
          ),
        );

        print("📢 Notification created: $isCreated");

        return true;
      } else {
        print("🚨 Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("🚨 Exception occurred: $e");
      return false;
    }
  }

  // Xác thực OTP
  Future<bool> verifyOTP(String email, String otp) async {
    final response = await http.post(
      Uri.parse(
          '$baseUrl/verify-otp?email=${Uri.encodeComponent(email)}&otp=${Uri
              .encodeComponent(otp)}'), // Query params
      headers: {"Content-Type": "application/json"},
    );

    print("Verify OTP Response: ${response.body}");

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Error: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  // Đặt lại mật khẩu
  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$baseUrl/reset-password?email=${Uri.encodeComponent(email)}&otp=${Uri.encodeComponent(otp)}&newPassword=${Uri.encodeComponent(newPassword)}'),
        headers: {"Content-Type": "application/json"},
      );

      // Check if status code is 200 for success
      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

}



// cccc
