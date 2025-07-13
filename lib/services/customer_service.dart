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
      
      // Register adapter if not already registered
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CustomerAdapter());
        print('✓ CustomerAdapter registered');
      }

      // Open the customers box
      _customersBox = await Hive.openBox<Customer>(_customersBoxName);
      print('✓ Customers box opened successfully');

      _isInitialized = true;
      print('✓ CustomerService initialization completed');
      
    } catch (e, stackTrace) {
      print('❌ Error initializing CustomerService: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  // Check if service is initialized
  static bool get isInitialized => _isInitialized;

  // Save customer from order
  static Future<Customer> saveCustomerFromOrder(Order order) async {
    if (!_isInitialized || _customersBox == null) {
      throw Exception('CustomerService not initialized');
    }

    if (order.customerInfo.name?.isEmpty != false || 
        order.customerInfo.phoneNumber?.isEmpty != false) {
      throw Exception('Customer name and phone number are required');
    }

    try {
      // Create customer ID from name and phone
      final customerId = _generateCustomerId(
        order.customerInfo.name!,
        order.customerInfo.phoneNumber!,
      );

      // Check if customer already exists
      Customer? existingCustomer = _customersBox!.get(customerId);

      if (existingCustomer != null) {
        // Update existing customer
        existingCustomer.lastUsed = DateTime.now();
        existingCustomer.orderCount++;
        
        // Add new address if different
        if (order.customerInfo.address?.isNotEmpty == true) {
          existingCustomer.addAddress(order.customerInfo.address!);
        }
        
        // Update postcode if provided
        if (order.customerInfo.postcode?.isNotEmpty == true) {
          existingCustomer.postcode = order.customerInfo.postcode;
        }

        await existingCustomer.save();
        print('Updated existing customer: ${existingCustomer.name}');
        return existingCustomer;
      } else {
        // Create new customer
        final newCustomer = Customer.fromCustomerInfo(order.customerInfo);
        await _customersBox!.put(customerId, newCustomer);
        print('Created new customer: ${newCustomer.name}');
        return newCustomer;
      }
    } catch (e) {
      print('Error saving customer: $e');
      rethrow;
    }
  }

  // Search customers by name or phone number
  static List<Customer> searchCustomers(String query) {
    if (!_isInitialized || _customersBox == null) {
      return [];
    }

    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final customers = _customersBox!.values.where((customer) {
        return customer.matchesSearch(query);
      }).toList();

      // Sort by last used (most recent first), then by order count
      customers.sort((a, b) {
        final lastUsedCompare = b.lastUsed.compareTo(a.lastUsed);
        if (lastUsedCompare != 0) return lastUsedCompare;
        return b.orderCount.compareTo(a.orderCount);
      });

      return customers;
    } catch (e) {
      print('Error searching customers: $e');
      return [];
    }
  }

  // Get recent customers (last 10)
  static List<Customer> getRecentCustomers({int limit = 10}) {
    if (!_isInitialized || _customersBox == null) {
      return [];
    }

    try {
      final customers = _customersBox!.values.toList();
      customers.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return customers.take(limit).toList();
    } catch (e) {
      print('Error getting recent customers: $e');
      return [];
    }
  }

  // Get frequent customers (by order count)
  static List<Customer> getFrequentCustomers({int limit = 10}) {
    if (!_isInitialized || _customersBox == null) {
      return [];
    }

    try {
      final customers = _customersBox!.values.where((c) => c.orderCount > 1).toList();
      customers.sort((a, b) => b.orderCount.compareTo(a.orderCount));
      return customers.take(limit).toList();
    } catch (e) {
      print('Error getting frequent customers: $e');
      return [];
    }
  }

  // Get customer by exact name and phone
  static Customer? getCustomer(String name, String phoneNumber) {
    if (!_isInitialized || _customersBox == null) {
      return null;
    }

    try {
      final customerId = _generateCustomerId(name, phoneNumber);
      return _customersBox!.get(customerId);
    } catch (e) {
      print('Error getting customer: $e');
      return null;
    }
  }

  // Update customer details
  static Future<void> updateCustomer(Customer customer) async {
    if (!_isInitialized || _customersBox == null) {
      throw Exception('CustomerService not initialized');
    }

    try {
      await customer.save();
      print('Customer updated: ${customer.name}');
    } catch (e) {
      print('Error updating customer: $e');
      rethrow;
    }
  }

  // Delete customer
  static Future<void> deleteCustomer(String customerId) async {
    if (!_isInitialized || _customersBox == null) {
      throw Exception('CustomerService not initialized');
    }

    try {
      await _customersBox!.delete(customerId);
      print('Customer deleted: $customerId');
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }

  // Get all customers
  static List<Customer> getAllCustomers() {
    if (!_isInitialized || _customersBox == null) {
      return [];
    }

    try {
      return _customersBox!.values.toList();
    } catch (e) {
      print('Error getting all customers: $e');
      return [];
    }
  }

  // Get customer statistics
  static Map<String, dynamic> getCustomerStats() {
    if (!_isInitialized || _customersBox == null) {
      return {};
    }

    try {
      final customers = _customersBox!.values.toList();
      
      if (customers.isEmpty) {
        return {
          'totalCustomers': 0,
          'repeatCustomers': 0,
          'totalOrders': 0,
          'averageOrdersPerCustomer': 0.0,
        };
      }

      final totalCustomers = customers.length;
      final repeatCustomers = customers.where((c) => c.orderCount > 1).length;
      final totalOrders = customers.fold<int>(0, (sum, c) => sum + c.orderCount);
      final averageOrdersPerCustomer = totalOrders / totalCustomers;

      return {
        'totalCustomers': totalCustomers,
        'repeatCustomers': repeatCustomers,
        'totalOrders': totalOrders,
        'averageOrdersPerCustomer': averageOrdersPerCustomer,
        'repeatCustomerRate': (repeatCustomers / totalCustomers) * 100,
      };
    } catch (e) {
      print('Error getting customer stats: $e');
      return {};
    }
  }

  // Clean up old customers (optional - keep customers who haven't ordered in 6+ months)
  static Future<void> cleanupOldCustomers() async {
    if (!_isInitialized || _customersBox == null) {
      return;
    }

    try {
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final customersToDelete = <String>[];

      for (final customer in _customersBox!.values) {
        if (customer.lastUsed.isBefore(sixMonthsAgo) && customer.orderCount == 1) {
          customersToDelete.add(customer.id);
        }
      }

      for (final customerId in customersToDelete) {
        await _customersBox!.delete(customerId);
      }

      print('Cleaned up ${customersToDelete.length} old customers');
    } catch (e) {
      print('Error cleaning up old customers: $e');
    }
  }

  // Clear all customer data (for testing)
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

  // Export customer data
  static Map<String, dynamic> exportCustomerData() {
    try {
      final customers = getAllCustomers();
      return {
        'exportDate': DateTime.now().toIso8601String(),
        'totalCustomers': customers.length,
        'customers': customers.map((customer) => {
          'id': customer.id,
          'name': customer.name,
          'phoneNumber': customer.phoneNumber,
          'addresses': customer.addresses,
          'postcode': customer.postcode,
          'createdAt': customer.createdAt.toIso8601String(),
          'lastUsed': customer.lastUsed.toIso8601String(),
          'orderCount': customer.orderCount,
        }).toList(),
      };
    } catch (e) {
      print('Error exporting customer data: $e');
      return {
        'error': e.toString(),
        'exportDate': DateTime.now().toIso8601String(),
        'customers': [],
      };
    }
  }

  // Generate consistent customer ID
  static String _generateCustomerId(String name, String phoneNumber) {
    return '${name.replaceAll(' ', '_').toLowerCase()}_${phoneNumber.replaceAll(' ', '')}';
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