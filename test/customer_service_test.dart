import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:curry_king_pos/services/customer_service.dart';
import 'package:curry_king_pos/model/customer_model.dart';

void main() {
  group('CustomerService Tests', () {
    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('test');
      await CustomerService.initialize();
    });

    tearDown(() async {
      await CustomerService.clearAllCustomers();
    });

    test('Add a new customer and verify address', () async {
      final customer = await CustomerService.addOrUpdateCustomer(
        name: 'John Doe',
        phone: '1234567890',
        address: '123 Test St',
        postcode: 'TS1 1ST',
        orderAmount: 50.0,
      );

      expect(customer.name, 'John Doe');
      expect(customer.addresses.length, 1);
      expect(customer.addresses.first.address, '123 Test St');
    });

    test('Update an existing customer with a new address', () async {
      // Add initial customer
      await CustomerService.addOrUpdateCustomer(
        name: 'Jane Doe',
        phone: '0987654321',
        address: '456 Main St',
        postcode: 'MN1 1NM',
        orderAmount: 30.0,
      );

      // Update with a new order and address
      final updatedCustomer = await CustomerService.addOrUpdateCustomer(
        name: 'Jane Doe',
        phone: '0987654321',
        address: '789 New Ave',
        postcode: 'NA1 1AN',
        orderAmount: 45.0,
      );

      expect(updatedCustomer.addresses.length, 2);
      expect(updatedCustomer.totalOrders, 2);
      expect(updatedCustomer.totalSpent, 75.0);
    });

    test('Look up a customer address', () async {
      // Add a customer with a specific address
      await CustomerService.addOrUpdateCustomer(
        name: 'Customer Lookup',
        phone: '1234567890',
        address: '123 Lookup Lane',
        postcode: 'LK1 1UP',
        orderAmount: 25.0,
      );

      // Search for the customer
      final results = CustomerService.searchByName('Lookup');
      final customer = results.first;

      // Verify the address details
      expect(results.isNotEmpty, isTrue);
      expect(customer.addresses.first.address, '123 Lookup Lane');
      expect(customer.addresses.first.postcode, 'LK1 1UP');
    });

    test('Search for a customer by name', () async {
      await CustomerService.addOrUpdateCustomer(
          name: 'Alice', phone: '111', address: 'Addr 1', postcode: 'PC1');
      await CustomerService.addOrUpdateCustomer(
          name: 'Alicia', phone: '222', address: 'Addr 2', postcode: 'PC2');

      final results = CustomerService.searchByName('Alice');
      expect(results.length, 2);
    });

    test('Search for a customer by last four digits of phone', () async {
      await CustomerService.addOrUpdateCustomer(
          name: 'Bob', phone: '1234567890', address: 'Addr 3', postcode: 'PC3');

      final results = CustomerService.searchByPhoneLastFour('7890');
      expect(results.length, 1);
      expect(results.first.name, 'Bob');
    });
  });
}
