import 'dart:convert';

import 'package:fe/pages/ForgotPasswordPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/User.dart';
import '../services/ApiUserService.dart';
import 'CreateAuctionItemsPage.dart';
import 'DeviceSettingsPage.dart';
import 'MyAccountPage.dart';
import 'MyAuctionPage.dart';
import 'MyBidsPage.dart';
import 'WonItemsPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<void> _navigateToMyAuctions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs
        .getString('userId'); // Giả sử bạn đã lưu userId vào SharedPreferences

    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyAuctionPage(userId: userId)),
      );
    } else {
      print("⚠ User ID not found!");
    }
  }

  final ApiUserService _apiUserService = ApiUserService();
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadUserData(); // Gọi hàm kiểm tra dữ liệu đăng nhập
  }

  Future<void> _loginUser(String email, String password) async {
    var response = await _apiUserService.loginUser(email, password);

    if (response != null && response.containsKey('result')) {
      var result = response['result'];

      if (result != null &&
          result.containsKey('userId') &&
          result.containsKey('token')) {
        String userId = result['userId'];
        String token = result['token'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        await prefs.setString('token', token);

        print("✅ Login thành công, chuyển về MyBidsPage!");

        // 🔥 Chuyển về MyBidsPage sau khi đăng nhập
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyBidsPage()),
        );
      } else {
        print("🚨 Lỗi: userId hoặc token không có trong kết quả!");
      }
    } else {
      print("🚨 Lỗi đăng nhập: API trả về dữ liệu không hợp lệ!");
    }
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('token');
    print("📢 Kiểm tra dữ liệu đăng nhập:");
    print("👤 Username: $username");
    print("🆔 UserId: $userId");
    print("🔑 Token: $token");
    if (username != null && userId != null && token != null) {
      setState(() {
        _username = username;
      });
    } else {
      print("🚨 Không tìm thấy thông tin đăng nhập!");
    }
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username');
    });
  }

  Future<void> _logout() async {
    print("🚨 Đang thực hiện logout!");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("📢 Đã xóa dữ liệu đăng nhập!");
    // Cập nhật lại UI
    _username = null;
    setState(() {});
  }

  void _showSignUpDialog(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    DateTime? selectedDOB;
    bool isChecked = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FractionallySizedBox(
              heightFactor: 0.85,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề và nút đóng
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Sign Up",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Username
                      TextField(
                          controller: usernameController,
                          decoration: _inputDecoration("Username")),
                      const SizedBox(height: 15),

                      // Email
                      TextField(
                          controller: emailController,
                          decoration: _inputDecoration("Email")),
                      const SizedBox(height: 15),

                      // Phone Number
                      TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration("Phone Number")),
                      const SizedBox(height: 15),

                      // Address
                      TextField(
                          controller: addressController,
                          decoration: _inputDecoration("Address")),
                      const SizedBox(height: 15),

                      // DOB (Ngày Sinh) với Date Picker
                      GestureDetector(
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDOB = pickedDate;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedDOB == null
                                    ? "Select Date of Birth"
                                    : "${selectedDOB!.day}/${selectedDOB!.month}/${selectedDOB!.year}",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.calendar_today, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Password
                      TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: _inputDecoration("Password")),
                      const SizedBox(height: 15),

                      // Confirm Password
                      TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration("Confirm Password")),
                      const SizedBox(height: 15),

                      // Checkbox Terms & Conditions
                      Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isChecked = value ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text("I agree to the Terms & Conditions",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black54)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Chuyển sang đăng nhập nếu đã có tài khoản
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Đóng Sign Up
                            _showLoginDialog(context); // Mở Login
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: Colors.black, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: "Log In",
                                  style: TextStyle(
                                      color: Colors.teal,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Nút SIGN UP
                      ElevatedButton(
                        onPressed: isChecked
                            ? () async {
                          if (passwordController.text !=
                              confirmPasswordController.text) {
                            _showMessage(
                                context, "Passwords do not match!");
                            return;
                          }
                          if (selectedDOB == null) {
                            _showMessage(context, "Please select your Date of Birth!");
                            return;
                          }

                          User newUser = User(
                            name: usernameController.text,
                            email: emailController.text,
                            password: passwordController.text,
                            phone: phoneController.text,
                            address: addressController.text,
                        //    dob: selectedDOB,
                          );

                          bool isSuccess =
                          await _apiUserService.registerUser(newUser);
                          if (isSuccess) {
                            _showMessage(context, "Sign Up Successful!");
                            Navigator.pop(context);
                          } else {
                            _showMessage(context, "Sign Up Failed!");
                          }
                        }
                            : null,
                        style: _buttonStyle(),
                        child: const Text("SIGN UP",
                            style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  void _showLoginDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Log In",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                    controller: emailController,
                    decoration: _inputDecoration("Email")),
                const SizedBox(height: 15),
                TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _inputDecoration("Password")),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    String email = emailController.text;
                    String password = passwordController.text;
                    var response =
                        await _apiUserService.loginUser(email, password);
                    if (response != null) {
                      print(
                          "📢 Full API Response: $response"); // ✅ In toàn bộ dữ liệu trả về

                      print(
                          "📢 Full API Response: $response"); // ✅ In toàn bộ dữ liệu trả về

                      if (response.containsKey('result')) {
                        // ✅ Kiểm tra key 'result' tồn tại
                        var result = response['result'];
                        print(
                            "📢 API result: $result"); // ✅ Kiểm tra result có null không

                        if (result != null &&
                            result.containsKey('userId') &&
                            result.containsKey('token')) {
                          String userId = result['userId'];
                          String token = result['token']; // ✅ Lấy token từ API
                          print(
                              "✅ userId lấy được: $userId"); // ✅ In userId để kiểm tra
                          print(
                              "✅ Token lấy được: $token"); // ✅ In token để kiểm tra

                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setString('userId',
                              userId); // ✅ Lưu userId vào SharedPreferences
                          await prefs.setString('token',
                              token); // ✅ Lưu token vào SharedPreferences

                          setState(() {
                            _username = result['username'];
                          });

                          _showMessage(context, "Login Successful!");
                          Navigator.pop(context);
                        } else {
                          print(
                              "🚨 Lỗi: userId hoặc token không có trong result!");
                        }
                      } else {
                        print("🚨 Lỗi: Response không có key 'result'!");
                      }
                    } else {
                      _showMessage(
                          context, "Login Failed! Check your credentials.");
                    }
                  },
                  style: _buttonStyle(),
                  child: const Text("LOG IN",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                Center(
                  child: Column(
                    children: [
                      if (_username == null)
                        GestureDetector(
                          onTap: () {
                            // Navigate to the ForgotPasswordPage when the text is tapped
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                            );
                          },
                          child: const Text(
                            "Forgot password.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue, // Set the text color to blue
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Đóng popup đăng nhập
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _showSignUpDialog(context); // Mở popup đăng ký
                          });
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Colors.black, fontSize: 16),
                            children: [
                              TextSpan(
                                text: "Join",
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Me"),
        centerTitle: true,
        actions: [
          if (_username != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: "Logout",
            ),
        ],
      ),
      body: SingleChildScrollView(
        // Sử dụng SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Nếu đã đăng nhập, hiển thị Welcome
              if (_username != null)
                Column(
                  children: [
                    Text(
                      "Welcome, $_username!",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              // Nếu chưa đăng nhập, hiển thị nội dung gốc
              if (_username == null)
                const Text(
                  "Log in to save items, follow searches, place bids, and register for auctions.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 20),

              // Nút đăng nhập hoặc đăng xuất
              if (_username == null)
                ElevatedButton(
                  onPressed: () => _showLoginDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  child: const Text("LOG IN",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              if (_username != null)
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  child: const Text("LOG OUT",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),

              const SizedBox(height: 30),
              const Divider(),

              // Các mục chỉ hiển thị khi người dùng đã đăng nhập
              if (_username != null) ...[
                _buildListTile("My Account", () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String? username = prefs.getString('username') ?? "Guest";
                  String? userId = prefs.getString('userId') ?? "Unknown ID";
                  String? token = prefs.getString('token') ?? "No Token";

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyAccountPage(
                      username: username,
                      userId: userId,
                      token: token,
                    )),
                  );
                }),
                _buildListTile("Create Auction", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateAuctionItemsPage()),
                  );
                }),
                _buildListTile("Won Items", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const WonItemsPage()), // ✅ Chuyển đến trang Won Items
                  );
                }),
                _buildListTile("Notifications", () {}),
                _buildListTile("Message", () {}),
                _buildListTile("Device Settings", () {

                }),

                const Divider(),
              ],

              _buildListTile("Help Center", () {}),
              _buildListTile("Send App Feedback", () {}),

              const Divider(),
              _buildListTile("About LiveAuctioneers", () {}),
              _buildListTile("Terms & Conditions", () {}),
              _buildListTile("Privacy Policy", () {}),
              _buildListTile("Cookie Policy", () {}),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  "version: 6.4.2 v294\nstore version: 6.4.2",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap, // Gọi hàm điều hướng
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.teal,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
