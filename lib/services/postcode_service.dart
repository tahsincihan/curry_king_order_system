import 'dart:convert';
import 'package:http/http.dart' as http;

class PostcodeService {
  final String? apiKey;

  PostcodeService(this.apiKey);

  Future<List<String>> getAddresses(String postcode) async {
    // Check if API key is available
    if (apiKey == null || apiKey!.isEmpty) {
      print('Warning: No API key provided for postcode service');
      return getMockAddresses(postcode);
    }

    // Clean up postcode (remove spaces, convert to uppercase)
    final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
    
    if (cleanPostcode.isEmpty) {
      return [];
    }

    // Try different endpoints in order of preference
    List<String> addresses = [];
    
    // First try the autocomplete endpoint (user suggested)
    addresses = await tryAutocompleteEndpoint(cleanPostcode);
    if (addresses.isNotEmpty && !addresses.first.contains('Sample Town')) {
      print('✓ Using autocomplete endpoint successfully');
      return addresses;
    }

    // If autocomplete doesn't work, try find endpoint
    addresses = await tryFindEndpoint(cleanPostcode);
    if (addresses.isNotEmpty && !addresses.first.contains('Sample Town')) {
      print('✓ Using find endpoint successfully');
      return addresses;
    }

    // If both fail, try the get endpoint (if we have postcode suggestions)
    addresses = await tryGetEndpoint(cleanPostcode);
    if (addresses.isNotEmpty && !addresses.first.contains('Sample Town')) {
      print('✓ Using get endpoint successfully');
      return addresses;
    }

    // If all endpoints fail, return mock data
    print('⚠ All endpoints failed, using mock data');
    return getMockAddresses(postcode);
  }

