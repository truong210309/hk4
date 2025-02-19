import 'dart:convert';
import 'dart:ffi';
import 'package:fe/models/Auction_Items.dart';
import 'package:fe/pages/MyAuctionPage.dart';
import 'package:fe/services/ApiAuction_ItemsService.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fe/models/Category.dart';
import 'package:fe/services/ApiCategoryService.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateAuctionItemsPage extends StatefulWidget {
  const CreateAuctionItemsPage({super.key});

  @override
  State createState() => _CreateAuctionItemsPageState();
}

class _CreateAuctionItemsPageState extends State {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _startingPriceController =
      TextEditingController();
  final TextEditingController _bidStepController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Category? _selectedCategory;
  List<Category> _categories = [];
  DateTime? _startDate;
  DateTime? _endDate;
  final List<File> _images = [];
  String? currentUserId;
  double? _currentPrice;
  bool _isPickingImage = false; // Add this flag

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    getCurrentUserId(); // Fetch user ID when the page initializes
  }

  void getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("userId");

    setState(() {
      currentUserId = userId;
    });

    print("🆔 Retrieved Seller ID: $currentUserId"); // ✅ Check if it’s set
  }

  Future<void> _fetchCategories() async {
    try {
      ApiCategoryService apiService = ApiCategoryService();
      List<Category> categories = await apiService.getAllCategory();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future _pickDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return; // Prevent multiple openings
    _isPickingImage = true; // Set flag to true

    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)));
      });
    } catch (e) {
      print("🔥 Error picking images: $e");
    } finally {
      _isPickingImage = false; // Reset flag after process
    }
  }

  Future<void> _submitAuctionItem() async {
    if (_itemNameController.text.isEmpty ||
        _startingPriceController.text.isEmpty ||
        _bidStepController.text.isEmpty ||
        _selectedCategory == null ||
        _startDate == null ||
        _endDate == null ||
        _images.isEmpty) {
      // ✅ Ensure at least one image is selected
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Please fill all required fields and upload at least one image")));
      return;
    }

    if (double.tryParse(_startingPriceController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid starting price")));
      return;
    }

    if (double.tryParse(_bidStepController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid bid step")));
      return;
    }

    print("Seller ID before submission: $currentUserId");
    if (currentUserId == null) {
      print("❌ User ID is NULL. Aborting submission.");
    }

    if (currentUserId == null) {
      print("❌ User ID is not loaded yet.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("User ID is not available, please try again.")));
      return;
    }

    // ✅ Step 1: Upload images to Cloudinary and get URLs
    List<String> uploadedImageUrls = [];
    for (var file in _images) {
      String? imageUrl = await uploadImageToCloudinary(file);
      if (imageUrl != null) {
        uploadedImageUrls.add(imageUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Failed to upload some images. Please try again.")));
        return;
      }
    }

    // ✅ Step 2: Create Auction Item with image URLs instead of Base64
    AuctionItems newItem = AuctionItems(
      itemName: _itemNameController.text,
      startingPrice: double.parse(_startingPriceController.text),
      bidStep: (_bidStepController.text),
      description: _descriptionController.text,
      startDate: _startDate != null
          ? DateTime.parse(DateFormat('yyyy-MM-dd').format(_startDate!))
          : null,
      endDate: _endDate != null
          ? DateTime.parse(DateFormat('yyyy-MM-dd').format(_endDate!))
          : null,
      images: uploadedImageUrls, // ✅ Now using URLs instead of Base64
      currentPrice: _currentPrice,
      sellerId: currentUserId,
    );

    Map<String, dynamic> itemData = newItem.toJson();
    itemData.removeWhere((key, value) => value == null);
    itemData['category_id'] = _selectedCategory?.category_id;
    itemData['images'] = uploadedImageUrls;

    itemData['start_date'] = _startDate != null
        ? DateFormat('yyyy-MM-dd').format(_startDate!)
        : null;
    itemData['end_date'] =
        _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;
    // 🚀 Log auction item details
    print("📌 Final Auction Item Data: ${jsonEncode(itemData)}");

    try {
      bool success = await ApiAuction_ItemsService().createAuctionItem(
          _itemNameController.text,
          itemData,
          _images.first // ✅ Pass the first image file
          );

      if (success) {
        print("🚀 _submitAuctionItem() function called!"); // ✅ Debugging
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Auction item created successfully")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyAuctionPage(userId: currentUserId ?? ''),
          ),
        );
      } else {
        print("🚨 Failed to create auction item!");
        print("📦 Request Payload: ${jsonEncode(itemData)}");
        print("🔗 API Endpoint: /api/auction/add");

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to create auction item")));
      }
    } catch (e, stacktrace) {
      print("🔥 Exception occurred: $e");
      print("📜 Stacktrace: $stacktrace");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("An error occurred while creating the auction item.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Auction Item")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputBox("Item Name", _itemNameController),
              _buildDropdown(),
              _buildInputBox("Starting Price", _startingPriceController,
                  isNumber: true),
              _buildInputBox("Bid Step", _bidStepController),
              _buildInputBox("Description", _descriptionController,
                  isMultiline: true),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker("Start Date", _startDate,
                        () => _pickDate(context, true)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDatePicker(
                        "End Date", _endDate, () => _pickDate(context, false)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildImagePicker(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAuctionItem,
                  child: const Text("Create Auction Item"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBox(String label, TextEditingController controller,
      {bool isNumber = false, bool isMultiline = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: isMultiline ? 3 : 1,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Category>(
          isExpanded: true,
          hint: const Text("Select Category"),
          value: _selectedCategory,
          onChanged: (Category? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
          items: _categories.map((Category category) {
            return DropdownMenuItem<Category>(
              value: category,
              child: Text(category.category_name ?? "Unknown"),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, VoidCallback onTap) {
    String formattedDate =
        date != null ? DateFormat('yyyy-MM-dd').format(date) : label;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          formattedDate, // Display formatted date instead of raw DateTime object
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (!_isPickingImage) {
              _pickImage();
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
                child: Text("Add Images", style: TextStyle(fontSize: 16))),
          ),
        ),
        const SizedBox(height: 10),
        // Show selected images
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _images.map((image) {
            return Stack(
              children: [
                Image.file(image, width: 100, height: 100, fit: BoxFit.cover),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _images.remove(image);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

Future<String?> uploadImageToCloudinary(File imageFile) async {
  const String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/dbt0u51ib/image/upload";
  const String uploadPreset = "duyhau"; // Set in Cloudinary settings

  try {
    var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();
    var responseData = jsonDecode(await response.stream.bytesToString());

    if (response.statusCode == 200) {
      print("✅ Cloudinary Upload Success: ${responseData['secure_url']}");
      return responseData['secure_url']; // ✅ Return Cloudinary image URL
    } else {
      print("❌ Cloudinary Upload Failed: ${responseData['error']['message']}");
      return null;
    }
  } catch (e) {
    print("🔥 Exception during Cloudinary upload: $e");
    return null;
  }
}
