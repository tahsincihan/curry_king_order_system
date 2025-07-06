import 'dart:convert';
import 'package:http/http.dart' as http;

class PostcodeService {
  final String apiKey;

  PostcodeService(this.apiKey);

  Future<List<String>> getAddresses(String postcode) async {
    final url = Uri.parse(
        'https://api.getAddress.io/find/$postcode?api-key=$apiKey&expand=true');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> addresses = data['addresses'];
        // Corrected the mapping to properly handle the string from the API
        return addresses
            .map((address) => address['formatted_address'] as String)
            .toList();
      } else {
        // Handle API errors (e.g., invalid postcode, API key issues)
        print('API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // Handle network errors
      print('Network Error: $e');
      return [];
    }
  }
}
