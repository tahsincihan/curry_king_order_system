import 'package:hive_flutter/hive_flutter.dart';
import '../model/customer_model.dart';
import '../model/order_model.dart';

class CustomerService {
  static const String _customersBoxName = 'customers';
  static Box<Customer>? _customersBox;
  static bool _isInitialized = false;

  // Initialize the customer service
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('CustomerService already initialized');
      return;
    }

    try {
      print('Initializing CustomerService...');

      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CustomerAdapter());
        print('✓ CustomerAdapter registered');
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(CustomerAddressAdapter());
        print('✓ CustomerAddressAdapter registered');
      }

      // Open the customers box with retry logic
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          _customersBox = await Hive.openBox<Customer>(_customersBoxName);
          print('✓ Customers box opened successfully');
          break;
        } catch (e) {
          retryCount++;
          print('Error opening customers box (attempt $retryCount/$maxRetries): $e');
          
          if (retryCount == maxRetries) {
            // Last resort: try to delete corrupted box and create new one
            try {
              await Hive.deleteBoxFromDisk(_customersBoxName);
              print('Deleted corrupted customers box, creating new one...');
              _customersBox = await Hive.openBox<Customer>(_customersBoxName);
              print('✓ New customers box created successfully');
              break;
            } catch (e2) {
              print('Failed to create new customers box: $e2');
              throw Exception('Failed to initialize customer database after $maxRetries attempts');
            }
          } else {
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }

      _isInitialized = true;
      print('✓ CustomerService initialization completed successfully');
      
    } catch (e, stackTrace) {
      print('❌ Critical error during CustomerService initialization: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  // Check if service is initialized
  static bool get isInitialized => _isInitialized;

  // Generate unique customer ID
  static String _generateCustomerId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Normalize phone number for consistent storage and search
  static String _normalizePhoneNumber(String phone) {
    // Remove all non-digit characters
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  // Search customers by name (partial match, case insensitive)
  static List<Customer> searchByName(String query) {
    if (!_isInitialized || _customersBox == null || query.trim().isEmpty) {
      return [];
    }

    try {
      final normalizedQuery = query.toLowerCase().trim();
      return _customersBox!.values
          .where((customer) => 
              customer.name.toLowerCase().contains(normalizedQuery))
          .toList()
        ..sort((a, b) => b.lastOrderDate.compareTo(a.lastOrderDate));
    } catch (e) {
      print('Error searching customers by name: $e');
      return [];
    }
  }

  // Search customers by last 4 digits of phone number
  static List<Customer> searchByPhoneLastFour(String lastFour) {
    if (!_isInitialized || _customersBox == null || lastFour.trim().isEmpty) {
      return [];
    }

    try {
      final normalizedLastFour = _normalizePhoneNumber(lastFour);
      if (normalizedLastFour.length != 4) {
        return [];
      }

      return _customersBox!.values
          .where((customer) => 
              _normalizePhoneNumber(customer.phoneNumber).endsWith(normalizedLastFour))
          .toList()
        ..sort((a, b) => b.lastOrderDate.compareTo(a.lastOrderDate));
    } catch (e) {
      print('Error searching customers by phone: $e');
      return [];
    }
  }

  // Get customer by exact name and phone match
  static Customer? getCustomerByNameAndPhone(String name, String phone) {
    if (!_isInitialized || _customersBox == null) {
      return null;
    }

    try {
      final normalizedPhone = _normalizePhoneNumber(phone);
      return _customersBox!.values.firstWhereOrNull((customer) => 
          customer.name.toLowerCase() == name.toLowerCase() &&
          _normalizePhoneNumber(customer.phoneNumber) == normalizedPhone);
    } catch (e) {
      print('Error getting customer by name and phone: $e');
      return null;
    }
  }

  // Add or update customer with new address
  static Future<Customer> addOrUpdateCustomer({
    required String name,
    required String phone,
    required String address,
    required String postcode,
    double orderAmount = 0.0,
  }) async {
    if (!_isInitialized || _customersBox == null) {
      throw Exception('CustomerService not initialized');
    }

    try {
      // Check if customer already exists
      Customer? existingCustomer = getCustomerByNameAndPhone(name, phone);

      if (existingCustomer != null) {
        // Update existing customer
        existingCustomer.addOrUpdateAddress(address, postcode);
        if (orderAmount > 0) {
          existingCustomer.updateOrderStats(orderAmount);
        }
        await existingCustomer.save(); // Hive method to save changes
        print('Updated existing customer: ${existingCustomer.displayName}');
        return existingCustomer;
      } else {
        // Create new customer
        final newCustomer = Customer(
          id: _generateCustomerId(),
          name: name.trim(),
          phoneNumber: _normalizePhoneNumber(phone),
          lastOrderDate: DateTime.now(),
        );

        newCustomer.addOrUpdateAddress(address, postcode);
        if (orderAmount > 0) {
          newCustomer.updateOrderStats(orderAmount);
        }

        await _customersBox!.put(newCustomer.id, newCustomer);
        print('Created new customer: ${newCustomer.displayName}');
        return newCustomer;
      }
    } catch (e) {
      print('Error adding/updating customer: $e');
      rethrow;
    }
  }

  // Save customer from completed order
  static Future<void> saveCustomerFromOrder(Order order) async {
    if (order.orderType != 'takeaway' || 
        !order.customerInfo.isDelivery ||
        order.customerInfo.name?.trim().isEmpty == true ||
        order.customerInfo.phoneNumber?.trim().isEmpty == true ||
        order.customerInfo.address?.trim().isEmpty == true) {
      return; // Only save delivery customers with complete info
    }

    try {
      await addOrUpdateCustomer(
        name: order.customerInfo.name!,
        phone: order.customerInfo.phoneNumber!,
        address: order.customerInfo.address!,
        postcode: order.customerInfo.postcode ?? '',
        orderAmount: order.total,
      );
    } catch (e) {
      print('Error saving customer from order: $e');
      // Don't rethrow - this shouldn't break order completion
    }
  }

  // Get all customers (for admin/management)
  static List<Customer> getAllCustomers() {
    if (!_isInitialized || _customersBox == null) {
      return [];
    }

    try {
      return _customersBox!.values.toList()
        ..sort((a, b) => b.lastOrderDate.compareTo(a.lastOrderDate));
    } catch (e) {
      print('Error getting all customers: $e');
      return [];
    }
  }

  // Get recent customers (last 10)
  static List<Customer> getRecentCustomers({int limit = 10}) {
    final allCustomers = getAllCustomers();
    return allCustomers.take(limit).toList();
  }

  // Delete a customer
  static Future<void> deleteCustomer(String customerId) async {
    if (!_isInitialized || _customersBox == null) {
      throw Exception('CustomerService not initialized');
    }

    try {
      await _customersBox!.delete(customerId);
      print('Deleted customer: $customerId');
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }

  // Get customer statistics
  static Map<String, dynamic> getCustomerStats() {
    if (!_isInitialized || _customersBox == null) {
      return {
        'totalCustomers': 0,
        'totalSpent': 0.0,
        'averageOrderValue': 0.0,
        'totalOrders': 0,
      };
    }

    try {
      final customers = _customersBox!.values.toList();
      final totalCustomers = customers.length;
      final totalSpent = customers.fold<double>(0.0, (sum, customer) => sum + customer.totalSpent);
      final totalOrders = customers.fold<int>(0, (sum, customer) => sum + customer.totalOrders);
      final averageOrderValue = totalOrders > 0 ? totalSpent / totalOrders : 0.0;

      return {
        'totalCustomers': totalCustomers,
        'totalSpent': totalSpent,
        'averageOrderValue': averageOrderValue,
        'totalOrders': totalOrders,
      };
    } catch (e) {
      print('Error getting customer stats: $e');
      return {
        'totalCustomers': 0,
        'totalSpent': 0.0,
        'averageOrderValue': 0.0,
        'totalOrders': 0,
      };
    }
  }

  // Clear all customer data (for testing/reset)
  static Future<void> clearAllCustomers() async {
    if (!_isInitialized || _customersBox == null) {
      throw Exception('CustomerService not initialized');
    }

    try {
      await _customersBox!.clear();
      print('All customer data cleared');
    } catch (e) {
      print('Error clearing customer data: $e');
      rethrow;
    }
  }

  // Close the database
  static Future<void> close() async {
    try {
      if (_customersBox != null && _customersBox!.isOpen) {
        await _customersBox!.close();
        print('Customers box closed successfully');
      }
      _isInitialized = false;
    } catch (e) {
      print('Error closing customers box: $e');
    }
  }
}

// Extension to add firstWhereOrNull functionality
extension FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}