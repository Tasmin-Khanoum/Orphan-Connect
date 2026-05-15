import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageService {
  // Replace with YOUR imgbb API Key
  static const String _imgbbApiKey = 'de171cfffc79338a7c44a99fe647b511';

  // Upload image to imgbb
  static Future<String?> uploadImage(File imageFile) async {
    try {
      print('Starting image upload...');

      // Read image as bytes
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('Image encoded, uploading to imgbb...');

      // Upload to imgbb
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
        body: {
          'image': base64Image,
        },
      );

      print('Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['data']['url'];
        print('✅ Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  // Generate placeholder avatar
  static String generateAvatar(String name, {String gender = 'Male'}) {
    final colors = {
      'Male': '6C63FF',
      'Female': 'FF6584',
    };
    final bgColor = colors[gender] ?? '6C63FF';
    final encodedName = Uri.encodeComponent(name);
    return 'https://ui-avatars.com/api/?name=$encodedName&size=512&background=$bgColor&color=fff&bold=true&rounded=true';
  }
}