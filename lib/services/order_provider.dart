import 'package:flutter/material.dart';
import '../model/order_model.dart';
import '../services/customer_service.dart'; // NEW: Import customer service

class OrderProvider extends ChangeNotifier {
  // State for the order being currently built
  List<OrderItem> _orderItems = [];
  CustomerInfo _customerInfo = CustomerInfo();
  String _orderType = 'takeaway';
  String _paymentMethod = 'none'; // Default to 'none'
  String? _tableNumber;
  double _deliveryCharge = 0.0;

  // NEW: State for managing live, active orders
  List<Order> _liveOrders = [];

  // Getters for the current order
  List<OrderItem> get orderItems => _orderItems;
  CustomerInfo get customerInfo => _customerInfo;
  String get orderType => _orderType;
  String get paymentMethod => _paymentMethod;
  String? get tableNumber => _tableNumber;
  double get deliveryCharge => _deliveryCharge;

  // NEW: Getter for live orders
  List<Order> get liveOrders => _liveOrders;

  double get subtotal =>
      _orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get total => subtotal + _deliveryCharge;
  int get totalItems => _orderItems.fold(0, (sum, item) => sum + item.quantity);

  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setTableNumber(String? table) {
    _tableNumber = table;
    notifyListeners();
  }

  void setDeliveryCharge(double charge) {
    _deliveryCharge = charge;
    notifyListeners();
  }

  void updateCustomerInfo({
    String? name,
    String? address,
    String? postcode,
    String? phoneNumber,
    bool? isDelivery,
  }) {
    if (name != null) _customerInfo.name = name;
    if (address != null) _customerInfo.address = address;
    if (postcode != null) _customerInfo.postcode = postcode;
    if (phoneNumber != null) _customerInfo.phoneNumber = phoneNumber;
    if (isDelivery != null) _customerInfo.isDelivery = isDelivery;
    notifyListeners();
  }

  // NEW: Update customer info from customer lookup
  void updateCustomerInfoFromLookup({
    required String name,
    required String phoneNumber,
    String? address,
    String? postcode,
    bool isDelivery = false,
  }) {
    _customerInfo.name = name;
    _customerInfo.phoneNumber = phoneNumber;
    _customerInfo.address = address;
    _customerInfo.postcode = postcode;
    _customerInfo.isDelivery = isDelivery;
    notifyListeners();
  }

  void addItem(MenuItem menuItem, {String? specialInstructions}) {
    int existingIndex = _orderItems.indexWhere(
      (item) =>
          item.menuItem.name == menuItem.name &&
          item.specialInstructions == specialInstructions,
    );
    if (existingIndex != -1) {
      _orderItems[existingIndex].quantity++;
    } else {
      _orderItems.add(OrderItem(
        menuItem: menuItem,
        specialInstructions: specialInstructions,
      ));
    }
    notifyListeners();
  }

  void addCompleteOrderItem(OrderItem newItem) {
    int existingIndex = _orderItems.indexWhere(
      (item) =>
          item.menuItem.name == newItem.menuItem.name &&
          item.specialInstructions == newItem.specialInstructions,
    );
    if (existingIndex != -1) {
      _orderItems[existingIndex].quantity += newItem.quantity;
    } else {
      _orderItems.add(newItem);
    }
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _orderItems.length) {
      _orderItems.removeAt(index);
      notifyListeners();
    }
  }

  void updateItemQuantity(int index, int quantity) {
    if (index >= 0 && index < _orderItems.length) {
      if (quantity <= 0) {
        _orderItems.removeAt(index);
      } else {
        _orderItems[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void updateItemInstructions(int index, String instructions) {
    if (index >= 0 && index < _orderItems.length) {
      _orderItems[index].specialInstructions = instructions;
      notifyListeners();
    }
  }

  // UPDATED: Renamed from createOrder to buildCurrentOrder
  Order buildCurrentOrder() {
    return Order(
      // Temporarily use timestamp for ID, will be replaced when placed
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: List.from(_orderItems),
      customerInfo: CustomerInfo(
        name: _customerInfo.name,
        address: _customerInfo.address,
        postcode: _customerInfo.postcode,
        phoneNumber: _customerInfo.phoneNumber,
        isDelivery: _customerInfo.isDelivery,
      ),
      orderType: _orderType,
      paymentMethod: _paymentMethod,
      orderTime: DateTime.now(),
      tableNumber: _tableNumber,
      deliveryCharge: _deliveryCharge,
    );
  }

  // NEW: Method to place the current order into the live orders list
  void placeOrder() {
    if (_orderItems.isEmpty) return;

    final newOrder = buildCurrentOrder();
    _liveOrders.add(newOrder);
    clearOrder(); // Clears the order builder for the next order
    notifyListeners();
  }

  // NEW: Method to update payment for a live collection order
  void updateLiveOrderPayment(String orderId, String paymentMethod) {
    int orderIndex = _liveOrders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      _liveOrders[orderIndex].paymentMethod = paymentMethod;
      notifyListeners();
    }
  }

  // UPDATED: Method to remove an order from the live list once completed
  // Now also saves customer information for delivery orders
  Order? completeOrder(String orderId) {
    int orderIndex = _liveOrders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      final completedOrder = _liveOrders.removeAt(orderIndex);

      // NEW: Save customer information for future orders
      _saveCustomerFromOrder(completedOrder);

      notifyListeners();
      return completedOrder;
    }
    return null;
  }

  // NEW: Private method to save customer information
  Future<void> _saveCustomerFromOrder(Order order) async {
    try {
      if (CustomerService.isInitialized) {
        await CustomerService.saveCustomerFromOrder(order);
        print('Customer information saved for order ${order.id}');
      } else {
        print(
            'Warning: CustomerService not initialized, skipping customer save');
      }
    } catch (e) {
      print('Error saving customer from order: $e');
      // Don't rethrow - this shouldn't break order completion
    }
  }

  void clearOrder() {
    _orderItems.clear();
    _customerInfo = CustomerInfo();
    _orderType = 'takeaway';
    _paymentMethod = 'none'; // Reset to 'none'
    _tableNumber = null;
    _deliveryCharge = 0.0;
    // We don't notify listeners here because it's usually part of another action
  }
}
