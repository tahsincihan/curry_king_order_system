import 'package:flutter/material.dart';
import '../model/order_model.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderItem> _orderItems = [];
  CustomerInfo _customerInfo = CustomerInfo();
  String _orderType = 'takeaway';
  String _paymentMethod = 'cash';
  String? _tableNumber;
  double _deliveryCharge = 0.0;

  List<OrderItem> get orderItems => _orderItems;
  CustomerInfo get customerInfo => _customerInfo;
  String get orderType => _orderType;
  String get paymentMethod => _paymentMethod;
  String? get tableNumber => _tableNumber;
  double get deliveryCharge => _deliveryCharge;

  double get subtotal {
    return _orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get total {
    return subtotal + _deliveryCharge;
  }

  int get totalItems {
    return _orderItems.fold(0, (sum, item) => sum + item.quantity);
  }

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

  void addItem(MenuItem menuItem, {String? specialInstructions}) {
    // Check if item already exists
    int existingIndex = _orderItems.indexWhere(
      (item) => item.menuItem.name == menuItem.name && 
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

  void addCompleteOrderItem(OrderItem newItem) {
    // Check if a similar item already exists
    int existingIndex = _orderItems.indexWhere(
      (item) => item.menuItem.name == newItem.menuItem.name && 
                item.specialInstructions == newItem.specialInstructions,
    );

    if (existingIndex != -1) {
      // If exists, update quantity
      _orderItems[existingIndex].quantity += newItem.quantity;
    } else {
      // Otherwise add new item
      _orderItems.add(newItem);
    }
    notifyListeners();
  }

  Order createOrder() {
    return Order(
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

  void clearOrder() {
    _orderItems.clear();
    _customerInfo = CustomerInfo();
    _orderType = 'takeaway';
    _paymentMethod = 'cash';
    _tableNumber = null;
    _deliveryCharge = 0.0;
    notifyListeners();
  }
}