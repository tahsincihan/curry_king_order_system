class MenuItem {
  final String name;
  final double price; // This is now the dine-in price
  final String category;
  final String? description;
  final double? takeawayPrice; // New field for takeaway pricing

  MenuItem({
    required this.name,
    required this.price, // dine-in price
    required this.category,
    this.description,
    this.takeawayPrice,
  });

  // Method to get the appropriate price based on order type
  double getTakeawayPrice() {
    return takeawayPrice ?? price; // Use takeaway price if available, otherwise use dine-in price
  }
  
  // Method to get dine-in price (just returns the main price)
  double getDineInPrice() {
    return price;
  }
}

class OrderItem {
  final MenuItem menuItem;
  int quantity;
  String? specialInstructions;

  OrderItem({
    required this.menuItem,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get totalPrice => menuItem.price * quantity;
}

class CustomerInfo {
  String? name;
  String? address;
  String? postcode;
  String? phoneNumber;
  bool isDelivery;

  CustomerInfo({
    this.name,
    this.address,
    this.postcode,
    this.phoneNumber,
    this.isDelivery = false,
  });
}

class Order {
  List<OrderItem> items;
  CustomerInfo customerInfo;
  String orderType; // 'takeaway' or 'dine-in'
  String paymentMethod; // 'cash' or 'card'
  DateTime orderTime;
  String? tableNumber; // for dine-in orders
  double deliveryCharge;
  double orderDiscount; // Order-level discount (percentage if ≤100, fixed amount if >100)
  String discountReason; // Reason for discount

  Order({
    required this.items,
    required this.customerInfo,
    required this.orderType,
    required this.paymentMethod,
    required this.orderTime,
    this.tableNumber,
    this.deliveryCharge = 0.0,
    this.orderDiscount = 0.0,
    this.discountReason = '',
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get discountAmount {
    if (orderDiscount <= 0) return 0.0;
    
    if (orderDiscount <= 100) {
      // Percentage discount (e.g., 10 = 10%)
      return subtotal * (orderDiscount / 100);
    } else {
      // Fixed amount discount (e.g., 105 = £105 off)
      return orderDiscount > subtotal ? subtotal : orderDiscount;
    }
  }

  double get subtotalAfterDiscount {
    return subtotal - discountAmount;
  }

  double get total {
    return subtotalAfterDiscount + deliveryCharge;
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Helper method to check if order has discount
  bool get hasDiscount {
    return orderDiscount > 0;
  }

  // Helper method to get discount type description
  String get discountTypeDescription {
    if (orderDiscount <= 0) return '';
    
    if (orderDiscount <= 100) {
      return '${orderDiscount.toStringAsFixed(0)}%';
    } else {
      return '£${orderDiscount.toStringAsFixed(2)}';
    }
  }
}