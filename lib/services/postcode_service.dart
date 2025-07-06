import 'dart:convert';
import 'package:http/http.dart' as http;

class PostcodeService {
  final String? apiKey;

  PostcodeService(this.apiKey);

  Future<List<String>> getAddresses(String postcode) async {
    // Check if API key is available
    if (apiKey == null || apiKey!.isEmpty) {
      print('Warning: No API key provided for postcode service');
      return _getMockAddresses(postcode);
    }

    // Clean up postcode (remove spaces, convert to uppercase)
    final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
    
    if (cleanPostcode.isEmpty) {
      return [];
    }

    final url = Uri.parse(
        'https://api.getAddress.io/find/$cleanPostcode?api-key=$apiKey&expand=true');

    try {
      print('Fetching addresses for postcode: $cleanPostcode');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if addresses field exists and is not null
        if (data['addresses'] != null) {
          final List<dynamic> addresses = data['addresses'];
          
          // Map addresses and handle potential null values
          return addresses
              .where((address) => address['formatted_address'] != null)
              .map((address) => address['formatted_address'] as String)
              .toList();
        } else {
          print('No addresses found in API response');
          return [];
        }
      } else if (response.statusCode == 401) {
        print('API Error: Invalid API key');
        return _getMockAddresses(postcode);
      } else if (response.statusCode == 404) {
        print('API Error: Postcode not found');
        return [];
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return _getMockAddresses(postcode);
      }
    } catch (e) {
      print('Network Error: $e');
      // Return mock addresses as fallback
      return _getMockAddresses(postcode);
    }
  }

  // Provide mock addresses as fallback when API is unavailable
  List<String> _getMockAddresses(String postcode) {
    print('Using mock addresses for postcode: $postcode');
    
    // Clean up postcode for mock generation
    final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
    
    if (cleanPostcode.isEmpty) {
      return [];
    }

    // Generate some mock addresses based on postcode pattern
    final postcodeArea = cleanPostcode.length >= 2 ? cleanPostcode.substring(0, 2) : 'XX';
    
    return [
      '1 High Street, Sample Town, $cleanPostcode',
      '2 Main Road, Sample Town, $cleanPostcode',
      '3 Church Lane, Sample Town, $cleanPostcode',
      '4 Victoria Street, Sample Town, $cleanPostcode',
      '5 The Green, Sample Town, $cleanPostcode',
    ];
  }

  // Validate postcode format (basic UK postcode validation)
  bool isValidUKPostcode(String postcode) {
    if (postcode.isEmpty) return false;
    
    // Remove spaces and convert to uppercase
    final cleaned = postcode.replaceAll(' ', '').toUpperCase();
    
    // Basic UK postcode regex pattern
    final regex = RegExp(r'^[A-Z]{1,2}[0-9][A-Z0-9]?[0-9][A-Z]{2}$');
    
    return regex.hasMatch(cleaned);
  }

  // Format postcode properly (add space if missing)
  String formatPostcode(String postcode) {
    if (postcode.isEmpty) return postcode;
    
    final cleaned = postcode.replaceAll(' ', '').toUpperCase();
    
    if (cleaned.length >= 3) {
      // Insert space before last 3 characters
      final firstPart = cleaned.substring(0, cleaned.length - 3);
      final lastPart = cleaned.substring(cleaned.length - 3);
      return '$firstPart $lastPart';
    }
    
    return cleaned;
  }
}