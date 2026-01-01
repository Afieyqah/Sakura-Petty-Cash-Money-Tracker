import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;

class CloudinaryService {
  // Replace these with YOUR actual details from Cloudinary Dashboard
  static const String cloudName = "dttqbnib0";
  static const String uploadPreset = "receipt_preset";

  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url']; // This is the web link
      }
    } catch (e) {
      dev.log("Cloudinary Error", error: e);
    }
    return null;
  }
}
