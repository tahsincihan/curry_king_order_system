import 'package:flutter/material.dart';
import '../model/customer_model.dart';
import 'customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  List<Customer> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  Customer? _selectedCustomer;
  CustomerAddress? _selectedAddress;
  bool _isInitialized = false;
  String? _initializationError;

  // Getters
  List<Customer> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  Customer? get selectedCustomer => _selectedCustomer;
  CustomerAddress? get selectedAddress => _selectedAddress;
  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;

  // Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) {
      print('CustomerProvider already initialized');
      return;
    }

    try {
      print('Initializing CustomerProvider...');
      await CustomerService.initialize();
      _isInitialized = true;
      print('✓ CustomerProvider initialization complete');
      notifyListeners();
    } catch (e) {
      _initializationError = e.toString();
      print('❌ Error initializing CustomerProvider: $e');
      _isInitialized = false;
      notifyListeners();
    }
  }

  // Search customers by name or phone
  Future<void> searchCustomers(String query) async {
    if (!_isInitialized) {
      print('Warning: CustomerProvider not initialized');
      return;
    }

    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      _clearSearch();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Debounce

      List<Customer> results = [];

      // Check if query is numeric (for phone search)
      if (RegExp(r'^\d{4}$').hasMatch(_searchQuery)) {
        // Search by last 4 digits of phone
        results = CustomerService.searchByPhoneLastFour(_searchQuery);
      } else {
        // Search by name
        results = CustomerService.searchByName(_searchQuery);
      }

      _searchResults = results;
      print('Found ${results.length} customers for query: $_searchQuery');
    } catch (e) {
      print('Error searching customers: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Select a customer from search results
  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    _selectedAddress = customer.mostRecentAddress;
    _clearSearch();
    print('Selected customer: ${customer.displayName}');
    notifyListeners();
  }

  // Select a specific address for the customer
  void selectAddress(CustomerAddress address) {
    _selectedAddress = address;
    print('Selected address: ${address.displayAddress}');
    notifyListeners();
  }

  // Clear customer selection
  void clearSelection() {
    _selectedCustomer = null;
    _selectedAddress = null;
    _clearSearch();
    notifyListeners();
  }

  // Clear search results
  void _clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    _isSearching = false;
  }

  // Clear search without clearing selection
  void clearSearchOnly() {
    _clearSearch();
    notifyListeners();
  }

  // Get recent customers for quick access
  List<Customer> getRecentCustomers({int limit = 5}) {
    if (!_isInitialized) return [];

    try {
      return CustomerService.getRecentCustomers(limit: limit);
    } catch (e) {
      print('Error getting recent customers: $e');
      return [];
    }
  }

  // Add or update customer manually
  Future<Customer?> addOrUpdateCustomer({
    required String name,
    required String phone,
    required String address,
    required String postcode,
  }) async {
    if (!_isInitialized) {
      throw Exception('CustomerProvider not initialized');
    }

    try {
      final customer = await CustomerService.addOrUpdateCustomer(
        name: name,
        phone: phone,
        address: address,
        postcode: postcode,
      );

      // Auto-select the new/updated customer
      selectCustomer(customer);

      return customer;
    } catch (e) {
      print('Error adding/updating customer: $e');
      rethrow;
    }
  }

  // Get customer statistics
  Map<String, dynamic> getCustomerStats() {
    if (!_isInitialized) {
      return {
        'totalCustomers': 0,
        'totalSpent': 0.0,
        'averageOrderValue': 0.0,
        'totalOrders': 0,
      };
    }

    return CustomerService.getCustomerStats();
  }

  // Delete a customer
  Future<void> deleteCustomer(String customerId) async {
    if (!_isInitialized) {
      throw Exception('CustomerProvider not initialized');
    }

    try {
      await CustomerService.deleteCustomer(customerId);

      // Clear selection if the deleted customer was selected
      if (_selectedCustomer?.id == customerId) {
        clearSelection();
      }

      // Refresh search if needed
      if (_searchQuery.isNotEmpty) {
        await searchCustomers(_searchQuery);
      }

      notifyListeners();
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }

  // Get all customers (for admin interface)
  List<Customer> getAllCustomers() {
    if (!_isInitialized) return [];
    return CustomerService.getAllCustomers();
  }

  // Check if a customer has multiple addresses
  bool customerHasMultipleAddresses(Customer customer) {
    return customer.addresses.length > 1;
  }

  // Get formatted display text for customer in search results
  String getCustomerDisplayText(Customer customer) {
    final mostRecent = customer.mostRecentAddress;
    if (mostRecent != null) {
      return '${customer.displayName}\n${mostRecent.displayAddress}';
    }
    return customer.displayName;
  }

  // Validate if customer data is complete for ordering
  bool isCustomerDataComplete() {
    return _selectedCustomer != null &&
        _selectedAddress != null &&
        _selectedCustomer!.name.isNotEmpty &&
        _selectedCustomer!.phoneNumber.isNotEmpty &&
        _selectedAddress!.address.isNotEmpty;
  }

  // Get customer info for order
  Map<String, String?> getCustomerInfoForOrder() {
    if (!isCustomerDataComplete()) {
      return {
        'name': null,
        'phone': null,
        'address': null,
        'postcode': null,
      };
    }

    return {
      'name': _selectedCustomer!.name,
      'phone': _selectedCustomer!.phoneNumber,
      'address': _selectedAddress!.address,
      'postcode': _selectedAddress!.postcode,
    };
  }

  // Force re-initialization (for error recovery)
  Future<void> reinitialize() async {
    _isInitialized = false;
    _initializationError = null;
    await initialize();
  }
}
