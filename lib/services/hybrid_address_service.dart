import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show sin, cos, sqrt, atan2, pi;

enum AddressProvider { getAddress, postcodesIo, manual }

class AddressLookupResult {
  final List<String> addresses;
  final AddressProvider provider;
  final bool success;
  final String? error;
  final Map<String, dynamic>? geocodingData;

  AddressLookupResult({
    required this.addresses,
    required this.provider,
    required this.success,
    this.error,
    this.geocodingData,
  });
}

class HybridAddressService {
  final String? getAddressApiKey;
  static const String postcodesIoBaseUrl = 'https://api.postcodes.io';
  
  // Restaurant location for delivery radius calculations (Devon, England)
  static const double restaurantLatitude = 50.721344;  // Your restaurant location
  static const double restaurantLongitude = -3.505041; // Your restaurant location
  static const double maxDeliveryRadiusKm = 8.0; // 8km delivery radius

  HybridAddressService(this.getAddressApiKey);

  /// PRIMARY METHOD: Intelligent address lookup with fallbacks
  Future<AddressLookupResult> lookupAddresses(String postcode) async {
    if (postcode.isEmpty) {
      return AddressLookupResult(
        addresses: [],
        provider: AddressProvider.manual,
        success: false,
        error: 'Postcode is required',
      );
    }

    // Step 1: Try GetAddress.io first (if API key available)
    if (getAddressApiKey != null && getAddressApiKey!.isNotEmpty) {
      print('🔍 Trying GetAddress.io first...');
      try {
        final getAddressResult = await _tryGetAddressIo(postcode);
        if (getAddressResult.success && getAddressResult.addresses.isNotEmpty) {
          print('✅ GetAddress.io success: ${getAddressResult.addresses.length} addresses');
          
          // Still check delivery radius for GetAddress results
          final withRadius = await _addDeliveryRadiusCheck(getAddressResult, postcode);
          return withRadius;
        } else {
          print('⚠️ GetAddress.io failed or no addresses found');
        }
      } catch (e) {
        print('❌ GetAddress.io error: $e');
      }
    } else {
      print('⚠️ No GetAddress.io API key available, skipping...');
    }

    // Step 2: Fallback to Postcodes.io for validation and geocoding
    print('🔍 Falling back to Postcodes.io...');
    try {
      final postcodesIoResult = await _tryPostcodesIo(postcode);
      if (postcodesIoResult.success) {
        print('✅ Postcodes.io success: Postcode validated');
        return postcodesIoResult;
      } else {
        print('⚠️ Postcodes.io failed');
      }
    } catch (e) {
      print('❌ Postcodes.io error: $e');
    }

    // Step 3: Final fallback - manual entry with basic validation
    print('🔍 Using manual entry fallback...');
    final isValidFormat = isValidUKPostcodeFormat(postcode);
    
    return AddressLookupResult(
      addresses: isValidFormat ? _getMockAddresses(postcode) : [],
      provider: AddressProvider.manual,
      success: isValidFormat,
      error: isValidFormat 
        ? 'Address lookup services unavailable. Using sample addresses.'
        : 'Invalid postcode format. Please check and try again.',
    );
  }

