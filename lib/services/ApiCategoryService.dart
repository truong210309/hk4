import 'dart:convert';
import 'package:fe/services/UrlAPI.dart';
import 'package:http/http.dart' as http;
import 'package:fe/models/Category.dart';

class ApiCategoryService {
  static const String urlCategory = "${UrlAPI.url}/category";
  // Get all Category entries
  Future<List<Category>> getAllCategory() async {
    try {
      final response = await http.get(Uri.parse(urlCategory));

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);

        if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('result')) {
          var resultData = jsonData['result'];

          if (resultData is Map<String, dynamic> &&
              resultData.containsKey('data')) {
            var categoryList = resultData['data'] as List;
            return categoryList.map((item) => Category.fromJson(item)).toList();
          }
        }
        throw Exception('Unexpected JSON format');
      } else {
        throw Exception(
            'Failed to load categories. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category data: $e');
    }
  }

  // Get a single Category by ID
  Future<Category?> getCategoryById(int id) async {
    try {
      final response = await http.get(Uri.parse("$urlCategory/$id"));

      if (response.statusCode == 200) {
        return Category.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null; // Return null if the category is not found
      } else {
        throw Exception(
            'Failed to load category. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category by ID: $e');
    }
  }
}

// cooooo
