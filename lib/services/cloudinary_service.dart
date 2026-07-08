import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImgBBService {
  static const String _apiKey = 'c99e6d1c7962f823480c297b0ee42608';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  static Future<String?> uploadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_uploadUrl),
        body: {
          'key': _apiKey,
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['url'] as String;
        }
      }

      debugPrint('ImgBB upload failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('ImgBB upload error: $e');
      return null;
    }
  }

  static Future<String?> uploadImageFromBytes(
    List<int> bytes, {
    String? fileName,
  }) async {
    try {
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_uploadUrl),
        body: {
          'key': _apiKey,
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['url'] as String;
        }
      }

      debugPrint('ImgBB upload failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('ImgBB upload error: $e');
      return null;
    }
  }

  static Future<String?> uploadImageBase64(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse(_uploadUrl),
        body: {
          'key': _apiKey,
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['url'] as String;
        }
      }

      debugPrint('ImgBB upload failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('ImgBB upload error: $e');
      return null;
    }
  }

  static Future<String?> safeUpload({
    File? file,
    List<int>? bytes,
    String? fileName,
  }) async {
    try {
      if (file != null) {
        return await uploadImage(file);
      } else if (bytes != null && bytes.isNotEmpty) {
        return await uploadImageFromBytes(bytes, fileName: fileName);
      }
      return null;
    } catch (e) {
      debugPrint('ImgBB safe upload error: $e');
      return null;
    }
  }
}