  /// Add delivery radius checking to GetAddress.io results
  Future<AddressLookupResult> _addDeliveryRadiusCheck(AddressLookupResult result, String postcode) async {
    try {
      // Get postcode coordinates from Postcodes.io for radius check
      final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
      final url = Uri.parse('$postcodesIoBaseUrl/postcodes/$cleanPostcode');
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['result'] != null) {
          final postcodeData = data['result'];
          final isWithinRadius = await _checkDeliveryRadius(postcodeData);
          
          return AddressLookupResult(
            addresses: result.addresses,
            provider: result.provider,
            success: result.success && isWithinRadius,
            error: isWithinRadius ? null : 'This postcode is outside our delivery area.',
            geocodingData: {
              ...postcodeData,
              'within_delivery_radius': isWithinRadius,
              'distance_km': _calculateDistance(
                restaurantLatitude, restaurantLongitude,
                postcodeData['latitude'], postcodeData['longitude']
              ).toStringAsFixed(2),
            },
          );
        }
      }
    } catch (e) {
      print('Warning: Could not check delivery radius: $e');
    }
    
    // Return original result if radius check fails
    return result;
  }

  /// Try GetAddress.io API for full address lookup
  Future<AddressLookupResult> _tryGetAddressIo(String postcode) async {
    final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
    
    // Try autocomplete endpoint first (as user suggested)
    try {
      final autocompleteUrl = Uri.parse(
        'https://api.getaddress.io/autocomplete/$cleanPostcode?api-key=$getAddressApiKey&all=true'
      );
      
      print('Trying GetAddress autocomplete: $autocompleteUrl');
      
      final response = await http.get(autocompleteUrl).timeout(
        const Duration(seconds: 10),
      );

      print('GetAddress autocomplete response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final addresses = _parseGetAddressResponse(response.body, 'autocomplete');
        if (addresses.isNotEmpty) {
          return AddressLookupResult(
            addresses: addresses,
            provider: AddressProvider.getAddress,
            success: true,
          );
        }
      }
    } catch (e) {
      print('GetAddress autocomplete failed: $e');
    }

    // Fallback to find endpoint
    try {
      final findUrl = Uri.parse(
        'https://api.getaddress.io/find/$cleanPostcode?api-key=$getAddressApiKey'
      );
      
      print('Trying GetAddress find: $findUrl');
      
      final response = await http.get(findUrl).timeout(
        const Duration(seconds: 10),
      );

      print('GetAddress find response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final addresses = _parseGetAddressResponse(response.body, 'find');
        return AddressLookupResult(
          addresses: addresses,
          provider: AddressProvider.getAddress,
          success: addresses.isNotEmpty,
          error: addresses.isEmpty ? 'No addresses found for this postcode' : null,
        );
      } else if (response.statusCode == 404) {
        return AddressLookupResult(
          addresses: [],
          provider: AddressProvider.getAddress,
          success: false,
          error: 'Postcode not found in GetAddress.io database',
        );
      } else if (response.statusCode == 401) {
        return AddressLookupResult(
          addresses: [],
          provider: AddressProvider.getAddress,
          success: false,
          error: 'GetAddress.io API key invalid or expired',
        );
      }
    } catch (e) {
      print('GetAddress find failed: $e');
    }

    return AddressLookupResult(
      addresses: [],
      provider: AddressProvider.getAddress,
      success: false,
      error: 'GetAddress.io service temporarily unavailable',
    );
  }

  /// Try Postcodes.io for validation and geocoding (no addresses)
  Future<AddressLookupResult> _tryPostcodesIo(String postcode) async {
    final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
    final url = Uri.parse('$postcodesIoBaseUrl/postcodes/$cleanPostcode');

    try {
      print('Trying Postcodes.io: $url');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 8),
      );

      print('Postcodes.io response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['result'] != null) {
          final postcodeData = data['result'];
          
          // Check if within delivery radius
          final isWithinRadius = await _checkDeliveryRadius(postcodeData);
          final distance = _calculateDistance(
            restaurantLatitude, restaurantLongitude,
            postcodeData['latitude'], postcodeData['longitude']
          );
          
          return AddressLookupResult(
            addresses: [], // Postcodes.io doesn't provide individual addresses
            provider: AddressProvider.postcodesIo,
            success: true,
            geocodingData: {
              ...postcodeData,
              'within_delivery_radius': isWithinRadius,
              'distance_km': distance.toStringAsFixed(2),
            },
            error: isWithinRadius 
              ? 'Postcode validated (${distance.toStringAsFixed(1)}km away). Please enter your full address manually.'
              : 'Sorry, this postcode is ${distance.toStringAsFixed(1)}km away, outside our ${maxDeliveryRadiusKm}km delivery area.',
          );
        }
      } else if (response.statusCode == 404) {
        return AddressLookupResult(
          addresses: [],
          provider: AddressProvider.postcodesIo,
          success: false,
          error: 'Postcode not found in UK postcode database',
        );
      }
    } catch (e) {
      print('Postcodes.io error: $e');
    }

    return AddressLookupResult(
      addresses: [],
      provider: AddressProvider.postcodesIo,
      success: false,
      error: 'Postcode validation service temporarily unavailable',
    );
  }

  /// Parse GetAddress.io response formats
  List<String> _parseGetAddressResponse(String responseBody, String endpoint) {
    List<String> addresses = [];
    
    try {
      final data = json.decode(responseBody);
      
      if (endpoint == 'autocomplete') {
        // Handle multiple possible autocomplete response formats
        if (data['suggestions'] != null && data['suggestions'] is List) {
          for (var suggestion in data['suggestions']) {
            if (suggestion is Map && suggestion['address'] != null) {
              addresses.add(suggestion['address'] as String);
            } else if (suggestion is String) {
              addresses.add(suggestion);
            }
          }
        } else if (data['addresses'] != null && data['addresses'] is List) {
          for (var address in data['addresses']) {
            if (address is String) {
              addresses.add(address);
            }
          }
        }
      } else if (endpoint == 'find') {
        // Handle find response format
        if (data['Addresses'] != null && data['Addresses'] is List) {
          for (var address in data['Addresses']) {
            if (address is String) {
              addresses.add(address);
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing GetAddress response: $e');
    }
    
    print('Parsed ${addresses.length} addresses from $endpoint endpoint');
    return addresses;
  }

  /// Check if postcode is within delivery radius
  Future<bool> _checkDeliveryRadius(Map<String, dynamic> postcodeData) async {
    final latitude = postcodeData['latitude'] as double?;
    final longitude = postcodeData['longitude'] as double?;

    if (latitude == null || longitude == null) {
      print('Warning: No coordinates available for delivery radius check');
      return true; // Allow if we can't check
    }

    final distance = _calculateDistance(
      restaurantLatitude, restaurantLongitude,
      latitude, longitude
    );

    print('Distance to postcode: ${distance.toStringAsFixed(2)}km (max: ${maxDeliveryRadiusKm}km)');
    return distance <= maxDeliveryRadiusKm;
  }

  /// Calculate distance between coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2));
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180);

  /// Validate UK postcode format
  bool isValidUKPostcodeFormat(String postcode) {
    if (postcode.isEmpty) return false;
    
    final cleaned = postcode.replaceAll(' ', '').toUpperCase();
    final regex = RegExp(r'^[A-Z]{1,2}[0-9][A-Z0-9]?[0-9][A-Z]{2}$');
    
    return regex.hasMatch(cleaned);
  }

  /// Format postcode with proper spacing
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

  /// Get user-friendly provider name
  String getProviderName(AddressProvider provider) {
    switch (provider) {
      case AddressProvider.getAddress:
        return 'GetAddress.io';
      case AddressProvider.postcodesIo:
        return 'Postcodes.io';
      case AddressProvider.manual:
        return 'Manual Entry';
    }
  }

  /// Get mock addresses for testing when APIs are unavailable
  List<String> _getMockAddresses(String postcode) {
    final formattedPostcode = formatPostcode(postcode);
    
    return [
      '1 High Street, Sample Town, $formattedPostcode',
      '2 Main Road, Sample Town, $formattedPostcode',
      '3 Church Lane, Sample Town, $formattedPostcode',
      '4 Victoria Street, Sample Town, $formattedPostcode',
      '5 The Green, Sample Town, $formattedPostcode',
    ];
  }
}