  // Try the /autocomplete endpoint (user suggested - test this first)
  Future<List<String>> tryAutocompleteEndpoint(String cleanPostcode) async {
    try {
      print('Trying /autocomplete endpoint for postcode: $cleanPostcode');
      
      // Try with all=true parameter
      final url = Uri.parse(
          'https://api.getaddress.io/autocomplete/$cleanPostcode?api-key=$apiKey&all=true');

      print('Autocomplete URL: $url');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      print('Autocomplete response status: ${response.statusCode}');
      print('Autocomplete response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addresses = parseAutocompleteResponse(data);
        if (addresses.isNotEmpty) {
          return addresses;
        }
      } else if (response.statusCode == 404) {
        print('Autocomplete endpoint: Postcode not found');
        return [];
      } else if (response.statusCode == 401) {
        print('Autocomplete endpoint: Invalid API key');
        throw Exception('Invalid API key for autocomplete endpoint');
      } else {
        print('Autocomplete endpoint failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Autocomplete endpoint error: $e');
      return [];
    }
    
    return [];
  }

  // Try the main /find endpoint
  Future<List<String>> tryFindEndpoint(String cleanPostcode) async {
    try {
      print('Trying /find endpoint for postcode: $cleanPostcode');
      
      final url = Uri.parse(
          'https://api.getaddress.io/find/$cleanPostcode?api-key=$apiKey');

      print('Find URL: $url');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      print('Find response status: ${response.statusCode}');
      print('Find response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return parseAddressResponse(data, 'find');
      } else if (response.statusCode == 404) {
        print('Find endpoint: Postcode not found');
        return [];
      } else if (response.statusCode == 401) {
        print('Find endpoint: Invalid API key');
        throw Exception('Invalid API key for find endpoint');
      } else {
        print('Find endpoint failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Find endpoint error: $e');
      return [];
    }
  }

  // Try the /get endpoint (requires address ID)
  Future<List<String>> tryGetEndpoint(String cleanPostcode) async {
    // This endpoint requires an address ID, which we don't have
    // So we'll skip this for now unless we get IDs from autocomplete
    print('Get endpoint not implemented - requires address ID');
    return [];
  }

  // Parse autocomplete response (different format)
  List<String> parseAutocompleteResponse(dynamic data) {
    List<String> addresses = [];
    
    try {
      if (data is Map<String, dynamic>) {
        print('Parsing autocomplete response as Map');
        
        // Format 1: suggestions array
        if (data['suggestions'] != null && data['suggestions'] is List) {
          print('Found suggestions array with ${data['suggestions'].length} items');
          for (var suggestion in data['suggestions']) {
            if (suggestion is Map && suggestion['address'] != null) {
              addresses.add(suggestion['address'] as String);
            } else if (suggestion is String) {
              addresses.add(suggestion);
            } else if (suggestion is Map && suggestion['text'] != null) {
              addresses.add(suggestion['text'] as String);
            }
          }
        }
        
        // Format 2: direct addresses array
        else if (data['addresses'] != null && data['addresses'] is List) {
          print('Found addresses array with ${data['addresses'].length} items');
          for (var address in data['addresses']) {
            if (address is String) {
              addresses.add(address);
            } else if (address is Map && address['formatted_address'] != null) {
              addresses.add(address['formatted_address'] as String);
            }
          }
        }
        
        // Format 3: predictions array (Google-style)
        else if (data['predictions'] != null && data['predictions'] is List) {
          print('Found predictions array with ${data['predictions'].length} items');
          for (var prediction in data['predictions']) {
            if (prediction is Map && prediction['description'] != null) {
              addresses.add(prediction['description'] as String);
            } else if (prediction is String) {
              addresses.add(prediction);
            }
          }
        }
        
        // Format 4: Direct array response
        else if (data['results'] != null && data['results'] is List) {
          print('Found results array with ${data['results'].length} items');
          for (var result in data['results']) {
            if (result is String) {
              addresses.add(result);
            } else if (result is Map && result['formatted_address'] != null) {
              addresses.add(result['formatted_address'] as String);
            }
          }
        }
      }
      
      // Format 5: Response might be directly an array
      else if (data is List) {
        print('Parsing autocomplete response as direct List with ${data.length} items');
        for (var address in data) {
          if (address is String) {
            addresses.add(address);
          } else if (address is Map && address['address'] != null) {
            addresses.add(address['address'] as String);
          } else if (address is Map && address['formatted_address'] != null) {
            addresses.add(address['formatted_address'] as String);
          }
        }
      }
      
      print('Autocomplete endpoint parsed ${addresses.length} addresses');
      return addresses;
      
    } catch (e) {
      print('Error parsing autocomplete response: $e');
      return [];
    }
  }

  // Parse standard address response (for /find endpoint)
  List<String> parseAddressResponse(dynamic data, String endpoint) {
    List<String> addresses = [];
    
    try {
      if (data is Map<String, dynamic>) {
        print('Parsing $endpoint response as Map');
        
        // Format 1: Addresses array (standard GetAddress.io format)
        if (data['Addresses'] != null && data['Addresses'] is List) {
          print('Found Addresses array with ${data['Addresses'].length} items');
          for (var address in data['Addresses']) {
            if (address is String) {
              addresses.add(address);
            }
          }
        }
        
        // Format 2: addresses array (lowercase)
        else if (data['addresses'] != null && data['addresses'] is List) {
          print('Found addresses array with ${data['addresses'].length} items');
          for (var address in data['addresses']) {
            if (address is String) {
              addresses.add(address);
            } else if (address is Map && address['formatted_address'] != null) {
              addresses.add(address['formatted_address'] as String);
            }
          }
        }
      }
      
      // Format 3: Direct array response
      else if (data is List) {
        print('Parsing $endpoint response as direct List with ${data.length} items');
        for (var address in data) {
          if (address is String) {
            addresses.add(address);
          } else if (address is Map && address['formatted_address'] != null) {
            addresses.add(address['formatted_address'] as String);
          }
        }
      }
      
      print('$endpoint endpoint parsed ${addresses.length} addresses');
      return addresses;
      
    } catch (e) {
      print('Error parsing $endpoint response: $e');
      return [];
    }
  }

  // Enhanced mock addresses
  List<String> getMockAddresses(String postcode) {
    print('Using mock addresses for postcode: $postcode');
    
    final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
    
    if (cleanPostcode.isEmpty) {
      return [];
    }

    final formattedPostcode = formatPostcode(cleanPostcode);
    
    return [
      '1 High Street, Sample Town, $formattedPostcode',
      '2 Main Road, Sample Town, $formattedPostcode',
      '3 Church Lane, Sample Town, $formattedPostcode',
      '4 Victoria Street, Sample Town, $formattedPostcode',
      '5 The Green, Sample Town, $formattedPostcode',
    ];
  }

  // Test all endpoints
  Future<Map<String, dynamic>> testAllEndpoints() async {
    if (apiKey == null || apiKey!.isEmpty) {
      return {
        'status': 'error',
        'message': 'No API key provided',
      };
    }

    final testPostcode = 'SW1A1AA';
    Map<String, dynamic> results = {
      'postcode': testPostcode,
      'endpoints': {},
    };

    // Test /autocomplete endpoint (test this first since user suggested it)
    try {
      print('Testing /autocomplete endpoint...');
      final autocompleteUrl = Uri.parse(
          'https://api.getaddress.io/autocomplete/$testPostcode?api-key=$apiKey&all=true');
      final autocompleteResponse = await http.get(autocompleteUrl).timeout(
        const Duration(seconds: 5),
      );
      
      results['endpoints']['autocomplete'] = {
        'status': autocompleteResponse.statusCode,
        'success': autocompleteResponse.statusCode == 200,
        'response': autocompleteResponse.body.length > 200 
            ? '${autocompleteResponse.body.substring(0, 200)}...' 
            : autocompleteResponse.body,
        'url': autocompleteUrl.toString(),
      };
      
      print('Autocomplete test result: ${autocompleteResponse.statusCode}');
    } catch (e) {
      results['endpoints']['autocomplete'] = {
        'status': 'error',
        'success': false,
        'error': e.toString(),
      };
      print('Autocomplete test error: $e');
    }

    // Test /find endpoint
    try {
      print('Testing /find endpoint...');
      final findUrl = Uri.parse(
          'https://api.getaddress.io/find/$testPostcode?api-key=$apiKey');
      final findResponse = await http.get(findUrl).timeout(
        const Duration(seconds: 5),
      );
      
      results['endpoints']['find'] = {
        'status': findResponse.statusCode,
        'success': findResponse.statusCode == 200,
        'response': findResponse.body.length > 200 
            ? '${findResponse.body.substring(0, 200)}...' 
            : findResponse.body,
        'url': findUrl.toString(),
      };
      
      print('Find test result: ${findResponse.statusCode}');
    } catch (e) {
      results['endpoints']['find'] = {
        'status': 'error',
        'success': false,
        'error': e.toString(),
      };
      print('Find test error: $e');
    }

    return results;
  }

  // Validate postcode format
  bool isValidUKPostcode(String postcode) {
    if (postcode.isEmpty) return false;
    
    final cleaned = postcode.replaceAll(' ', '').toUpperCase();
    final regex = RegExp(r'^[A-Z]{1,2}[0-9][A-Z0-9]?[0-9][A-Z]{2}$');
    
    return regex.hasMatch(cleaned);
  }

  // Format postcode properly
  String formatPostcode(String postcode) {
    if (postcode.isEmpty) return postcode;
    
    final cleaned = postcode.replaceAll(' ', '').toUpperCase();
    
    if (cleaned.length >= 3) {
      final firstPart = cleaned.substring(0, cleaned.length - 3);
      final lastPart = cleaned.substring(cleaned.length - 3);
      return '$firstPart $lastPart';
    }
    
    return cleaned;
  }

  // Simple connectivity test
  Future<bool> testApiConnection() async {
    if (apiKey == null || apiKey!.isEmpty) {
      print('No API key available for testing');
      return false;
    }

    try {
      // Test with autocomplete first (user's suggestion)
      final testPostcode = 'SW1A1AA';
      final url = Uri.parse(
          'https://api.getaddress.io/autocomplete/$testPostcode?api-key=$apiKey&all=true');

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );

      print('Simple API test - Status: ${response.statusCode}');
      print('Simple API test - Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Simple API test failed: $e');
      return false;
    }
  }
}